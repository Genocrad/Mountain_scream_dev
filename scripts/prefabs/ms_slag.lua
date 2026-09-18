local assets =
{
    Asset("ANIM", "anim/ms_ore.zip"),
}

--

local function OnMined(inst)
  
    SpawnPrefab("rock_break_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())

    if inst.recipe_table then
      for k, v in pairs(inst.recipe_table) do
        local part = SpawnPrefab(v)
        part.Transform:SetPosition(inst.Transform:GetWorldPosition())
        part.components.inventoryitem:OnDropped(true)
      end
    end

    inst:Remove()
end

local function OnSave(inst, data)
	if inst.recipe_table then
		data.recipe_table = inst.recipe_table
  end
end

local function OnLoad(inst, data)
	if data ~= nil and data.recipe_table then
    inst.recipe_table = data.recipe_table
  end
end

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

  
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnFinishCallback(OnMined)

    
    MakeHauntable(inst)
    
    return inst
end

return Prefab("ms_slag", fn, assets)