local assets =
{
	Asset("ANIM", "anim/mountain_snowpeak_stones.zip"),
}

local prefabs =
{
	"rocks",
	"ice",
	"mountain_snowball",
	"rock_break_fx",
}

------------------------------------------------------------------------------------------------------------------------

SetSharedLootTable("mountain_snowpeak_stone_1",
{
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "ice", 1.00 },
	{ "ice", 1.00 },
	{ "mountain_snowball", 1.00 },
	{ "mountain_snowball", 1.00 },
	{ "mountain_snowball", 1.00 },
})

SetSharedLootTable("mountain_snowpeak_stone_2",
{
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "mountain_snowball", 1.00 },
	{ "mountain_snowball", 1.00 },
})

SetSharedLootTable("mountain_snowpeak_stone_3",
{
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "mountain_snowball", 1.00 },
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

	if workleft <= workmax / 3 then
		return stages[3]
	elseif workleft <= workmax * 2 / 3 then
		return stages[2]
	end
	return stages[1]
end

local function OnWork(inst, worker, workleft)
	if workleft <= 0 then
		local pt = inst:GetPosition()
		SpawnPrefab("rock_break_fx").Transform:SetPosition(pt:Get())
		inst.components.lootdropper:DropLoot(pt)
		inst:Remove()
	else
		inst.AnimState:PlayAnimation(GetAnimForWork(inst, workleft))
	end
end

local function OnLoad(inst)
	if inst.components.workable ~= nil then
		inst.AnimState:PlayAnimation(GetAnimForWork(inst, inst.components.workable.workleft))
	end
end

------------------------------------------------------------------------------------------------------------------------

local function MakeSnowpeakStone(anim_stages, loottable, workleft, physics_radius)
	local default_anim = anim_stages[1]

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()
		inst.entity:AddMiniMapEntity()

		MakeObstaclePhysics(inst, physics_radius)

		inst.AnimState:SetBank("mountain_snowpeak_stones")
		inst.AnimState:SetBuild("mountain_snowpeak_stones")
		inst.AnimState:PlayAnimation(default_anim)

		inst.MiniMapEntity:SetIcon(loottable..".tex")

		inst:SetPrefabNameOverride("mountain_snowpeak_stone")

		inst:AddTag("boulder")

		MakeSnowCoveredPristine(inst)

		inst.scrapbook_anim = default_anim

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst._anim_stages = anim_stages
		inst._work_max = workleft

		inst:AddComponent("lootdropper")
		inst.components.lootdropper:SetChanceLootTable(loottable)

		inst:AddComponent("inspectable")

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.MINE)
		inst.components.workable:SetWorkLeft(workleft)
		inst.components.workable.savestate = true
		inst.components.workable:SetOnWorkCallback(OnWork)

		MakeSnowCovered(inst)
		MakeHauntableWork(inst)

		inst.OnLoad = OnLoad

		return inst
	end

	return fn
end

------------------------------------------------------------------------------------------------------------------------

local stone1_fn = MakeSnowpeakStone(
	{ "idle1_full", "idle1_med", "idle1_short" },
	"mountain_snowpeak_stone_1",
	TUNING.MOUNTAIN_SNOWPEAK_STONE.WORK_1,
	1
)

local stone2_fn = MakeSnowpeakStone(
	{ "idle2_full", "idle2_short" },
	"mountain_snowpeak_stone_2",
	TUNING.MOUNTAIN_SNOWPEAK_STONE.WORK_2,
	0.75
)

local stone3_fn = MakeSnowpeakStone(
	{ "idle3_full" },
	"mountain_snowpeak_stone_3",
	TUNING.MOUNTAIN_SNOWPEAK_STONE.WORK_3,
	0.5
)

return Prefab("mountain_snowpeak_stone_1", stone1_fn, assets, prefabs),
	Prefab("mountain_snowpeak_stone_2", stone2_fn, assets, prefabs),
	Prefab("mountain_snowpeak_stone_3", stone3_fn, assets, prefabs)
