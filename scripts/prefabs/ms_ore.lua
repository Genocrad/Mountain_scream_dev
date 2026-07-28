local assets =
{
    Asset("ANIM", "anim/ms_ingot.zip"),
    Asset("ANIM", "anim/swap_flower.zip"),
    Asset("INV_IMAGE", "ms_copper_ingot"),
    Asset("INV_IMAGE", "ms_copper_ingot_warm"),
    Asset("INV_IMAGE", "ms_copper_ingot_hot"),
    Asset("INV_IMAGE", "ms_copper_ingot_melt"),
    Asset("INV_IMAGE", "ms_copper_ingot_left"),
    Asset("INV_IMAGE", "ms_copper_ingot_left_warm"),
    Asset("INV_IMAGE", "ms_copper_ingot_left_hot"),
    Asset("INV_IMAGE", "ms_copper_ingot_left_melt"),
    Asset("INV_IMAGE", "ms_copper_ingot_forward"),
    Asset("INV_IMAGE", "ms_copper_ingot_forward_warm"),
    Asset("INV_IMAGE", "ms_copper_ingot_forward_hot"),
    Asset("INV_IMAGE", "ms_copper_ingot_forward_melt"),
    Asset("INV_IMAGE", "ms_copper_ingot_right"),
    Asset("INV_IMAGE", "ms_copper_ingot_right_warm"),
    Asset("INV_IMAGE", "ms_copper_ingot_right_hot"),
    Asset("INV_IMAGE", "ms_copper_ingot_right_melt"),
    Asset("ATLAS", "images/inventoryimages/inventoryimages_ingots.xml"),
   
    
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ms_ingot")
    inst.AnimState:SetBuild("ms_ingot")
    inst.AnimState:PlayAnimation("idle_unchanged")


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

return Prefab("ms_copper_ore", fn, assets)