local assets =
{
	Asset("ANIM", "anim/mountain_monster_drumstick.zip"),
}

local prefabs =
{
	"mountain_monster_drumstick_cooked",
	"spoiled_food",
}

local function common(anim, tags, cookable)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_monster_drumstick")
	inst.AnimState:SetBuild("mountain_monster_drumstick")
	inst.AnimState:PlayAnimation(anim)
	inst.scrapbook_anim = anim

	inst:AddTag("meat")
	inst:AddTag("monstermeat")
	inst:AddTag("catfood")
	if tags ~= nil then
		for i, v in ipairs(tags) do
			inst:AddTag(v)
		end
	end

	if cookable ~= nil then
		inst:AddTag("cookable")
	end

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("edible")
	inst.components.edible.ismeat = true
	inst.components.edible.foodtype = FOODTYPE.MEAT
	inst.components.edible.secondaryfoodtype = FOODTYPE.MONSTER

	inst:AddComponent("bait")

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")
	inst.components.tradable.goldvalue = 0

	inst:AddComponent("perishable")
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	if cookable ~= nil then
		inst:AddComponent("cookable")
		inst.components.cookable.product = cookable.product
	end

	MakeHauntableLaunchAndPerish(inst)

	return inst
end

local function raw_fn()
	local inst = common("raw", { "rawmeat" }, { product = "mountain_monster_drumstick_cooked" })

	if not TheWorld.ismastersim then
		return inst
	end

	local cfg = TUNING.MOUNTAIN_MONSTER_DRUMSTICK
	inst.components.edible.healthvalue = cfg.HEALTH
	inst.components.edible.hungervalue = cfg.HUNGER
	inst.components.edible.sanityvalue = cfg.SANITY
	inst.components.perishable:SetPerishTime(cfg.PERISH_TIME)
	inst.components.inventoryitem.imagename = "mountain_monster_drumstick"

	inst.components.floater:SetVerticalOffset(0.2)

	return inst
end

local function cooked_fn()
	local inst = common("cooked")

	if not TheWorld.ismastersim then
		return inst
	end

	local cfg = TUNING.MOUNTAIN_MONSTER_DRUMSTICK_COOKED
	inst.components.edible.healthvalue = cfg.HEALTH
	inst.components.edible.hungervalue = cfg.HUNGER
	inst.components.edible.sanityvalue = cfg.SANITY
	inst.components.perishable:SetPerishTime(cfg.PERISH_TIME)
	inst.components.inventoryitem.imagename = "mountain_monster_drumstick_cooked"

	inst.components.floater:SetVerticalOffset(0.15)
	inst.components.floater:SetScale(0.85)

	return inst
end

return Prefab("mountain_monster_drumstick", raw_fn, assets, prefabs),
	Prefab("mountain_monster_drumstick_cooked", cooked_fn, assets)
