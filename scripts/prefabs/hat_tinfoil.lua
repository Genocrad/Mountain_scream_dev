local assets =
{
    Asset("ANIM", "anim/hat_tinfoil.zip"),
}


local function onequip(inst, owner)
  owner.AnimState:OverrideSymbol("swap_hat", "hat_tinfoil", "swap_hat")

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
  if owner ~= nil and owner.components.sanity ~= nil then
    owner.components.sanity.rate_modifier = 0
  end
end

local function onunequip(inst, owner)
  
  owner.AnimState:ClearOverrideSymbol("swap_hat")
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
  if owner ~= nil and owner.components.sanity ~= nil then
    owner.components.sanity.rate_modifier = 1
  end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hat_tinfoil")
    inst.AnimState:SetBuild("hat_tinfoil")
    inst.AnimState:PlayAnimation("anim")
    --inst.AnimState:SetMultColour(1, 1, 1, 0.6)

    inst:AddTag("sanity")

    inst:AddTag("hat")
    
    inst.foleysound = "dontstarve/movement/foley/metalarmour"

    local swap_data = {bank = "hat_tinfoil", anim = "anim"}
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.HAT_TINFOIL.CONDITION, TUNING.HAT_TINFOIL.ABSORTION)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("hat_tinfoil", fn, assets)