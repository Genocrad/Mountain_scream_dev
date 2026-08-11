local assets =
{
  Asset("ANIM", "anim/ms_anvil.zip"),
}
    
    
--
local function AbleToAcceptDecor(inst, item, giver)
  return (item ~= nil) and item:HasTag("ms_ingot") and item.components.temperature and item.components.temperature:GetCurrent() >= TUNING.MS_SMELT_TEMP[item.prefab] * 2/3 
end

local function OnDecorGiven(inst, item, giver)
    if not item then return end

    inst.SoundEmitter:PlaySound("wintersfeast2019/winters_feast/table/food")

    if item.Physics then item.Physics:SetActive(false) end
    if item.Follower then item.Follower:FollowSymbol(inst.GUID, "swap_object") end
    
    inst.ingot = item
    if inst.left_helper then
      inst.left_helper.ingot = item
      inst.right_helper.ingot = item
      inst.down_helper.ingot = item
    end
end

local function OnDecorTaken(inst, item)
    -- Item might be nil if it's taken in a way that destroys it.
    if item then
        if item.Physics then item.Physics:SetActive(true) end
        if item.Follower then item.Follower:StopFollowing() end
    end
end


local function fn_helper()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  inst.persists = false
  
  inst:AddTag("decortable")

  --inst.Transform:SetScale(2,2,2)

  inst.AnimState:SetBank("ms_anvil")
  inst.AnimState:SetBuild("ms_anvil")
  inst.AnimState:PlayAnimation("idle")
  inst.AnimState:SetFinalOffset(-1)
  inst.AnimState:SetRayTestOnBB(false)
  
  
  inst:AddTag("stone")
  inst:AddTag("wall")
  
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")


  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(20000000)
  
  if inst.master and inst.master.ingot then
    inst.ingot = inst.master.ingot
  end

  
  return inst
end


--inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")


local function onhitleft(inst, attacker)
  inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
  if inst.ingot then
    if inst.master then 
      if not inst.master.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.master.AnimState:PlayAnimation("center_hit")
        inst.master.AnimState:PushAnimation("center_idle", false)
      end
    else
      if not inst.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.AnimState:PlayAnimation("center_hit")
        inst.AnimState:PushAnimation("center_idle", false)
      end
    end

      inst.ingot:PushEvent("onforged", "_left")
    end
  end

  
local function onhitright(inst, attacker)
  inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
  if inst.ingot then
    if inst.master then 
      if not inst.master.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.master.AnimState:PlayAnimation("center_hit")
        inst.master.AnimState:PushAnimation("center_idle", false)
      end
    else
      if not inst.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.AnimState:PlayAnimation("center_hit")
        inst.AnimState:PushAnimation("center_idle", false)
      end
    end

      inst.ingot:PushEvent("onforged", "_right")
    end
  end

  
local function onhit(inst, attacker)
  inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
  if inst.ingot then
    if inst.master then 
      if not inst.master.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.master.AnimState:PlayAnimation("center_hit")
        inst.master.AnimState:PushAnimation("center_idle", false)
      end
    else
      if not inst.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.AnimState:PlayAnimation("center_hit")
        inst.AnimState:PushAnimation("center_idle", false)
      end
    end
     
      inst.ingot:PushEvent("onforged", "_forward")
    end
  end
  
-- For ingot creation
local function onhitdown(inst, attacker)
  inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
  if inst.ingot then
    if inst.master then 
      if not inst.master.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.master.AnimState:PlayAnimation("center_hit")
        inst.master.AnimState:PushAnimation("center_idle", false)
      end
    else
      if not inst.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.AnimState:PlayAnimation("center_hit")
        inst.AnimState:PushAnimation("center_idle", false)
      end
    end
      inst.ingot:PushEvent("onforged", "_down")
    end
  end
  
local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  
  inst:AddTag("decortable")

  inst.AnimState:SetBank("ms_anvil")
  inst.AnimState:SetBuild("ms_anvil")
  inst.AnimState:PlayAnimation("center_idle")
  inst.AnimState:HideSymbol("swap_object")
  inst.AnimState:SetFinalOffset(-2)

  
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")


  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(2000000)
  inst.components.workable:SetOnWorkCallback(onhit)

  inst:AddComponent("furnituredecortaker")
  inst.components.furnituredecortaker.abletoaccepttest = AbleToAcceptDecor
  inst.components.furnituredecortaker.ondecorgiven = OnDecorGiven
  inst.components.furnituredecortaker.ondecortaken = OnDecorTaken
  
  inst:DoTaskInTime(0, function(inst)
    local mx, my, mz = inst.Transform:GetWorldPosition()
    inst.right_helper = SpawnPrefab("ms_anvil_helper")
    inst.right_helper.Transform:SetPosition(mx, 0, mz)
    inst.right_helper.AnimState:PlayAnimation("right_idle")
    inst.right_helper.AnimState:SetFinalOffset(-3)
    inst.right_helper.master = inst
    inst.right_helper.components.workable:SetOnWorkCallback(onhitright)

    inst.left_helper = SpawnPrefab("ms_anvil_helper")
    inst.left_helper.Transform:SetPosition(mx, 0, mz)
    inst.left_helper.AnimState:PlayAnimation("left_idle")
    
    inst.left_helper.master = inst
    inst.left_helper.components.workable:SetOnWorkCallback(onhitleft)
        
    inst.down_helper = SpawnPrefab("ms_anvil_helper")
    inst.down_helper.Transform:SetPosition(mx, 0, mz)
    inst.down_helper.AnimState:PlayAnimation("down_idle")
    inst.down_helper.master = inst
    inst.down_helper.AnimState:SetFinalOffset(-3)
    inst.down_helper.components.workable:SetOnWorkCallback(onhitdown)
  end)
  
  return inst
end


return Prefab("ms_anvil", fn, assets, nil), Prefab("ms_anvil_helper", fn_helper, assets, nil)
  
