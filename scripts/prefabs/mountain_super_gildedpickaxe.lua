local assets =
{
	Asset("ANIM", "anim/mountain_super_gildedpickaxe.zip"),
	Asset("ANIM", "anim/swap_super_gildedpickaxe.zip"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_super_gildedpickaxe", "swap_super_gildedpickaxe")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_super_gildedpickaxe")
	inst.AnimState:SetBuild("mountain_super_gildedpickaxe")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("sharp")
	inst:AddTag("tool")
	inst:AddTag("weapon")

	local floater_swap_data = { sym_build = "swap_super_gildedpickaxe", sym_name = "swap_super_gildedpickaxe" }
	MakeInventoryFloatable(inst, "med", 0.05, { 0.75, 0.4, 0.75 }, true, -11, floater_swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_super_gildedpickaxe"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	local uses = TUNING.MOUNTAIN_SUPER_GILDEDTOOL.PICKAXE_USES

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.MOUNTAIN_SUPER_GILDEDTOOL.DAMAGE)

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.MINE, TUNING.MOUNTAIN_SUPER_GILDEDTOOL.EFFECTIVENESS)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(uses)
	inst.components.finiteuses:SetUses(uses)
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 1)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_super_gildedpickaxe", fn, assets)
