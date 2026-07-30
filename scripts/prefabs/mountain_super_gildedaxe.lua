local assets =
{
	Asset("ANIM", "anim/mountain_super_gildedaxe.zip"),
	Asset("ANIM", "anim/swap_super_gildedaxe.zip"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_super_gildedaxe", "swap_super_gildedaxe")
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

	inst.AnimState:SetBank("mountain_super_gildedaxe")
	inst.AnimState:SetBuild("mountain_super_gildedaxe")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("sharp")
	inst:AddTag("possessable_axe")
	inst:AddTag("tool")

	if TheNet:GetServerGameMode() ~= "quagmire" then
		inst:AddTag("weapon")
	end

	local floater_swap_data = { sym_build = "swap_super_gildedaxe", sym_name = "swap_super_gildedaxe" }
	MakeInventoryFloatable(inst, "small", 0.05, { 1.2, 0.75, 1.2 }, true, -11, floater_swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_super_gildedaxe"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.CHOP, TUNING.MOUNTAIN_SUPER_GILDEDTOOL.EFFECTIVENESS)

	if TheNet:GetServerGameMode() ~= "quagmire" then
		local uses = TUNING.MOUNTAIN_SUPER_GILDEDTOOL.AXE_USES

		inst:AddComponent("finiteuses")
		inst.components.finiteuses:SetMaxUses(uses)
		inst.components.finiteuses:SetUses(uses)
		inst.components.finiteuses:SetOnFinished(inst.Remove)
		inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)

		inst:AddComponent("weapon")
		inst.components.weapon:SetDamage(TUNING.MOUNTAIN_SUPER_GILDEDTOOL.DAMAGE)
	end

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_super_gildedaxe", fn, assets)
