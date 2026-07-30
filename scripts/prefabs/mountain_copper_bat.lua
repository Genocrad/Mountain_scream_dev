local assets =
{
	Asset("ANIM", "anim/mountain_copper_bat.zip"),
}

------------------------------------------------------------------------------------------------------------------------

local function GetPhase(percent)
	for _, phase in ipairs(TUNING.MOUNTAIN_COPPER_BAT.DAMAGE_PHASES) do
		if percent >= phase.PCT then
			return phase
		end
	end
	return TUNING.MOUNTAIN_COPPER_BAT.DAMAGE_PHASES[#TUNING.MOUNTAIN_COPPER_BAT.DAMAGE_PHASES]
end

local function ApplySwapToOwner(inst, owner, stage)
	if owner ~= nil and owner:IsValid() and owner.AnimState ~= nil then
		owner.AnimState:OverrideSymbol("swap_object", "mountain_copper_bat", "swap_copper_bat_"..stage)
	end
end

local function ApplyPhaseVisuals(inst, stage)
	local idle = "idle_"..stage
	local swap = "swap_copper_bat_"..stage
	local image = "mountain_copper_bat_"..stage

	if not inst.AnimState:IsCurrentAnimation(idle) then
		inst.AnimState:PlayAnimation(idle)
	end

	if inst.components.inventoryitem ~= nil then
		inst.components.inventoryitem:ChangeImageName(image)
	end

	if inst.components.floater ~= nil then
		inst.components.floater:SetBankSwapOnFloat(true, -11, {
			sym_build = "mountain_copper_bat",
			sym_name = swap,
			anim = idle,
		})
		if inst.components.floater:IsFloating() then
			inst.components.floater:SwitchToFloatAnim()
		end
	end

	local owner = inst.components.equippable ~= nil and inst.components.equippable:IsEquipped()
		and inst.components.inventoryitem ~= nil
		and inst.components.inventoryitem.owner
		or nil
	ApplySwapToOwner(inst, owner, stage)
end

local function UpdatePhase(inst)
	local percent = inst.components.finiteuses ~= nil and inst.components.finiteuses:GetPercent() or 1
	local phase = GetPhase(percent)

	inst.components.weapon:SetDamage(phase.DAMAGE)

	if inst._bat_stage ~= phase.STAGE then
		inst._bat_stage = phase.STAGE
		ApplyPhaseVisuals(inst, phase.STAGE)
	end
end

------------------------------------------------------------------------------------------------------------------------

local function onequip(inst, owner)
	local stage = inst._bat_stage or 1
	ApplySwapToOwner(inst, owner, stage)
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function on_uses_finished(inst)
	local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem:GetGrandOwner() or nil
	if owner ~= nil then
		owner:PushEvent("toolbroke", { tool = inst })
	end
	inst:Remove()
end

local function OnLoad(inst)
	inst._bat_stage = nil
	UpdatePhase(inst)
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_copper_bat")
	inst.AnimState:SetBuild("mountain_copper_bat")
	inst.AnimState:PlayAnimation("idle_1")

	inst:AddTag("sharp")
	inst:AddTag("weapon")

	local floater_swap_data = {
		sym_build = "mountain_copper_bat",
		sym_name = "swap_copper_bat_1",
		anim = "idle_1",
	}
	MakeInventoryFloatable(inst, "med", 0.05, { 1.1, 0.5, 1.1 }, true, -11, floater_swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	local uses = TUNING.MOUNTAIN_COPPER_BAT.USES

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(uses)
	inst.components.finiteuses:SetUses(uses)
	inst.components.finiteuses:SetOnFinished(on_uses_finished)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(GetPhase(1).DAMAGE)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_copper_bat_1"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst._bat_stage = 1
	inst:ListenForEvent("percentusedchange", UpdatePhase)
	UpdatePhase(inst)

	inst.OnLoad = OnLoad

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_copper_bat", fn, assets)
