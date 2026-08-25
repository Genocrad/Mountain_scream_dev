local assets =
{
	Asset("ANIM", "anim/mountain_gravel_pile.zip"),
}

local prefabs =
{
	"rocks",
	"flint",
	"mountain_suspicious_ore",
}

------------------------------------------------------------------------------------------------------------------------
-- 每次挖掘：50% rocks / 40% flint / 10% mountain_suspicious_ore（互斥，合计 100%）

local function DropDigLoot(inst)
	local r = math.random()
	local loot
	if r < 0.50 then
		loot = "rocks"
	elseif r < 0.90 then
		loot = "flint"
	else
		loot = "mountain_suspicious_ore"
	end
	inst.components.lootdropper:SpawnLootPrefab(loot)
end

------------------------------------------------------------------------------------------------------------------------
-- 仅有 idle 动画，无 dig_*；挖掘后直接切下一阶段

local STAGE =
{
	full =
	{
		idle = "idle_full",
		next = "med",
	},
	med =
	{
		idle = "idle_med",
		next = "short",
	},
	short =
	{
		idle = "idle_short",
		next = nil,
	},
}

------------------------------------------------------------------------------------------------------------------------

local EnableDig
local ApplyStage

local function GetStageConfig(inst)
	return STAGE[inst.pile_stage]
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
	if inst._digging or inst._removing then
		return
	end

	local cfg = GetStageConfig(inst)
	if cfg == nil then
		inst:Remove()
		return
	end

	inst._digging = true
	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkable(false)
	end

	DropDigLoot(inst)

	if cfg.next ~= nil then
		inst.pile_stage = cfg.next
		ApplyStage(inst, true)
		EnableDig(inst)
	else
		inst._removing = true
		inst.persists = false
		inst:AddTag("NOCLICK")
		inst:Remove()
	end
end

local function OnSave(inst, data)
	data.pile_stage = inst.pile_stage
end

local function OnLoad(inst, data)
	if data ~= nil and data.pile_stage ~= nil and STAGE[data.pile_stage] ~= nil then
		inst.pile_stage = data.pile_stage
	end
end

local function OnLoadPostPass(inst)
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

	MakeObstaclePhysics(inst, 1.5) -- Luigi: Made a bit bigger due to "barricades" being easier

	inst.AnimState:SetBank("mountain_gravel_pile")
	inst.AnimState:SetBuild("mountain_gravel_pile")
	inst.AnimState:PlayAnimation("idle_full", true)

	inst.MiniMapEntity:SetIcon("mountain_gravel_pile.tex")

	inst:AddTag("gravelpile")

	inst.scrapbook_anim = "idle_full"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.pile_stage = "full"
	inst._digging = false
	inst._removing = false

	inst:AddComponent("lootdropper")

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnWorkCallback(OnDig)
	inst.components.workable:SetOnFinishCallback(OnDigFinish)

	MakeHauntableWork(inst)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnLoadPostPass = OnLoadPostPass

	return inst
end

return Prefab("mountain_gravel_pile", fn, assets, prefabs)
