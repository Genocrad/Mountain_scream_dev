local assets = {
    Asset("ANIM", "anim/gas_mountain_wall.zip")
}


  local function fn()
      local inst = CreateEntity()

      inst:AddTag("FX")

      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddNetwork()
     
      inst.Transform:SetScale(3,3,5)
      inst.AnimState:SetBuild("gas_mountain_wall")
      inst.AnimState:SetBank("gas_mountain_wall")
        
      inst.AnimState:PlayAnimation("idle")
      inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
      inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/mountain_vertical_shader.ksh"))	
      
      inst.AnimState:SetDepthTestEnabled(true)
      inst.AnimState:SetDepthWriteEnabled(true)

      inst.AnimState:SetSymbolAddColour("wall", 0.59, 0.5, 1, 1)
      
      return inst
  end
  return Prefab("gas_mountain_wall", fn, assets)