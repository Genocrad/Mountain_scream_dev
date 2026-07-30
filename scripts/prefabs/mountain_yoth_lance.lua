local assets =
{
	Asset("ANIM", "anim/mountain_yoth_lance.zip"),
}

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "mountain_yoth_lance", "swap_lance")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function on_uses_finished(inst)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner then
		owner:PushEvent("toolbroke", { tool = inst })
	end
	inst:Remove()
end

local function OnHitOther(inst, owner, target)
	local fx = SpawnPrefab((target:HasTag("largecreature") or target:HasTag("epic")) and "round_puff_fx_lg" or "round_puff_fx_sm")
	fx.Transform:SetPosition(target.Transform:GetWorldPosition())
end

local function GetAttackDamage(percent)
	for _, phase in ipairs(TUNING.MOUNTAIN_YOTH_LANCE.DAMAGE_PHASES) do
		if percent >= phase.PCT then
			return phase.DAMAGE
		end
	end
	return TUNING.MOUNTAIN_YOTH_LANCE.DAMAGE_PHASES[#TUNING.MOUNTAIN_YOTH_LANCE.DAMAGE_PHASES].DAMAGE
end

local function UpdateAttackDamage(inst)
	local percent = inst.components.finiteuses ~= nil and inst.components.finiteuses:GetPercent() or 1
	inst.components.weapon:SetDamage(GetAttackDamage(percent))
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_yoth_lance")
	inst.AnimState:SetBuild("mountain_yoth_lance")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("nopunch")
	inst:AddTag("sharp")
	inst:AddTag("pointy")
	inst:AddTag("lancejab")
	inst:AddTag("weapon")

	MakeInventoryFloatable(inst, "med", 0.05, { 1.8, 0.5, 1 }, true, -37)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.floater:SetBankSwapOnFloat(true, -37, { sym_build = "mountain_yoth_lance", sym_name = "swap_lance" })

	local uses = TUNING.MOUNTAIN_YOTH_LANCE.USES

	local finiteuses = inst:AddComponent("finiteuses")
	finiteuses:SetMaxUses(uses)
	finiteuses:SetUses(uses)
	finiteuses:SetOnFinished(on_uses_finished)

	local weapon = inst:AddComponent("weapon")
	weapon:SetDamage(GetAttackDamage(1))
	weapon:SetRange(TUNING.MOUNTAIN_YOTH_LANCE.LENGTH)

	inst:ListenForEvent("percentusedchange", UpdateAttackDamage)
	UpdateAttackDamage(inst)

	local joustsource = inst:AddComponent("joustsource")
	joustsource:SetSpeed(TUNING.MOUNTAIN_YOTH_LANCE.JOUST_SPEED)
	joustsource:SetLanceLength(TUNING.MOUNTAIN_YOTH_LANCE.LENGTH)
	joustsource:SetRunAnimLoopCount(TUNING.MOUNTAIN_YOTH_LANCE.RUNANIM_LOOP_COUNT)
	joustsource:SetOnHitOtherFn(OnHitOther)

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_yoth_lance"

	inst:AddComponent("fencerotator")

	local equippable = inst:AddComponent("equippable")
	equippable:SetOnEquip(onequip)
	equippable:SetOnUnequip(onunequip)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_yoth_lance", fn, assets)
