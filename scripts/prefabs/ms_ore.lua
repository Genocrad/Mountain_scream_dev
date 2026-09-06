local assets =
{
    Asset("ANIM", "anim/ms_ore.zip"),
}

local function MakeOre(name)
  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ms_ore")
    inst.AnimState:SetBuild("ms_ore")
    inst.AnimState:PlayAnimation("ms_" .. name .. "_ore")

    inst:AddTag("ms_ore")
    
    MakeInventoryFloatable(inst, "small", 0.2)
    
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    --

    --
    inst:AddComponent("inspectable")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    --
    inst:AddComponent("inventoryitem")
  
    --
    MakeHauntable(inst)
    return inst
end

return Prefab("ms_" .. name .. "_ore", fn, assets)
end

return MakeOre("copper"), MakeOre("alu")