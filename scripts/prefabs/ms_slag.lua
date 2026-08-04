local assets =
{
    Asset("ANIM", "anim/ms_ore.zip"),
}

--
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ms_ore")
    inst.AnimState:SetBuild("ms_ore")
    inst.AnimState:PlayAnimation("ms_slag")
    inst.AnimState:SetFinalOffset(2)



    MakeInventoryFloatable(inst, "small", 0.2)
    
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end


    local inspectable = inst:AddComponent("inspectable")
    
    local inventoryitem = inst:AddComponent("inventoryitem")

    local stackable = inst:AddComponent("stackable")
    stackable.maxsize = TUNING.STACK_SIZE_MEDITEM
    
    MakeHauntable(inst)
    
    return inst
end

return Prefab("ms_slag", fn, assets)