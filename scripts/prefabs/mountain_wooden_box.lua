local assets =
{
	Asset("ANIM", "anim/mountain_wooden_box.zip"),
}

local COMMON_LOOT =
{
	{ prefab = "carrot" },
	{ prefab = "corn" },
	{ prefab = "eggplant" },
	{ prefab = "pumpkin" },
	{ prefab = "cactus_meat" },
	{ prefab = "blue_cap" },
	{ prefab = "green_cap" },
	{ prefab = "red_cap" },
	{ prefab = "asparagus" },
	{ prefab = "garlic" },
	{ prefab = "potato" },
	{ prefab = "tomato" },
	{ prefab = "onion" },
	{ prefab = "pepper" },
	{ prefab = "durian" },
	{ prefab = "cave_banana" },
	{ prefab = "dragonfruit" },
	{ prefab = "pomegranate" },
	{ prefab = "berries" },
	{ prefab = "berries_juicy" },
	{ prefab = "wormlight" },
	{ prefab = "wormlight_lesser" },
	{ prefab = "ancientfruit_nightvision" },
	{ prefab = "watermelon" },
	{ prefab = "fig" },
	{ prefab = "seeds", count = 5 },
	{ prefab = "birchnutdrake" },
}

local MATERIAL_LOOT =
{
	{ prefab = "cutgrass", count = 5 },
	{ prefab = "twigs", count = 5 },
	{ prefab = "livinglog", count = 2 },
	{ prefab = "lightbulb", count = 10 },
}

local RARE_LOOT =
{
	"ancienttree_seed",
	"tree_rock_seed",
	"mandrake",
}

local prefabs = { "log", "collapse_small" }
for _, loot in ipairs(COMMON_LOOT) do
	table.insert(prefabs, loot.prefab)
end
for _, loot in ipairs(MATERIAL_LOOT) do
	table.insert(prefabs, loot.prefab)
end
for _, prefab in ipairs(RARE_LOOT) do
	table.insert(prefabs, prefab)
end

local function DropStack(inst, prefab, count)
	local item = inst.components.lootdropper:SpawnLootPrefab(prefab)
	if item ~= nil and count ~= nil and count > 1 and item.components.stackable ~= nil then
		item.components.stackable:SetStackSize(count)
	end
end

local function DropBoxLoot(inst)
	-- 必定掉落 1 木头
	DropStack(inst, "log", 1)

	if math.random() < 0.75 then
		local loot = COMMON_LOOT[math.random(#COMMON_LOOT)]
		DropStack(inst, loot.prefab, loot.count)
	else
		local loot = MATERIAL_LOOT[math.random(#MATERIAL_LOOT)]
		DropStack(inst, loot.prefab, loot.count)
	end

	-- 稀有掉落为独立的 0.1% 判定。
	if math.random() < 0.001 then
		DropStack(inst, RARE_LOOT[math.random(#RARE_LOOT)])
	end
end

local WORK_LEFT = 1

local function OnWorked(inst, worker, workleft, workdone)
	worker.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")

	local num_opened = math.clamp(math.ceil(workdone / WORK_LEFT), 1, inst.components.stackable:StackSize())
	for _ = 1, num_opened do
		DropBoxLoot(inst)
	end

	local top = inst.components.stackable:Get(num_opened)
	top:Remove()
end

local function OnStackSizeChanged(inst, data)
	if data ~= nil and data.stacksize ~= nil and inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(data.stacksize * WORK_LEFT)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_wooden_box")
	inst.AnimState:SetBuild("mountain_wooden_box")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("choppable")
	inst:AddTag("wooden")

	MakeInventoryFloatable(inst, "med", 0.1, 0.75)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_wooden_box"

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.CHOP)
	inst.components.workable:SetWorkLeft(WORK_LEFT * inst.components.stackable.stacksize)
	inst.components.workable:SetOnWorkCallback(OnWorked)

	inst:ListenForEvent("stacksizechange", OnStackSizeChanged)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_wooden_box", fn, assets, prefabs)
