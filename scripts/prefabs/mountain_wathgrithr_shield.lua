local assets =
{
	Asset("ANIM", "anim/mountain_wathgrithr_shield.zip"),
}

local prefabs =
{
	"reticulearc",
	"reticulearcping",
}

------------------------------------------------------------------------------------------------------------------------

local function ReticuleTargetFn()
	return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
	if mousepos ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		local dx = mousepos.x - x
		local dz = mousepos.z - z
		local l = dx * dx + dz * dz
		if l <= 0 then
			return inst.components.reticule.targetpos
		end
		l = 6.5 / math.sqrt(l)
		return Vector3(x + dx * l, 0, z + dz * l)
	end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
	local x, y, z = inst.Transform:GetWorldPosition()
	reticule.Transform:SetPosition(x, 0, z)
	local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
	if ease and dt ~= nil then
		local rot0 = reticule.Transform:GetRotation()
		local drot = rot - rot0
		rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
	end
	reticule.Transform:SetRotation(rot)
end

------------------------------------------------------------------------------------------------------------------------

local function GetPhase(inst)
	local percent = inst.components.armor ~= nil and inst.components.armor:GetPercent() or 1
	for _, phase in ipairs(TUNING.MOUNTAIN_WATHGRITHR_SHIELD.PHASES) do
		if percent >= phase.PCT then
			return phase
		end
	end
	return TUNING.MOUNTAIN_WATHGRITHR_SHIELD.PHASES[#TUNING.MOUNTAIN_WATHGRITHR_SHIELD.PHASES]
end

local function UpdatePhaseStats(inst)
	local phase = GetPhase(inst)
	inst.components.armor:SetAbsorption(phase.ABSORPTION)
end

------------------------------------------------------------------------------------------------------------------------

local function OnEquip(inst, owner)
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Show("lantern_overlay")
	owner.AnimState:Hide("ARM_normal")
	owner.AnimState:HideSymbol("swap_object")

	owner.AnimState:OverrideSymbol("lantern_overlay", "mountain_wathgrithr_shield", "swap_shield")
	owner.AnimState:OverrideSymbol("swap_shield", "mountain_wathgrithr_shield", "swap_shield")

	if inst.components.rechargeable:GetTimeToCharge() < TUNING.MOUNTAIN_WATHGRITHR_SHIELD.COOLDOWN_ONEQUIP then
		inst.components.rechargeable:Discharge(TUNING.MOUNTAIN_WATHGRITHR_SHIELD.COOLDOWN_ONEQUIP)
	end
end

local function OnUnequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("lantern_overlay")
	owner.AnimState:ClearOverrideSymbol("swap_shield")

	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Hide("lantern_overlay")
	owner.AnimState:Show("ARM_normal")
	owner.AnimState:ShowSymbol("swap_object")
end

------------------------------------------------------------------------------------------------------------------------

local function SpellFn(inst, doer, pos)
	local phase = GetPhase(inst)
	inst.components.parryweapon:EnterParryState(
		doer,
		doer:GetAngleToPoint(pos),
		phase.PARRY_DURATION
	)
	inst.components.rechargeable:Discharge(TUNING.MOUNTAIN_WATHGRITHR_SHIELD.COOLDOWN)
end

local function OnParry(inst, doer, attacker, damage)
	doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)

	if inst.components.rechargeable:GetPercent() < TUNING.MOUNTAIN_WATHGRITHR_SHIELD.COOLDOWN_ONPARRY_REDUCTION then
		inst.components.rechargeable:SetPercent(TUNING.MOUNTAIN_WATHGRITHR_SHIELD.COOLDOWN_ONPARRY_REDUCTION)
	end

	-- 格挡防御力 < 100% 时，未吸收部分穿透到玩家
	local absorb = GetPhase(inst).PARRY_ABSORPTION
	if absorb < 1 and damage ~= nil and damage > 0 and doer.components.health ~= nil and not doer.components.health:IsDead() then
		local leftover = damage * (1 - absorb)
		if leftover > 0 then
			local cause = attacker ~= nil and (attacker.nameoverride or attacker.prefab) or "NIL"
			doer.components.health:DoDelta(-leftover, false, cause, false, attacker)
		end
		if absorb > 0 then
			inst.components.armor:TakeDamage(damage * absorb)
		end
	end
end

local function DamageFn(inst)
	return TUNING.MOUNTAIN_WATHGRITHR_SHIELD.DAMAGE
end

local function OnAttackFn(inst, attacker, target)
	inst.components.armor:TakeDamage(TUNING.MOUNTAIN_WATHGRITHR_SHIELD.USEDAMAGE)
end

local function OnDischarged(inst)
	inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
	inst.components.aoetargeting:SetEnabled(true)
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_wathgrithr_shield")
	inst.AnimState:SetBuild("mountain_wathgrithr_shield")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("toolpunch")
	inst:AddTag("battleshield")
	inst:AddTag("shield")
	inst:AddTag("parryweapon")
	inst:AddTag("weapon")
	inst:AddTag("rechargeable")
	inst:AddTag("heavyarmor")

	MakeInventoryFloatable(inst, nil, 0.2, { 1.1, 0.6, 1.1 })

	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAlwaysValid(true)
	inst.components.aoetargeting:SetAllowRiding(false)
	inst.components.aoetargeting.reticule.reticuleprefab = "reticulearc"
	inst.components.aoetargeting.reticule.pingprefab = "reticulearcping"
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
	inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
	inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
	inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.scrapbook_weapondamage = TUNING.MOUNTAIN_WATHGRITHR_SHIELD.DAMAGE

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_wathgrithr_shield"

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DamageFn)
	inst.components.weapon:SetOnAttack(OnAttackFn)

	local phase0 = TUNING.MOUNTAIN_WATHGRITHR_SHIELD.PHASES[1]

	inst:AddComponent("armor")
	inst.components.armor:InitCondition(
		TUNING.MOUNTAIN_WATHGRITHR_SHIELD.ARMOR,
		phase0.ABSORPTION
	)

	inst:ListenForEvent("percentusedchange", UpdatePhaseStats)
	UpdatePhaseStats(inst)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnequip)

	inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(SpellFn)

	inst:AddComponent("parryweapon")
	inst.components.parryweapon:SetParryArc(TUNING.MOUNTAIN_WATHGRITHR_SHIELD.PARRY_ARC)
	inst.components.parryweapon:SetOnParryFn(OnParry)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
	inst.components.rechargeable:SetOnChargedFn(OnCharged)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_wathgrithr_shield", fn, assets, prefabs)
