local assets =
{
	Asset("ANIM", "anim/mountain_kiki_house.zip"),
}

local prefabs =
{
	"mountain_kiki",
	"collapse_small",
}

local function RefreshWorkLevel(inst, workleft)
	if workleft > 4 then
		if not inst.AnimState:IsCurrentAnimation("idle_tall") then
			inst.AnimState:PlayAnimation("idle_tall", true)
		end
	elseif workleft > 2 then
		if not inst.AnimState:IsCurrentAnimation("idle_med") then
			inst.AnimState:PlayAnimation("idle_med", true)
		end
	else
		if not inst.AnimState:IsCurrentAnimation("idle_short") then
			inst.AnimState:PlayAnimation("idle_short", true)
		end
	end
end

local function ReturnChildren(inst)
	if inst.components.childspawner == nil then
		return
	end
	for child in pairs(inst.components.childspawner.childrenoutside) do
		if child:IsValid() then
			if child.components.homeseeker ~= nil then
				child.components.homeseeker:GoHome(true)
			end
			child:PushEvent("gohome")
		end
	end
end

local function StartSpawning(inst)
	if inst.components.childspawner ~= nil then
		inst.components.childspawner:StartSpawning()
	end
end

local function StopSpawning(inst)
	if inst.components.childspawner ~= nil then
		inst.components.childspawner:StopSpawning()
	end
end

-- Mountain floors live on the cave shard; use cave clock, not surface isday/isnight.
local function OnIsCaveDay(inst, iscaveday)
	if iscaveday then
		StartSpawning(inst)
	else
		StopSpawning(inst)
	end
end

local function OnIsCaveNight(inst, iscavenight)
	if iscavenight then
		ReturnChildren(inst)
	end
end

local function OnSpawned(inst, child)
	if not child:IsOnValidGround() then
		child:Remove()
		return
	end
	inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
end

local function OnGoHome(inst, child)
	inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
end

local function gohomevalidatefn(inst)
	return inst.components.workable ~= nil and inst.components.workable.workleft > 0
end

local function OnWork(inst, worker, workleft)
	if workleft > 0 then
		RefreshWorkLevel(inst, workleft)
	end
end

local function OnWorkFinished(inst, worker)
	if inst.components.childspawner ~= nil then
		inst.components.childspawner:ReleaseAllChildren(worker)
		inst:RemoveComponent("childspawner")
	end

	local fx = SpawnPrefab("collapse_small")
	fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	fx:SetMaterial("wood")
	inst:Remove()
end

local function OnLoad(inst, data)
	RefreshWorkLevel(inst, inst.components.workable.workleft)
	if TheWorld.state.iscaveday then
		StartSpawning(inst)
	else
		StopSpawning(inst)
		if TheWorld.state.iscavenight then
			ReturnChildren(inst)
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	inst.AnimState:SetBank("mountain_kiki_house")
	inst.AnimState:SetBuild("mountain_kiki_house")
	inst.AnimState:PlayAnimation("idle_tall", true)

	inst.MiniMapEntity:SetIcon("mountain_kiki_house.tex")

	inst:SetDeploySmartRadius(1.25)
	inst:SetPhysicsRadiusOverride(1)
	MakeObstaclePhysics(inst, inst.physicsradiusoverride)

	inst:AddTag("structure")
	inst:AddTag("cavedweller")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.MOUNTAIN_KIKI_HOUSE.MINE_WORK)
	inst.components.workable.savestate = true
	inst.components.workable:SetOnWorkCallback(OnWork)
	inst.components.workable:SetOnFinishCallback(OnWorkFinished)

	local childspawner = inst:AddComponent("childspawner")
	childspawner.childname = "mountain_kiki"
	childspawner:SetMaxChildren(TUNING.MOUNTAIN_KIKI_HOUSE.MAX_CHILDREN)
	childspawner:SetRegenPeriod(TUNING.MOUNTAIN_KIKI_HOUSE.REGEN_PERIOD)
	childspawner:SetSpawnPeriod(TUNING.MOUNTAIN_KIKI_HOUSE.SPAWN_PERIOD)
	childspawner:SetSpawnedFn(OnSpawned)
	childspawner:SetGoHomeFn(OnGoHome)
	childspawner.gohomevalidatefn = gohomevalidatefn
	childspawner:StartRegen()

	inst:WatchWorldState("iscaveday", OnIsCaveDay)
	inst:WatchWorldState("iscavenight", OnIsCaveNight)
	if TheWorld.state.iscaveday then
		StartSpawning(inst)
	else
		StopSpawning(inst)
	end

	inst.OnLoad = OnLoad

	return inst
end

return Prefab("mountain_kiki_house", fn, assets, prefabs)
