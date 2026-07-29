local assets =
{
	Asset("ANIM", "anim/mountain_copper_axe.zip"),
	Asset("ANIM", "anim/swap_copper_axe.zip"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_copper_axe", "swap_axe")
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
	inst.components.tool:SetAction(ACTIONS.CHOP, GetWorkEfficiency(percent))
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_copper_axe")
	inst.AnimState:SetBuild("mountain_copper_axe")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("sharp")
	inst:AddTag("possessable_axe")
	inst:AddTag("tool")

	if TheNet:GetServerGameMode() ~= "quagmire" then
		inst:AddTag("weapon")
	end

	local floater_swap_data = { sym_build = "swap_copper_axe", sym_name = "swap_axe" }
	MakeInventoryFloatable(inst, "small", 0.05, { 1.2, 0.75, 1.2 }, true, -11, floater_swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_copper_axe"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.CHOP, 1)

	if TheNet:GetServerGameMode() ~= "quagmire" then
		local uses = TUNING.MOUNTAIN_COPPER_AXE.USES

		inst:AddComponent("finiteuses")
		inst.components.finiteuses:SetMaxUses(uses)
		inst.components.finiteuses:SetUses(uses)
		inst.components.finiteuses:SetOnFinished(inst.Remove)
		inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)

		inst:ListenForEvent("percentusedchange", UpdateWorkEfficiency)
		UpdateWorkEfficiency(inst)

		inst:AddComponent("weapon")
		inst.components.weapon:SetDamage(TUNING.AXE_DAMAGE)
	end

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_copper_axe", fn, assets)
