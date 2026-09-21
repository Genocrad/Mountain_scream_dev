local assets =
{
	Asset("ANIM", "anim/mountain_sand_block.zip"),
	Asset("ANIM", "anim/mountain_sand_block_bank.zip"),
}

local charged_assets =
{
	Asset("ANIM", "anim/mountain_sand_block_charged.zip"),
	Asset("ANIM", "anim/mountain_sand_block_bank.zip"),
}

local BLOCK_STATES =
{
	tall =
	{
		idle = "idle_tall",
		break_anim = "tall_break",
		next = "med",
		mine_work = TUNING.MOUNTAIN_GOLEM.SANDBLOCK_MINE_WORK.TALL,
		radius = 1,
	},
	med =
	{
		idle = "idle_med",
		break_anim = "med_break",
		next = "short",
		mine_work = TUNING.MOUNTAIN_GOLEM.SANDBLOCK_MINE_WORK.MED,
		radius = 0.75,
	},
	short =
	{
		idle = "idle_short",
		break_anim = "short_break",
		next = nil,
		mine_work = TUNING.MOUNTAIN_GOLEM.SANDBLOCK_MINE_WORK.SHORT,
		radius = 0.5,
	},
}

local OnMine
local OnMineDown
local FinishEmerge
local StartBlockPst
local BeginEmerge

local function GetStateConfig(inst)
	return BLOCK_STATES[inst.blockstate]
end

local function UnlinkFromGolem(inst)
	if inst._link ~= nil then
		inst._link:PushEvent("unlinkmountaintower", inst)
		inst._link = nil
	end
end

local function OnGolemRemoved(inst)
	UnlinkFromGolem(inst)
end

local function DoLink(inst, golem)
	inst._link = golem
	inst:ListenForEvent("onremove", OnGolemRemoved, golem)
	inst:ListenForEvent("death", OnGolemRemoved, golem)
	golem:PushEvent("linkmountaintower", inst)
end

local function OnLinkMountainGolem(inst, golem)
	if inst._link == nil and golem ~= nil and golem:IsValid() then
		inst.components.entitytracker:TrackEntity("golem", golem)
		DoLink(inst, golem)
	end
end

local function SetObstaclePhysics(inst, radius)
	local x, y, z = inst.Transform:GetWorldPosition()
	inst.Physics:Stop()
	inst.Physics:SetMass(0)
	inst.Physics:SetCapsule(radius, 2)
	inst.Physics:SetCollisionMask(
		COLLISION.ITEMS,
		COLLISION.CHARACTERS,
		COLLISION.GIANTS
	)
	inst.Physics:Teleport(x, 0, z)
end

local function EnableWorkable(inst)
	if inst.components.workable ~= nil then
		inst.components.workable:SetOnWorkCallback(OnMine)
		inst.components.workable:SetOnFinishCallback(OnMineDown)
		inst.components.workable:SetWorkable(true)
	end
end

local function ApplyBlockState(inst, play_idle)
	local cfg = GetStateConfig(inst)
	if cfg == nil then
		return
	end

	inst.Physics:SetActive(true)
	SetObstaclePhysics(inst, cfg.radius)
	inst.AnimState:SetLayer(LAYER_WORLD)
	inst.AnimState:SetSortOrder(0)

	if play_idle then
		inst.AnimState:PlayAnimation(cfg.idle, true)
	end

	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(cfg.mine_work)
	end
end

local function PlayBreakSound(inst, cfg)
	local next_cfg = cfg.next ~= nil and BLOCK_STATES[cfg.next] or nil
	inst.SoundEmitter:PlaySound(
		"dontstarve/creatures/together/antlion/sfx/break_spike",
		nil,
		(next_cfg == nil and .6) or
		(cfg.next == "short" and .8) or
		nil
	)
end

local function DowngradeBlock(inst)
	local cfg = GetStateConfig(inst)
	if cfg == nil or cfg.next == nil then
		return false
	end

	local break_anim = cfg.break_anim
	local next_cfg = BLOCK_STATES[cfg.next]

	inst.blockstate = cfg.next
	ApplyBlockState(inst, false)
	EnableWorkable(inst)

	inst.AnimState:PlayAnimation(break_anim, false)
	inst.AnimState:PushAnimation(next_cfg.idle, true)
	PlayBreakSound(inst, cfg)
	return true
end

local function OnBreakAnimOver(inst)
	inst:RemoveEventCallback("animover", OnBreakAnimOver)
	UnlinkFromGolem(inst)
	inst:Remove()
end

local function BeginBreak(inst)
	if inst._breaking then
		return
	end
	inst._breaking = true

	if inst.components.timer ~= nil then
		inst.components.timer:StopTimer("lifetime")
	end

	if inst.components.workable ~= nil then
		inst.components.workable:SetOnWorkCallback(nil)
		inst.components.workable:SetOnFinishCallback(nil)
		inst.components.workable:SetWorkable(false)
	end

	inst:AddTag("NOCLICK")
	inst.Physics:SetActive(false)
	inst:RemoveEventCallback("animover", OnBreakAnimOver)
	inst:ListenForEvent("animover", OnBreakAnimOver)

	local cfg = GetStateConfig(inst)
	inst.AnimState:PlayAnimation(cfg.break_anim)
	PlayBreakSound(inst, cfg)

	if cfg.next == nil then
		inst.persists = false
	end
end

local function OnBlockRetractAnimOver(inst)
	local state = inst._retract_states ~= nil and table.remove(inst._retract_states, 1) or nil
	local cfg = state ~= nil and BLOCK_STATES[state] or nil
	if cfg == nil then
		inst:RemoveEventCallback("animover", OnBlockRetractAnimOver)
		inst:Remove()
		return
	end
	inst.AnimState:PlayAnimation(cfg.break_anim)
	PlayBreakSound(inst, cfg)
end

local function RetractBlock(inst)
	if inst._breaking or inst._retracting or inst:HasTag("mountain_sandblock_charged") then
		return
	end
	inst._retracting = true

	if inst.components.timer ~= nil then
		inst.components.timer:StopTimer("lifetime")
	end

	if inst.components.workable ~= nil then
		inst.components.workable:SetOnWorkCallback(nil)
		inst.components.workable:SetOnFinishCallback(nil)
		inst.components.workable:SetWorkable(false)
	end

	inst:AddTag("NOCLICK")
	inst.Physics:SetActive(false)
	inst.persists = false
	UnlinkFromGolem(inst)

	inst:RemoveEventCallback("animover", OnBreakAnimOver)
	inst:RemoveEventCallback("animover", StartBlockPst)
	inst:RemoveEventCallback("animover", FinishEmerge)
	inst:RemoveEventCallback("animover", BeginEmerge)

	local states = {}
	local state = BLOCK_STATES[inst.blockstate] ~= nil and inst.blockstate or "short"
	while state ~= nil do
		table.insert(states, state)
		state = BLOCK_STATES[state].next
	end

	local first = table.remove(states, 1)
	inst._retract_states = states
	local cfg = BLOCK_STATES[first]
	inst.AnimState:SetLayer(LAYER_WORLD)
	inst.AnimState:SetSortOrder(0)
	inst.AnimState:PlayAnimation(cfg.break_anim)
	PlayBreakSound(inst, cfg)
	inst:ListenForEvent("animover", OnBlockRetractAnimOver)
end

local function StartBlockLifetime(inst)
	if inst:HasTag("mountain_sandblock_charged") or inst._breaking or inst._retracting then
		return
	end
	if inst.components.timer ~= nil and inst.components.timer:TimerExists("lifetime") then
		return
	end

	local remaining = TUNING.MOUNTAIN_GOLEM.SANDBLOCK_LIFETIME
	if remaining == nil or remaining <= 0 then
		inst:DoTaskInTime(0, RetractBlock)
		return
	end
	inst.components.timer:StartTimer("lifetime", remaining)
end

local function OnBlockLifetime(inst, data)
	if data.name == "lifetime" then
		RetractBlock(inst)
	end
end

FinishEmerge = function(inst)
	inst:RemoveEventCallback("animover", FinishEmerge)
	inst._emerged = true

	ApplyBlockState(inst, true)
	EnableWorkable(inst)
end

StartBlockPst = function(inst)
	inst:RemoveEventCallback("animover", StartBlockPst)
	inst:ListenForEvent("animover", FinishEmerge)
	inst.AnimState:PlayAnimation("block_pst")
	inst.SoundEmitter:PlaySound("dontstarve/creatures/together/antlion/sfx/break")
end

BeginEmerge = function(inst)
	if inst._emerged then
		return
	end
	inst:RemoveEventCallback("animover", BeginEmerge)
	inst:ListenForEvent("animover", StartBlockPst)
	inst.AnimState:PlayAnimation("block_pre")
end

local function SetupIdle(inst)
	inst._emerged = true
	ApplyBlockState(inst, true)

	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
	end
	EnableWorkable(inst)
end

local function Setup(inst)
	if inst._setup then
		return
	end
	inst._setup = true
	StartBlockLifetime(inst)

	if inst.blockstate == "tall" and not inst._emerged then
		BeginEmerge(inst)
	else
		SetupIdle(inst)
	end
end

OnMine = function(inst, worker)
	if worker == nil or not worker:HasTag("playerghost") then
		inst.SoundEmitter:PlaySound("dontstarve/wilson/use_pickaxe")
	end
end

OnMineDown = function(inst)
	if not inst.persists or inst._breaking or inst._retracting then
		return
	end

	inst:RemoveEventCallback("animover", StartBlockPst)
	inst:RemoveEventCallback("animover", FinishEmerge)

	if not DowngradeBlock(inst) then
		BeginBreak(inst)
	end
end

local function OnSave(inst, data)
	data.blockstate = inst.blockstate
	data.emerged = inst._emerged or false
end

local function OnLoad(inst, data)
	if data ~= nil then
		if data.blockstate ~= nil and BLOCK_STATES[data.blockstate] ~= nil then
			inst.blockstate = data.blockstate
		end
		inst._emerged = data.emerged or false
	end
end

local function OnLoadPostPass(inst)
	if inst._link == nil and inst.components.entitytracker ~= nil then
		local golem = inst.components.entitytracker:GetEntity("golem")
		if golem ~= nil then
			DoLink(inst, golem)
		end
	end

	StartBlockLifetime(inst)

	if inst._setup then
		return
	end
	inst._setup = true

	if inst._emerged or inst.blockstate ~= "tall" then
		SetupIdle(inst)
	elseif inst.blockstate == "tall" then
		BeginEmerge(inst)
	end
end

local function MakeBlock(charged)
	local prefab_assets = charged and charged_assets or assets
	local build = charged and "mountain_sand_block_charged" or "mountain_sand_block"
	local prefab_name = charged and "mountain_sandblock_charged" or "mountain_sandblock"

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddPhysics()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank("mountain_sand_block_bank")
		inst.AnimState:SetBuild(build)
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

		inst:AddTag("mountain_sandblock")
		inst:AddTag("object")
		inst:AddTag("stone")
		if charged then
			inst:AddTag("mountain_sandblock_charged")
		end

		inst.blockstate = "tall"

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.MINE)
		inst.components.workable:SetWorkLeft(BLOCK_STATES.tall.mine_work)
		inst.components.workable:SetOnWorkCallback(OnMine)
		inst.components.workable:SetOnFinishCallback(OnMineDown)
		inst.components.workable:SetWorkable(false)

		if not charged then
			inst:AddComponent("timer")
			inst:ListenForEvent("timerdone", OnBlockLifetime)
		end

		if charged then
			inst:AddComponent("entitytracker")
			inst:ListenForEvent("linkmountaingolem", OnLinkMountainGolem)
		end

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

return MakeBlock(false), MakeBlock(true)
