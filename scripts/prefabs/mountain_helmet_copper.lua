local BronzeRepair = require("ms_bronze_repair")

local assets =
{
	Asset("ANIM", "anim/mountain_helmet_iron.zip"),
}

local function GetAbsorption(percent)
	for _, phase in ipairs(TUNING.MOUNTAIN_HELMET_COPPER.ABSORPTION_PHASES) do
		if percent >= phase.PCT then
			return phase.ABSORPTION
		end
	end
	return TUNING.MOUNTAIN_HELMET_COPPER.ABSORPTION_PHASES[#TUNING.MOUNTAIN_HELMET_COPPER.ABSORPTION_PHASES].ABSORPTION
end

local function UpdateAbsorption(inst)
	local percent = inst.components.armor ~= nil and inst.components.armor:GetPercent() or 1
	inst.components.armor:SetAbsorption(GetAbsorption(percent))
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_hat", "mountain_helmet_iron", "swap_hat")

	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAIR_HAT")
	owner.AnimState:Hide("HAIR_NOHAT")
	owner.AnimState:Hide("HAIR")

	if owner.isplayer then
		owner.AnimState:Hide("HEAD")
		owner.AnimState:Show("HEAD_HAT")
		owner.AnimState:Show("HEAD_HAT_NOHELM")
		owner.AnimState:Hide("HEAD_HAT_HELM")
	end
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_hat")
	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAIR_HAT")
	owner.AnimState:Show("HAIR_NOHAT")
	owner.AnimState:Show("HAIR")

	if owner.isplayer then
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAT")
		owner.AnimState:Hide("HEAD_HAT_NOHELM")
		owner.AnimState:Hide("HEAD_HAT_HELM")
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_helmet_iron")
	inst.AnimState:SetBuild("mountain_helmet_iron")
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("hat")
	inst:AddTag("metal")
	inst:AddTag("hardarmor")
	inst:AddTag("heavyarmor") -- 免疫击飞（knockback → knockbacklanded）
	inst:AddTag("waterproofer")

	local swap_data = { bank = "mountain_helmet_iron", anim = "anim" }
	MakeInventoryFloatable(inst)
	inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_helmet_iron"

	inst:AddComponent("tradable")

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("armor")
	inst.components.armor:InitCondition(
		TUNING.MOUNTAIN_HELMET_COPPER.CONDITION,
		GetAbsorption(1)
	)

	inst:ListenForEvent("percentusedchange", UpdateAbsorption)
	UpdateAbsorption(inst)

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(TUNING.MOUNTAIN_HELMET_COPPER.WATERPROOFNESS)

	BronzeRepair.MakeBronzeRepairable(inst)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_helmet_copper", fn, assets)
