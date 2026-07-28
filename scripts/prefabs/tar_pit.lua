local assets = {
  Asset("ANIM", "anim/tar_pit.zip")
}

local function launchproj(inst)
  local projectile = SpawnPrefab("tar_projectile")
  local targetpos = inst:GetPosition()
  projectile.Transform:SetPosition(targetpos.x, targetpos.y+2, targetpos.z)

  projectile.components.complexprojectile.velocity = Vector3(0,40,0)
  projectile.components.complexprojectile:SetGravity(-50)
  projectile.components.complexprojectile:SetHorizontalSpeed(20)
  targetpos.z = targetpos.z + math.random() *10 - 5
  targetpos.x = targetpos.x + math.random() *10 - 5
  projectile.components.complexprojectile:Launch(targetpos, inst, inst)
  
end
  
  local function fn_bubble_fx()
    
      local inst = CreateEntity()
      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddNetwork()
      
      
      inst.AnimState:SetBuild("crab_king_bubble_fx")
      inst.AnimState:SetBank("Bubble_fx")
      inst.AnimState:SetMultColour(0.05,0.1,0.3, 1)
      inst.AnimState:SetAddColour(0.1,0.1,0.2, 1)
      inst.AnimState:SetDeltaTimeMultiplier(0.55)
      inst.AnimState:PlayAnimation("bubbles_" .. math.random(1,3))
      
      if not TheWorld.ismastersim then
        return inst
      end
      
      inst:ListenForEvent("animover", function(inst)
        if math.random() <0.5 then
          inst:Hide()
        else
          inst:Show()
        end
        inst.AnimState:PlayAnimation("bubbles_" .. math.random(1,3))
        if math.random() <0.05 then
          launchproj(inst)
        end
      end)
      return inst
  end
  local function fn_fx()
      local inst = CreateEntity()
      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddFollower()
      
      inst:AddTag("FX")
      inst.AnimState:SetBuild("tar_pit")
      inst.AnimState:SetBank("tar_pit")
        
      inst.AnimState:PlayAnimation("idle")
      inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
      inst.AnimState:SetLayer(LAYER_BACKGROUND)
      inst.AnimState:SetSortOrder(3)

      return inst
  end
  
  local function fn()
      local inst = CreateEntity()

      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddNetwork()
      
      inst.Transform:SetScale(1.5,1.5,1.5)
      
      inst.AnimState:SetBuild("tar_pit")
      inst.AnimState:SetBank("tar_pit")
        
      inst.AnimState:PlayAnimation("oil_deco")
      inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
      inst.AnimState:SetLayer(LAYER_BACKGROUND)
      inst.AnimState:SetSortOrder(4)
    
      local x,y,z = inst.Transform:GetWorldPosition()
      inst:DoTaskInTime(0, function(inst)
      if TheWorld.ismastersim then
        inst.bubbles = SpawnPrefab("tar_pit_bubbles")
        inst.bubbles.Transform:SetPosition(inst.Transform:GetWorldPosition())
      end
      end)
      return inst
  end
  return Prefab("tar_pit", fn, assets),
  Prefab("tar_pit_sand", fn_fx, assets),
  Prefab("tar_pit_bubbles", fn_bubble_fx, assets)