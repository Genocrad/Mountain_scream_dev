local assets = {
  Asset("ANIM", "anim/gas_sediment_mountain.zip")
}



  local function fn()
      local inst = CreateEntity()

      inst:AddTag("FX")

      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddNetwork()
      
      inst.Transform:SetScale(2,2,2)
      inst.AnimState:SetBuild("gas_sediment_mountain")
      inst.AnimState:SetBank("gas_mountain_sediment")
        
      inst.AnimState:PlayAnimation("idle")
      inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
      inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/mountain_vertical_shader.ksh"))	

      inst.AnimState:SetDepthTestEnabled(true)
      inst.AnimState:SetDepthWriteEnabled(true)
      
      inst.AnimState:SetSymbolAddColour("side_1", 0.8, 0.2, 1, 1)
      inst.AnimState:SetSymbolAddColour("side_2", 0.8, 0.8, 1, 1)
      return inst
  end
  return Prefab("gas_mountain_sediment", fn, assets)

