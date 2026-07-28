local assets = {
    Asset("ANIM", "anim/ms_cave_wall.zip")
}


  local function fn()
      local inst = CreateEntity()
      
      inst.persist = false
      
      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      
      inst.entity:SetCanSleep(false)
      inst:AddTag("FX")
      
      
      --inst.Transform:SetScale(1.002,4,1.002)
      inst.AnimState:SetBuild("ms_cave_wall")
      inst.AnimState:SetBank("ms_cave_wall")
        
      inst.AnimState:PlayAnimation("idle")
      inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
      inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/cave_vertical_shader.ksh"))	
      inst.AnimState:SetLayer(LAYER_BACKGROUND)
      inst.AnimState:SetSortOrder(3)
      
      inst.AnimState:SetDepthTestEnabled(true)
      inst.AnimState:SetDepthWriteEnabled(true)

      inst.AnimState:SetSymbolAddColour("wall", 0, 0, 0, 1)
      inst.entity:SetPristine()
      if not TheWorld.ismastersim then
        return inst
      end
      return inst
  end
  
  
  return Prefab("ms_cave_wall", fn, assets)
