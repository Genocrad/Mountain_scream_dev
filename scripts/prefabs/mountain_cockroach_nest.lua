local assets =
{
	Asset("ANIM", "anim/mountain_cockroach_nest.zip"),
}

local prefabs =
{
	"mountain_cockroach",
	"rocks",
	"marble",
	"mountain_suspicious_ore",
	"rock_break_fx",
}

------------------------------------------------------------------------------------------------------------------------
-- nest1：rocks×3 + suspicious ore×2 + marble 50%
-- nest2：rocks×2 + suspicious ore×1.6（必掉1，60%再掉1）+ marble 50%
-- nest3：suspicious ore×1 + marble 50%
------------------------------------------------------------------------------------------------------------------------

SetSharedLootTable("mountain_cockroach_nest_1",
{
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "mountain_suspicious_ore", 1.00 },
	{ "mountain_suspicious_ore", 1.00 },
	{ "marble", 0.50 },
})

SetSharedLootTable("mountain_cockroach_nest_2",
{
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "mountain_suspicious_ore", 1.00 },
	{ "mountain_suspicious_ore", 0.60 },
	{ "marble", 0.50 },
})

SetSharedLootTable("mountain_cockroach_nest_3",
{
	{ "mountain_suspicious_ore", 1.00 },
	{ "marble", 0.50 },
})

------------------------------------------------------------------------------------------------------------------------

local function GetAnimForWork(inst, workleft)
	local stages = inst._anim_stages
	local workmax = inst._work_max
	local n = #stages

	if n <= 1 then
		return stages[1]
	elseif n == 2 then
		return workleft <= workmax / 2 and stages[2] or stages[1]
	end

	-- full / med / short
	if workleft <= workmax / 3 then
		return stages[3]
	elseif workleft <= workmax * 2 / 3 then
		return stages[2]
	end
	return stages[1]
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

local function OnIsDusk(inst, isdusk)
	if isdusk then
		-- 傍晚只开始逐只放出，不一次清空巢内
		StartSpawning(inst)
	else
		StopSpawning(inst)
	end
end

local function OnIsNight(inst, isnight)
	if isnight then
		ReturnChildren(inst)
	end
end

local function OnIsDay(inst, isday)
	if isday then
		StopSpawning(inst)
		ReturnChildren(inst)
	end
end

local function OnSpawned(inst, child)
	if not child:IsOnValidGround() then
		child:Remove()
		return
	end
end

local function gohomevalidatefn(inst)
	return inst.components.workable ~= nil and inst.components.workable.workleft > 0
end

-- 敲击时放出巢内全部，并让已在外的蟑螂一起仇恨敲击者。
-- 注意：官方 ReleaseAllChildren 在目标 invincible 时会直接 return，故改用手动循环生成。
local function ReleaseGuards(inst, attacker)
	local spawner = inst.components.childspawner
	if spawner == nil then
		return
	end

	local target = attacker
	if target ~= nil
		and target.components.health ~= nil
		and target.components.health.invincible then
		target = nil
	end

	local failures = 0
	while spawner:CanSpawn() and failures < 6 do
		local child = spawner:SpawnChild(target)
		if child == nil then
			failures = failures + 1
		else
			failures = 0
		end
	end

	if attacker ~= nil and attacker:IsValid() then
		for child in pairs(spawner.childrenoutside) do
			if child:IsValid() and child.components.combat ~= nil then
				child.components.combat:SetTarget(attacker)
			end
		end
	end
end

local function OnWork(inst, worker, workleft)
	ReleaseGuards(inst, worker)

	if workleft <= 0 then
		if inst.components.childspawner ~= nil then
			inst:RemoveComponent("childspawner")
		end
		local pos = inst:GetPosition()
		SpawnPrefab("rock_break_fx").Transform:SetPosition(pos:Get())
		inst.components.lootdropper:DropLoot(pos)
		inst:Remove()
	else
		inst.AnimState:PlayAnimation(GetAnimForWork(inst, workleft))
	end
end

local function SyncSpawnState(inst)
	if TheWorld.state.isdusk then
		StartSpawning(inst)
	else
		StopSpawning(inst)
		if TheWorld.state.isnight or TheWorld.state.isday then
			ReturnChildren(inst)
		end
	end
end

local function OnLoad(inst, data)
	if inst.components.workable ~= nil then
		inst.AnimState:PlayAnimation(GetAnimForWork(inst, inst.components.workable.workleft))
	end
	SyncSpawnState(inst)
end

------------------------------------------------------------------------------------------------------------------------

local function MakeNest(anim_stages, loottable, workleft, max_children, minimap_icon)
	local default_anim = anim_stages[1]

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()
		inst.entity:AddMiniMapEntity()

		MakeObstaclePhysics(inst, 1)

		inst.AnimState:SetBank("mountain_cockroach_nest")
		inst.AnimState:SetBuild("mountain_cockroach_nest")
		inst.AnimState:PlayAnimation(default_anim)

		inst.MiniMapEntity:SetIcon(minimap_icon..".tex")

		inst.Transform:SetScale(1.3, 1.3, 1.3)

		inst:SetPrefabNameOverride("mountain_cockroach_nest")

		inst:AddTag("boulder")

		inst.scrapbook_anim = default_anim

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst._anim_stages = anim_stages
		inst._work_max = workleft

		local color = 0.5 + math.random() * 0.5
		inst.AnimState:SetMultColour(color, color, color, 1)

		inst:AddComponent("lootdropper")
		inst.components.lootdropper:SetChanceLootTable(loottable)

		inst:AddComponent("inspectable")

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.MINE)
		inst.components.workable:SetWorkLeft(workleft)
		inst.components.workable.savestate = true
		inst.components.workable:SetOnWorkCallback(OnWork)

		local childspawner = inst:AddComponent("childspawner")
		childspawner.childname = "mountain_cockroach"
		childspawner:SetMaxChildren(max_children)
		childspawner:SetRegenPeriod(TUNING.MOUNTAIN_COCKROACH_NEST.REGEN_PERIOD)
		childspawner:SetSpawnPeriod(TUNING.MOUNTAIN_COCKROACH_NEST.SPAWN_PERIOD)
		childspawner:SetSpawnedFn(OnSpawned)
		childspawner.gohomevalidatefn = gohomevalidatefn
		-- 岩石占位较大，拉开生成半径减少 FindWalkableOffset 失败导致放不全
		childspawner.spawnradius = { min = 1, max = 2 }
		childspawner:StartRegen()

		inst:WatchWorldState("isdusk", OnIsDusk)
		inst:WatchWorldState("isnight", OnIsNight)
		inst:WatchWorldState("isday", OnIsDay)
		SyncSpawnState(inst)

		MakeHauntableWork(inst)

		inst.OnLoad = OnLoad

		return inst
	end

	return fn
end

------------------------------------------------------------------------------------------------------------------------

local nest1_fn = MakeNest(
	{ "nest1_full", "nest1_med", "nest1_short" },
	"mountain_cockroach_nest_1",
	TUNING.MOUNTAIN_COCKROACH_NEST.WORK_1,
	TUNING.MOUNTAIN_COCKROACH_NEST.MAX_CHILDREN_1,
	"mountain_stalagmite_1"
)

local nest2_fn = MakeNest(
	{ "nest2_full", "nest2_short" },
	"mountain_cockroach_nest_2",
	TUNING.MOUNTAIN_COCKROACH_NEST.WORK_2,
	TUNING.MOUNTAIN_COCKROACH_NEST.MAX_CHILDREN_2,
	"mountain_stalagmite_2"
)

local nest3_fn = MakeNest(
	{ "nest3_full" },
	"mountain_cockroach_nest_3",
	TUNING.MOUNTAIN_COCKROACH_NEST.WORK_3,
	TUNING.MOUNTAIN_COCKROACH_NEST.MAX_CHILDREN_3,
	"mountain_stalagmite_3"
)

return Prefab("mountain_cockroach_nest_1", nest1_fn, assets, prefabs),
	Prefab("mountain_cockroach_nest_2", nest2_fn, assets, prefabs),
	Prefab("mountain_cockroach_nest_3", nest3_fn, assets, prefabs)
