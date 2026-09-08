local assets =
{
	Asset("ANIM", "anim/ms_broken_pillar.zip"),
}

local prefabs =
{
	"cutstone",
	"rock_break_fx",
}

local WORK_PER_STAGE = 2

------------------------------------------------------------------------------------------------------------------------

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

local EnableMine
local ApplyStage

local function GetStageConfig(inst)
	return STAGE[inst.pillar_stage]
end

EnableMine = function(inst)
	inst._mining = false
	inst:RemoveTag("NOCLICK")

	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(WORK_PER_STAGE)
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

local function OnMine(inst, worker, workleft)
	if worker ~= nil and not worker:HasTag("playerghost") then
		inst.SoundEmitter:PlaySound("dontstarve/wilson/use_pickaxe")
	end

	if workleft > 0 then
		local pt = inst:GetPosition()
		SpawnPrefab("rock_break_fx").Transform:SetPosition(pt:Get())
	end
end

local function OnMineFinish(inst)
	if inst._mining or inst._removing then
		return
	end

	local cfg = GetStageConfig(inst)
	if cfg == nil then
		inst:Remove()
		return
	end

	inst._mining = true
	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkable(false)
	end

	local pt = inst:GetPosition()
	SpawnPrefab("rock_break_fx").Transform:SetPosition(pt:Get())
	inst.components.lootdropper:SpawnLootPrefab("cutstone")

	if cfg.next ~= nil then
		inst.pillar_stage = cfg.next
		ApplyStage(inst, true)
		EnableMine(inst)
	else
		inst._removing = true
		inst.persists = false
		inst:AddTag("NOCLICK")
		inst:Remove()
	end
end

local function OnSave(inst, data)
	data.pillar_stage = inst.pillar_stage
end

local function OnLoad(inst, data)
	if data ~= nil and data.pillar_stage ~= nil and STAGE[data.pillar_stage] ~= nil then
		inst.pillar_stage = data.pillar_stage
	end
end

local function OnLoadPostPass(inst)
	ApplyStage(inst, true)
	EnableMine(inst)
end

local function SetStage(inst, stage)
	if STAGE[stage] == nil then
		return
	end
	inst.pillar_stage = stage
	ApplyStage(inst, true)
	EnableMine(inst)
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	MakeObstaclePhysics(inst, 1)

	inst.AnimState:SetBank("ms_broken_pillar")
	inst.AnimState:SetBuild("ms_broken_pillar")
	inst.AnimState:PlayAnimation("idle_full", true)

	inst.MiniMapEntity:SetIcon("ms_broken_pillar.tex")

	inst:AddTag("boulder")

	inst.scrapbook_anim = "idle_full"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.pillar_stage = "full"
	inst._mining = false
	inst._removing = false

	inst:AddComponent("lootdropper")

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(WORK_PER_STAGE)
	inst.components.workable:SetOnWorkCallback(OnMine)
	inst.components.workable:SetOnFinishCallback(OnMineFinish)

	MakeHauntableWork(inst)

	inst.SetStage = SetStage
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnLoadPostPass = OnLoadPostPass

	return inst
end

return Prefab("ms_broken_pillar", fn, assets, prefabs)
