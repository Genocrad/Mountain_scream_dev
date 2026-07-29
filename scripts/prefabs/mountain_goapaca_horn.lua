local assets =
{
	Asset("ANIM", "anim/swap_goapaca_horn.zip"),
}

------------------------------------------------------------------------------------------------------------------------
-- 山羊角：propweapon，攻击动画与猪王摔跤木牌相同，可击飞玩家；可用 3 次

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "swap_goapaca_horn", "swap_goapaca_horn")
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

-- 官方 attack_prop 命中后会推送 propsmashed；木牌一击即碎，这里改为消耗 1 次耐久
local function OnPropSmashed(inst--[[, pos]])
	if inst.components.finiteuses ~= nil then
		inst.components.finiteuses:Use(1)
	end
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("swap_goapaca_horn")
	inst.AnimState:SetBuild("swap_goapaca_horn")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("propweapon")
	inst:AddTag("weapon")

	local floater_swap_data = { sym_build = "swap_goapaca_horn", sym_name = "swap_goapaca_horn" }
	MakeInventoryFloatable(inst, "med", 0.05, { 1.1, 0.5, 1.1 }, true, -11, floater_swap_data)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	local uses = TUNING.MOUNTAIN_GOAPACA_HORN.USES

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(uses)
	inst.components.finiteuses:SetUses(uses)
	inst.components.finiteuses:SetOnFinished(on_uses_finished)

	inst:AddComponent("weapon")
	inst.components.weapon:SetRange(TUNING.PROP_WEAPON_RANGE)
	inst.components.weapon:SetDamage(1)

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	-- 暂无官方电羊角图标（模组 atlas 尚无专用图）
	inst.components.inventoryitem.imagename = "mountain_goapaca_horn"

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst.nobrokentoolfx = true
	inst:ListenForEvent("propsmashed", OnPropSmashed)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_goapaca_horn", fn, assets)
