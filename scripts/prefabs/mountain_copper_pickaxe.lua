local assets =
{
	Asset("ANIM", "anim/mountain_copper_pickaxe.zip"),
	Asset("ANIM", "anim/swap_copper_pickaxe.zip"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_copper_pickaxe", "swap_pickaxe")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function GetWorkEfficiency(percent)
	for _, phase in ipairs(TUNING.MOUNTAIN_COPPER_TOOL.EFFICIENCY_PHASES) do
		if percent >= phase.PCT then
			return phase.EFFICIENCY
		end
	end
	return TUNING.MOUNTAIN_COPPER_TOOL.EFFICIENCY_PHASES[#TUNING.MOUNTAIN_COPPER_TOOL.EFFICIENCY_PHASES].EFFICIENCY
end

local function UpdateWorkEfficiency(inst)
	local percent = inst.components.finiteuses ~= nil and inst.components.finiteuses:GetPercent() or 1
	inst.components.tool:SetAction(ACTIONS.MINE, GetWorkEfficiency(percent))
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_copper_pickaxe")
	inst.AnimState:SetBuild("mountain_copper_pickaxe")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("sharp")
	inst:AddTag("tool")
	inst:AddTag("weapon")

	local floater_swap_data = { sym_build = "swap_copper_pickaxe", sym_name = "swap_pickaxe" }
	MakeInventoryFloatable(inst, "med", 0.05, { 0.75, 0.4, 0.75 }, true, -11, floater_swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_copper_pickaxe"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.PICK_DAMAGE)

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.MINE, 1)

	local uses = TUNING.MOUNTAIN_COPPER_PICKAXE.USES

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(uses)
	inst.components.finiteuses:SetUses(uses)
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 1)

	inst:ListenForEvent("percentusedchange", UpdateWorkEfficiency)
	UpdateWorkEfficiency(inst)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_copper_pickaxe", fn, assets)
