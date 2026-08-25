local assets =
{
	Asset("ANIM", "anim/mountain_snowpile.zip"),
}

local prefabs =
{
	"mountain_snowball",
	"rocks",
	"ice",
	"boneshard",
	"mountain_kiki",
	"bluegem",
	"mountain_frozen_meatballs",
}

------------------------------------------------------------------------------------------------------------------------

SetSharedLootTable("mountain_snowpile",
{
	{ "mountain_snowball", 1.00 },
	{ "rocks", 1.00 },
	{ "ice", 0.50 },
	{ "boneshard", 0.05 },
	{ "mountain_frozen_meatballs", 0.01 },
	{ "mountain_kiki", 0.001 },
	{ "bluegem", 0.001 },
})

------------------------------------------------------------------------------------------------------------------------

local STAGE =
{
	full =
	{
		idle = "idle_full",
		dig = "dig_full",
		next = "med",
		radius = 1.5,
	},
	med =
	{
		idle = "idle_med",
		dig = "dig_med",
		next = "low",
		radius = 0.75,
	},
	low =
	{
		idle = "idle_low",
		dig = "dig_low",
		next = nil,
		radius = 0.5,
	},
}

local FALL_DAMAGE_RADIUS = 1.5
local FALL_DAMAGE_TAGS = { "player" }
local FALL_DAMAGE_CANT_TAGS = { "INLIMBO", "playerghost", "FX" }

------------------------------------------------------------------------------------------------------------------------

local OnDigAnimOver
local EnableDig
local ApplyStage

local function GetStageConfig(inst)
	return STAGE[inst.pile_stage]
end

local function DropDigLoot(inst)
	local pt = inst:GetPosition()
	inst.components.lootdropper:DropLoot(pt)
end

local function DoFallDamage(inst)
	if inst._fall_damaged then
		return
	end
	inst._fall_damaged = true

	local damage = TUNING.MOUNTAIN_SNOWPILE.FALL_DAMAGE
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, FALL_DAMAGE_RADIUS, FALL_DAMAGE_TAGS, FALL_DAMAGE_CANT_TAGS)
	for _, v in ipairs(ents) do
		if v:IsValid()
			and v.components.combat ~= nil
			and v.components.health ~= nil
			and not v.components.health:IsDead() then
			v.components.combat:GetAttacked(inst, damage)
		end
	end
end

local function FinishFall(inst)
	inst:RemoveEventCallback("animover", FinishFall)
	inst._falling = false

	-- 若动画提前被打断，仍保证造成一次坠落伤害
	DoFallDamage(inst)

	inst.pile_stage = "full"
	ApplyStage(inst, true)
	EnableDig(inst)

	if inst.components.inspectable == nil then
		inst:AddComponent("inspectable")
	end
end

local function BeginFall(inst)
	if inst._falling then
		return
	end
	inst._falling = true
	inst._fall_damaged = false

	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkable(false)
	end

	inst:AddTag("NOCLICK")
	inst.AnimState:PlayAnimation("fall")
	inst:ListenForEvent("animover", FinishFall)

	-- 与落地震屏同步造成伤害（原先等 animover 偏晚）
	local land_time = TUNING.MOUNTAIN_SNOWPILE.FALL_LAND_TIME or (12 / 30)
	inst:DoTaskInTime(land_time, function()
		if inst:IsValid() and inst._falling then
			DoFallDamage(inst)
			ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.3, 0.02, 0.5, inst, 20)
		end
	end)
end

OnDigAnimOver = function(inst)
	inst:RemoveEventCallback("animover", OnDigAnimOver)

	if inst._removing then
		inst:Remove()
		return
	end

	local cfg = GetStageConfig(inst)
	if cfg == nil then
		inst:Remove()
		return
	end

	ApplyStage(inst, true)
	EnableDig(inst)
end

local function BeginDigTransition(inst)
	local cfg = GetStageConfig(inst)
	if cfg == nil or inst._digging then
		return
	end
	inst._digging = true

	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkable(false)
	end

	DropDigLoot(inst)

	inst:RemoveEventCallback("animover", OnDigAnimOver)
	inst:ListenForEvent("animover", OnDigAnimOver)

	inst.AnimState:PlayAnimation(cfg.dig)

	if cfg.next ~= nil then
		inst.pile_stage = cfg.next
	else
		inst._removing = true
		inst.persists = false
		inst:AddTag("NOCLICK")
	end
end

EnableDig = function(inst)
	inst._digging = false
	inst:RemoveTag("NOCLICK")

	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(1)
		inst.components.workable:SetWorkable(true)
	end
end

ApplyStage = function(inst, play_idle)
	local cfg = GetStageConfig(inst)
	if cfg == nil then
		return
	end

	if play_idle then
		inst.AnimState:PlayAnimation(cfg.idle, true)
	end
end

local function OnDig(inst, worker)
	if worker ~= nil and not worker:HasTag("playerghost") then
		inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
	end
end

local function OnDigFinish(inst)
	if inst._falling or inst._digging or inst._removing then
		return
	end
	BeginDigTransition(inst)
end

local function OnSave(inst, data)
	data.pile_stage = inst.pile_stage
end

local function OnLoad(inst, data)
	-- 读档时不再播放坠落
	inst._skip_fall = true
	if data ~= nil and data.pile_stage ~= nil and STAGE[data.pile_stage] ~= nil then
		inst.pile_stage = data.pile_stage
	end
end

local function OnLoadPostPass(inst)
	inst._falling = false
	ApplyStage(inst, true)
	EnableDig(inst)
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	MakeObstaclePhysics(inst, STAGE.full.radius)

	inst.AnimState:SetBank("mountain_snowpile")
	inst.AnimState:SetBuild("mountain_snowpile")
	-- inst.AnimState:PlayAnimation("idle_full")
	
	inst.MiniMapEntity:SetIcon("mountain_snowpile.tex")

	inst:AddTag("snowpile")
	inst:AddTag("structure")

	inst.scrapbook_anim = "idle_full"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.pile_stage = "full"
	inst._falling = false
	inst._digging = false
	inst._removing = false
	inst._fall_damaged = false
	inst._skip_fall = false

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_snowpile")

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnWorkCallback(OnDig)
	inst.components.workable:SetOnFinishCallback(OnDigFinish)
	inst.components.workable:SetWorkable(false)

	MakeHauntableWork(inst)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnLoadPostPass = OnLoadPostPass

	inst:DoTaskInTime(0, function()
		if not inst._skip_fall then
			BeginFall(inst)
		end
	end)

	return inst
end

return Prefab("mountain_snowpile", fn, assets, prefabs)
