local assets =
{
	Asset("ANIM", "anim/ms_wall_stone.zip"),
}

local prefabs =
{
	"mountain_suspicious_ore",
	"rock_break_fx",
}

SetSharedLootTable("ms_wall_stone",
{
	{ "mountain_suspicious_ore", 1.00 },
	{ "mountain_suspicious_ore", 0.50 },
})

------------------------------------------------------------------------------------------------------------------------

local function OnWork(inst, worker, workleft)
	if workleft <= 0 then
		local x, y, z = inst.Transform:GetWorldPosition()
		local pos = Vector3(x, y, z)
		SpawnPrefab("rock_break_fx").Transform:SetPosition(pos:Get())
		inst.components.lootdropper:DropLoot(pos)
		inst:Remove()
	end
end

local function OnLoad(inst)
	if inst.components.workable ~= nil then
		-- 仅铝镐投掷可挖，读档后保持不可点选开采
		inst.components.workable:SetWorkable(false)
	end
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	-- 单视角贴图：普通直立放置在墙面高度即可，不走墙体平铺+垂直着色器。
	inst.AnimState:SetBank("ms_wall_stone")
	inst.AnimState:SetBuild("ms_wall_stone")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("boulder")
	inst:AddTag("ms_wall_stone")

	inst.scrapbook_anim = "idle"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.scrapbook_deps = {}

	local color = 0.5 + math.random() * 0.5
	inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("ms_wall_stone")

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.MS_WALL_STONE.WORK)
	inst.components.workable.savestate = true
	inst.components.workable:SetOnWorkCallback(OnWork)
	-- 禁止普通镐点挖；铝镐投掷命中前会临时 SetWorkable(true)
	inst.components.workable:SetWorkable(false)

	MakeHauntableWork(inst)

	inst.OnLoad = OnLoad

	return inst
end

return Prefab("ms_wall_stone", fn, assets, prefabs)
