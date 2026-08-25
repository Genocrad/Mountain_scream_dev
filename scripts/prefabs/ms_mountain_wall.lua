local assets = {
    Asset("ANIM", "anim/ms_mountain_wall.zip")
}

  local function MakeWall(name, customfn)
    local function fn()
      local inst = CreateEntity()

      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddNetwork()
      

      inst:AddTag("FX")
      inst:AddTag("DECOR")
      inst:AddTag("NOCLICK")
      inst:AddTag("ms_wall")
      
      inst.Transform:SetScale(1.01,4,1.01)
      inst.AnimState:SetBuild("ms_mountain_wall")
      inst.AnimState:SetBank("ms_mountain_wall")
      inst.AnimState:SetSymbolAddColour("filler", 1,1, 1, 1)
      
      inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
      inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/mountain_vertical_shader.ksh"))	
      
      inst.AnimState:SetDepthTestEnabled(true)
      inst.AnimState:SetDepthWriteEnabled(true)
      
      if customfn then
        customfn(inst)
      end
      
      inst.entity:SetPristine()
      if not TheWorld.ismastersim then
        return inst
      end
      inst:AddComponent("savedrotation")
      return inst
  end
    
    
    
    
    
    return Prefab(name, fn, assets)
  end
  return MakeWall("ms_mountain_wall", function(inst) inst.AnimState:PlayAnimation("idle") inst.AnimState:SetSymbolAddColour("wall", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_corner_wall_right", function(inst) inst.AnimState:PlayAnimation("idle_right_corner") inst.AnimState:SetSymbolAddColour("wall_half_right", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_corner_wall_left", function(inst) inst.AnimState:PlayAnimation("idle_left_corner") inst.AnimState:SetSymbolAddColour("wall_half_left", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_slope", function(inst) inst.AnimState:PlayAnimation("idle_left_slope") inst.AnimState:SetSymbolAddColour("wall_half_right", 0.01, 0.07, 0, 1) inst.AnimState:SetSymbolAddColour("wall_half_left", 0.01, 0.07, 0, 1) inst.AnimState:SetSymbolLightOverride("wall_half_right", 1) end),
  MakeWall("ms_mountain_wall_snow", function(inst) inst.AnimState:PlayAnimation("idle_snow_mountain") inst.AnimState:SetSymbolAddColour("wall", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_corner_wall_right_snow", function(inst) inst.AnimState:PlayAnimation("idle_right_corner_snow_mountain") inst.AnimState:SetSymbolAddColour("wall_half_right", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_corner_wall_left_snow", function(inst) inst.AnimState:PlayAnimation("idle_left_corner_snow_mountain") inst.AnimState:SetSymbolAddColour("wall_half_left", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_slope_snow", function(inst) inst.AnimState:PlayAnimation("idle_left_slope_snow_mountain") inst.AnimState:SetSymbolAddColour("wall_half_right", 0.01, 0.07, 0, 1) inst.AnimState:SetSymbolAddColour("wall_half_left", 0.01, 0.07, 0, 1) inst.AnimState:SetSymbolLightOverride("wall_half_right", 1) end),
  MakeWall("ms_mountain_wall_high", function(inst) inst.AnimState:PlayAnimation("idle_high_mountain") inst.AnimState:SetSymbolAddColour("wall", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_corner_wall_right_high", function(inst) inst.AnimState:PlayAnimation("idle_right_corner_high_mountain") inst.AnimState:SetSymbolAddColour("wall_half_right", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_corner_wall_left_high", function(inst) inst.AnimState:PlayAnimation("idle_left_corner_high_mountain") inst.AnimState:SetSymbolAddColour("wall_half_left", 0, 0, 1, 1) end),
  MakeWall("ms_mountain_slope_high", function(inst) inst.AnimState:PlayAnimation("idle_left_slope_high_mountain") inst.AnimState:SetSymbolAddColour("wall_half_right", 0.01, 0.07, 0, 1) inst.AnimState:SetSymbolAddColour("wall_half_left", 0.01, 0.07, 0, 1) inst.AnimState:SetSymbolLightOverride("wall_half_right", 1) end)
