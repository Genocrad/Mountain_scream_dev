local assets =
{
	Asset("ANIM", "anim/mountain_super_gildedshovel.zip"),
	Asset("ANIM", "anim/swap_super_gildedshovel.zip"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_super_gildedshovel", "swap_super_gildedshovel")
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

	inst.AnimState:SetBank("mountain_super_gildedshovel")
	inst.AnimState:SetBuild("mountain_super_gildedshovel")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("tool")

	if TheNet:GetServerGameMode() ~= "quagmire" then
		inst:AddTag("weapon")
	end

	local floater_swap_data = { sym_build = "swap_super_gildedshovel", sym_name = "swap_super_gildedshovel" }
	MakeInventoryFloatable(inst, "med", 0.05, { 0.8, 0.4, 0.8 }, true, 7, floater_swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_super_gildedshovel"

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.DIG, TUNING.MOUNTAIN_SUPER_GILDEDTOOL.EFFECTIVENESS)

	if TheNet:GetServerGameMode() ~= "quagmire" then
		local uses = TUNING.MOUNTAIN_SUPER_GILDEDTOOL.SHOVEL_USES

		local finiteuses = inst:AddComponent("finiteuses")
		finiteuses:SetMaxUses(uses)
		finiteuses:SetUses(uses)
		finiteuses:SetOnFinished(inst.Remove)
		finiteuses:SetConsumption(ACTIONS.DIG, 1)

		inst:AddComponent("weapon")
		inst.components.weapon:SetDamage(TUNING.MOUNTAIN_SUPER_GILDEDTOOL.DAMAGE)
	end

	inst:AddInherentAction(ACTIONS.DIG)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_super_gildedshovel", fn, assets)
