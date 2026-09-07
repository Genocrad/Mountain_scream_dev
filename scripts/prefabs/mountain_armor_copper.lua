local BronzeRepair = require("ms_bronze_repair")

local assets =
{
	Asset("ANIM", "anim/mountain_armor_goldchest.zip"),
}

local function OnBlocked(owner)
	owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

local function GetAbsorption(percent)
	for _, phase in ipairs(TUNING.MOUNTAIN_ARMOR_COPPER.ABSORPTION_PHASES) do
		if percent >= phase.PCT then
			return phase.ABSORPTION
		end
	end
	return TUNING.MOUNTAIN_ARMOR_COPPER.ABSORPTION_PHASES[#TUNING.MOUNTAIN_ARMOR_COPPER.ABSORPTION_PHASES].ABSORPTION
end

local function UpdateAbsorption(inst)
	local percent = inst.components.armor ~= nil and inst.components.armor:GetPercent() or 1
	inst.components.armor:SetAbsorption(GetAbsorption(percent))
end

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_body", "mountain_armor_goldchest", "swap_body")
	inst:ListenForEvent("blocked", OnBlocked, owner)
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")
	inst:RemoveEventCallback("blocked", OnBlocked, owner)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_armor_goldchest")
	inst.AnimState:SetBuild("mountain_armor_goldchest")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("metal")
	inst:AddTag("hardarmor")
	inst:AddTag("heavyarmor") -- 免疫击飞（knockback → knockbacklanded）

	inst.foleysound = "dontstarve/movement/foley/metalarmour"

	local swap_data = { bank = "mountain_armor_goldchest", anim = "idle" }
	MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_armor_goldchest"

	inst:AddComponent("armor")
	inst.components.armor:InitCondition(
		TUNING.MOUNTAIN_ARMOR_COPPER.CONDITION,
		GetAbsorption(1)
	)

	inst:ListenForEvent("percentusedchange", UpdateAbsorption)
	UpdateAbsorption(inst)

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	BronzeRepair.MakeBronzeRepairable(inst)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_armor_copper", fn, assets)
