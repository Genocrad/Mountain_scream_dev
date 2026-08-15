local assets =
{
    Asset("ANIM", "anim/ms_ore.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ms_ore")
    inst.AnimState:SetBuild("ms_ore")
    inst.AnimState:PlayAnimation("ms_coal")

    inst.pickupsound = "wood"

    inst:AddTag("molebait")

    MakeInventoryFloatable(inst, "med", 0.05, 0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.HUGE_FUEL

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.BURNT
    inst.components.edible.hungervalue = 20
    inst.components.edible.healthvalue = 20

    inst:AddComponent("tradable")

    inst:AddComponent("bait")

    MakeMediumBurnable(inst, TUNING.MED_BURNTIME)
    MakeMediumPropagator(inst)

    MakeHauntableLaunchAndIgnite(inst)

    ---------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")


    return inst
end

return Prefab("ms_coal", fn, assets)
