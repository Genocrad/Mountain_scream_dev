local assets =
{
	Asset("ANIM", "anim/mountain_sand_spike_stone.zip"),
	Asset("ANIM", "anim/mountain_sand_spike_bank.zip"),
	Asset("ANIM", "anim/ms_snow_splash_fx.zip"),
}

local charged_assets =
{
	Asset("ANIM", "anim/mountain_sand_spike_stone_charged.zip"),
	Asset("ANIM", "anim/mountain_sand_spike_bank.zip"),
	Asset("ANIM", "anim/ms_snow_splash_fx.zip"),
	Asset("ANIM", "anim/mushroombomb_base.zip"),
}

local RADIUS =
{
	short = .2,
	med = .4,
	tall = .6,
}

local SPIKE_CONFIG =
{
	tall =
	{
		animname = "tall",
		radius = RADIUS.tall,
		mine_work = TUNING.MOUNTAIN_GOLEM.SANDSPIKE_MINE_WORK.TALL,
		downgrade = "mountain_sandspike_med",
		emerges = true,
		deals_damage = true,
	},
	med =
	{
		animname = "med",
		radius = RADIUS.med,
		mine_work = TUNING.MOUNTAIN_GOLEM.SANDSPIKE_MINE_WORK.MED,
		downgrade = "mountain_sandspike_short",
		emerges = false,
		deals_damage = false,
	},
	short =
	{
		animname = "short",
		radius = RADIUS.short,
		mine_work = TUNING.MOUNTAIN_GOLEM.SANDSPIKE_MINE_WORK.SHORT,
		downgrade = nil,
		emerges = false,
		deals_damage = false,
	},
}

local CHARGED_DOWNGRADE =
{
	tall = "mountain_sandspike_charged_med",
	med = "mountain_sandspike_charged_short",
}

local CHARGED_SPIKE_CONFIG = {}
for name, cfg in pairs(SPIKE_CONFIG) do
	local explode_cfg = TUNING.MOUNTAIN_GOLEM.CHARGED_SANDSPIKE_EXPLODE[string.upper(name)]
	CHARGED_SPIKE_CONFIG[name] =
	{
		animname = cfg.animname,
		radius = cfg.radius,
		mine_work = cfg.mine_work,
		downgrade = CHARGED_DOWNGRADE[name],
		emerges = cfg.emerges,
		deals_damage = cfg.deals_damage,
		charged = true,
		explode_damage = explode_cfg.DAMAGE,
		explode_radius = explode_cfg.RADIUS,
	}
end

local DAMAGE_RADIUS_PADDING = .5

local EXPLODETARGET_MUST_TAGS = { "_health", "_combat" }
local EXPLODETARGET_CANT_TAGS = { "INLIMBO", "mountain_golem" }

local COLLAPSIBLE_WORK_ACTIONS =
{
	CHOP = true,
	DIG = true,
	HAMMER = true,
	MINE = true,
}

local COLLAPSIBLE_TAGS = { "_combat", "pickable", "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
	table.insert(COLLAPSIBLE_TAGS, k.."_workable")
end

local NON_COLLAPSIBLE_TAGS = { "antlion", "groundspike", "flying", "shadow", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO" }
local TOSSITEM_MUST_TAGS = { "_inventoryitem" }
local TOSSITEM_CANT_TAGS = { "locomotor", "INLIMBO" }

local CancelExplodeTimer
local StartExplodeTimer
local OnExplode

local function EnableWorkable(inst)
	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkable(true)
	end
end

local function SetObstaclePhysics(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	inst.Physics:Stop()
	inst.Physics:SetMass(0)
	inst.Physics:SetCollisionMask(
		COLLISION.ITEMS,
		COLLISION.CHARACTERS,
		COLLISION.GIANTS
	)
	inst.Physics:Teleport(x, 0, z)
end

local function CreateGroundFX(source)
	local inst = CreateEntity()

	inst:AddTag("FX")
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBank("mushroombomb_base")
	inst.AnimState:SetBuild("mushroombomb_base")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)
	inst.AnimState:SetFinalOffset(3)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst:ListenForEvent("animover", inst.Remove)

	inst.Transform:SetPosition(source.Transform:GetWorldPosition())
end

local function DoExplosionEffects(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/spore_explode")
	if inst._explode ~= nil then
		inst._explode:push()
	end
	if not TheNet:IsDedicated() then
		CreateGroundFX(inst)
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, inst.spikeconfig.explode_radius, EXPLODETARGET_MUST_TAGS, EXPLODETARGET_CANT_TAGS)
	for i, v in ipairs(ents) do
		if v:IsValid() and not v:IsInLimbo() and
			v.components.combat ~= nil and
			not (v.components.health ~= nil and v.components.health:IsDead())
		then
			v.components.combat:GetAttacked(inst, inst.spikeconfig.explode_damage, nil, nil, nil, inst)
		end
	end
end

local function SpikeLaunch(inst, launcher, basespeed, startheight, startradius)
	local x0, y0, z0 = launcher.Transform:GetWorldPosition()
	local x1, y1, z1 = inst.Transform:GetWorldPosition()
	local dx, dz = x1 - x0, z1 - z0
	local dsq = dx * dx + dz * dz
	local angle
	if dsq > 0 then
		local dist = math.sqrt(dsq)
		angle = math.atan2(dz / dist, dx / dist) + (math.random() * 20 - 10) * DEGREES
	else
		angle = TWOPI * math.random()
	end
	local sina, cosa = math.sin(angle), math.cos(angle)
	local speed = basespeed + math.random()
	TryTeleportToLaunchPos(inst, x0 + startradius * cosa, startheight, z0 + startradius * sina)
	inst.Physics:SetVel(cosa * speed, speed * 5 + math.random() * 2, sina * speed)
end

local function DoDamage(inst)
	if inst._damaged then
		return
	end
	inst._damaged = true

	inst.Physics:SetActive(true)
	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, inst.spikeradius + DAMAGE_RADIUS_PADDING, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
	for i, v in ipairs(ents) do
		if v:IsValid() then
			local isworkable = false
			if v.components.workable ~= nil then
				local work_action = v.components.workable:GetWorkAction()
				isworkable = (
					(work_action == nil and v:HasTag("NPC_workable")) or
					(v.components.workable:CanBeWorked() and work_action ~= nil and COLLAPSIBLE_WORK_ACTIONS[work_action.id])
				)
			end
			if isworkable then
				v.components.workable:Destroy(inst)
				if v:IsValid() and v:HasTag("stump") then
					v:Remove()
				end
			elseif v.components.pickable ~= nil
				and v.components.pickable:CanBePicked()
				and not v:HasTag("intense") then
				v.components.pickable:Pick(inst)
			elseif v.components.combat ~= nil
				and v.components.health ~= nil
				and not v.components.health:IsDead()
				and inst.components.combat:IsValidTarget(v) then
				if v.components.locomotor == nil then
					v.components.health:Kill()
				else
					inst.components.combat:DoAttack(v)
				end
			end
		end
	end

	local totoss = TheSim:FindEntities(x, 0, z, inst.spikeradius + DAMAGE_RADIUS_PADDING, TOSSITEM_MUST_TAGS, TOSSITEM_CANT_TAGS)
	for i, v in ipairs(totoss) do
		DeactivateInventoryItemBeforeLaunch(v)
		if not v.components.inventoryitem.nobounce and v.Physics ~= nil and v.Physics:IsActive() then
			SpikeLaunch(v, inst, .8 + inst.spikeradius, inst.spikeradius * .4, inst.spikeradius + v:GetPhysicsRadius(0))
		end
	end
end

local function SpawnDowngradeSpike(inst)
	if inst.spikeconfig.downgrade == nil then
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local spike = SpawnPrefab(inst.spikeconfig.downgrade)
	if spike ~= nil then
		spike.Transform:SetPosition(x, 0, z)
		if spike.Setup ~= nil then
			spike:Setup()
		end
	end
end

local function OnBreakAnimOver(inst)
	inst:RemoveEventCallback("animover", OnBreakAnimOver)
	SpawnDowngradeSpike(inst)
	inst:Remove()
end

local function BeginBreak(inst, is_explode)
	if inst._breaking then
		return
	end
	inst._breaking = true

	CancelExplodeTimer(inst)

	if inst.components.workable ~= nil then
		inst.components.workable:SetOnWorkCallback(nil)
		inst.components.workable:SetOnFinishCallback(nil)
		inst.components.workable:SetWorkable(false)
	end

	inst:AddTag("NOCLICK")
	inst.Physics:SetActive(false)
	inst:RemoveEventCallback("animover", OnBreakAnimOver)
	inst:ListenForEvent("animover", OnBreakAnimOver)
	inst.AnimState:PlayAnimation(inst.animname.."_break")

	if is_explode then
		DoExplosionEffects(inst)
	else
		inst.SoundEmitter:PlaySound(
			"dontstarve/creatures/together/antlion/sfx/break_spike",
			nil,
			(inst.animname == "short" and .6) or
			(inst.animname == "med" and .8) or
			nil
		)
	end

	inst.persists = false
end

CancelExplodeTimer = function(inst)
	if inst._explodetask ~= nil then
		inst._explodetask:Cancel()
		inst._explodetask = nil
	end
	inst._explode_time = nil
end

local function GetChargedExplodeDelay()
	local cfg = TUNING.MOUNTAIN_GOLEM.CHARGED_SANDSPIKE_EXPLODE_DELAY
	return GetRandomMinMax(cfg.MIN, cfg.MAX)
end

StartExplodeTimer = function(inst, delay)
	if not inst.spikeconfig.charged then
		return
	end
	CancelExplodeTimer(inst)
	delay = delay or GetChargedExplodeDelay()
	inst._explode_time = GetTime() + delay
	inst._explodetask = inst:DoTaskInTime(delay, OnExplode)
end

OnExplode = function(inst)
	if not inst.persists or inst._breaking then
		return
	end
	BeginBreak(inst, true)
end

local function FinishEmerge(inst)
	inst:RemoveEventCallback("animover", FinishEmerge)
	inst._emerged = true

	SetObstaclePhysics(inst)
	inst.AnimState:SetLayer(LAYER_WORLD)
	inst.AnimState:SetSortOrder(0)
	inst.AnimState:PlayAnimation(inst.animname.."_idle", true)

	inst:DoTaskInTime(0, function()
		EnableWorkable(inst)
		StartExplodeTimer(inst, inst._explode_remaining)
		inst._explode_remaining = nil
	end)
end

local function StartSpikeAnim(inst)
	inst:RemoveEventCallback("animover", StartSpikeAnim)
	inst:ListenForEvent("animover", FinishEmerge)
	inst.AnimState:SetLayer(LAYER_WORLD)
	inst.AnimState:SetSortOrder(0)
	inst.AnimState:PlayAnimation(inst.animname.."_pst")
	if inst.spikeconfig.deals_damage then
		inst:DoTaskInTime(2 * FRAMES, DoDamage)
	end
	inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/break")
end

local function BeginEmerge(inst)
	if inst._emerged then
		return
	end
	inst:RemoveEventCallback("animover", BeginEmerge)
	inst:ListenForEvent("animover", StartSpikeAnim)
	inst.AnimState:PlayAnimation(inst.animname.."_pre")
end

local function SetupIdle(inst)
	inst._emerged = true

	inst.Physics:SetActive(true)
	inst.AnimState:SetLayer(LAYER_WORLD)
	inst.AnimState:SetSortOrder(0)
	inst.AnimState:PlayAnimation(inst.animname.."_idle", true)

	SetObstaclePhysics(inst)

	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
	end
	EnableWorkable(inst)
	StartExplodeTimer(inst, inst._explode_remaining)
	inst._explode_remaining = nil
end

local function Setup(inst)
	if inst._setup then
		return
	end
	inst._setup = true

	if inst.spikeconfig.emerges and not inst._emerged then
		BeginEmerge(inst)
	else
		SetupIdle(inst)
	end
end

local function OnMine(inst, worker)
	if worker == nil or not worker:HasTag("playerghost") then
		inst.SoundEmitter:PlaySound("dontstarve/wilson/use_pickaxe")
	end
end

local function OnMineDown(inst)
	if not inst.persists or inst._breaking then
		return
	end

	inst:RemoveEventCallback("animover", StartSpikeAnim)
	inst:RemoveEventCallback("animover", FinishEmerge)
	BeginBreak(inst, false)
end

local function OnSave(inst, data)
	data.emerged = inst._emerged or false
	data.damaged = inst._damaged or false
	if inst._explode_time ~= nil then
		data.explode_remaining = math.max(0, inst._explode_time - GetTime())
	end
end

local function OnLoad(inst, data)
	if data ~= nil then
		inst._emerged = data.emerged or false
		inst._damaged = data.damaged or false
		inst._explode_remaining = data.explode_remaining
	end
end

local function OnLoadPostPass(inst)
	if inst._setup then
		return
	end
	inst._setup = true
	if inst._emerged then
		SetupIdle(inst)
	elseif inst.spikeconfig.emerges then
		BeginEmerge(inst)
	else
		SetupIdle(inst)
	end
end

local function MakeSpike(name, charged)
	local config = charged and CHARGED_SPIKE_CONFIG[name] or SPIKE_CONFIG[name]
	local prefab_assets = charged and charged_assets or assets
	local build = charged and "mountain_sand_spike_stone_charged" or "mountain_sand_spike_stone"
	local prefab_name = charged and ("mountain_sandspike_charged_"..name) or ("mountain_sandspike_"..name)
	local general_name = charged and "mountain_sandspike_charged_tall" or "mountain_sandspike_tall"

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddPhysics()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank("mountain_sand_spike_bank")
		inst.AnimState:SetBuild(build)
		inst.AnimState:OverrideSymbol("sand_splash", "ms_snow_splash_fx", "sand_splash")
		inst.AnimState:SetLayer(LAYER_BACKGROUND)
		inst.AnimState:SetSortOrder(3)

		inst.Physics:SetMass(999999)
		inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
		inst.Physics:SetCollisionMask(
			COLLISION.ITEMS,
			COLLISION.CHARACTERS,
			COLLISION.GIANTS,
			COLLISION.WORLD
		)
		inst.Physics:SetActive(false)
		inst.Physics:SetCapsule(config.radius, 2)

		inst:AddTag("notarget")
		inst:AddTag("groundspike")
		inst:AddTag("mountain_sandspike")
		inst:AddTag("object")
		inst:AddTag("stone")
		if charged then
			inst:AddTag("mountain_sandspike_charged")
			inst:AddTag("explosive")
		end

		inst:SetPrefabNameOverride(general_name)

		inst.spikeconfig = config
		inst.animname = config.animname
		inst.spikeradius = config.radius

		if charged then
			inst._explode = net_event(inst.GUID, "mountain_sandspike_charged._explode")
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			if charged then
				inst:ListenForEvent("mountain_sandspike_charged._explode", function()
					CreateGroundFX(inst)
				end)
			end
			return inst
		end

		if config.deals_damage then
			inst:AddComponent("combat")
			inst.components.combat:SetDefaultDamage(TUNING.SANDSPIKE.DAMAGE.TALL)
			inst.components.combat.playerdamagepercent = .5
			inst.components.combat:SetKeepTargetFunction(function() return false end)
		end

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.MINE)
		inst.components.workable:SetWorkLeft(config.mine_work)
		inst.components.workable:SetOnWorkCallback(OnMine)
		inst.components.workable:SetOnFinishCallback(OnMineDown)
		inst.components.workable:SetWorkable(false)

		inst.Setup = Setup
		inst.OnSave = OnSave
		inst.OnLoad = OnLoad
		inst.OnLoadPostPass = OnLoadPostPass

		inst.persists = true
		inst:DoTaskInTime(0, Setup)

		return inst
	end

	return Prefab(prefab_name, fn, prefab_assets)
end

return MakeSpike("tall"), MakeSpike("med"), MakeSpike("short"),
	MakeSpike("tall", true), MakeSpike("med", true), MakeSpike("short", true)
