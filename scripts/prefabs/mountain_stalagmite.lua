local assets =
{
	Asset("ANIM", "anim/mountain_cockroach_nest.zip"),
}

local prefabs =
{
	"rocks",
	"marble",
	"mountain_suspicious_ore",
	"rock_break_fx",
}

------------------------------------------------------------------------------------------------------------------------
-- 掉落沿用蟑螂巢：1/2/3 档（纯石笋，不生成蟑螂）

SetSharedLootTable("mountain_stalagmite_1",
{
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "mountain_suspicious_ore", 1.00 },
	{ "mountain_suspicious_ore", 1.00 },
	{ "marble", 0.50 },
})

SetSharedLootTable("mountain_stalagmite_2",
{
	{ "rocks", 1.00 },
	{ "rocks", 1.00 },
	{ "mountain_suspicious_ore", 1.00 },
	{ "mountain_suspicious_ore", 0.60 },
	{ "marble", 0.50 },
})

SetSharedLootTable("mountain_stalagmite_3",
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

	if workleft <= workmax / 3 then
		return stages[3]
	elseif workleft <= workmax * 2 / 3 then
		return stages[2]
	end
	return stages[1]
end

local function OnWork(inst, worker, workleft)
	if workleft <= 0 then
		local pos = inst:GetPosition()
		SpawnPrefab("rock_break_fx").Transform:SetPosition(pos:Get())
		inst.components.lootdropper:DropLoot(pos)
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

local function MakeStalagmite(anim_stages, loottable, workleft)
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

		inst.MiniMapEntity:SetIcon(loottable..".tex")

		inst.Transform:SetScale(1.3, 1.3, 1.3)

		inst:SetPrefabNameOverride("mountain_stalagmite")

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

		MakeHauntableWork(inst)

		inst.OnLoad = OnLoad

		return inst
	end

	return fn
end

------------------------------------------------------------------------------------------------------------------------

local rock1_fn = MakeStalagmite(
	{ "nest1_full", "nest1_med", "nest1_short" },
	"mountain_stalagmite_1",
	TUNING.MOUNTAIN_STALAGMITE.WORK_1
)

local rock2_fn = MakeStalagmite(
	{ "nest2_full", "nest2_short" },
	"mountain_stalagmite_2",
	TUNING.MOUNTAIN_STALAGMITE.WORK_2
)

local rock3_fn = MakeStalagmite(
	{ "nest3_full" },
	"mountain_stalagmite_3",
	TUNING.MOUNTAIN_STALAGMITE.WORK_3
)

return Prefab("mountain_stalagmite_1", rock1_fn, assets, prefabs),
	Prefab("mountain_stalagmite_2", rock2_fn, assets, prefabs),
	Prefab("mountain_stalagmite_3", rock3_fn, assets, prefabs)
