local assets =
{
  Asset("ANIM", "anim/ms_anvil.zip"),
}
    
    
--
local function AbleToAcceptDecor(inst, item, giver)
  return (item ~= nil) and item:HasTag("ms_ingot")
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
  inst.components.workable:SetWorkLeft(2000)
  
  if inst.master and inst.master.ingot then
    inst.ingot = inst.master.ingot
  end

  
  return inst
end

local function comparehitstotemp(inst, ingot, hits)
  local temp = ingot.components.temperature:GetCurrent()
  local hits_min = TUNING.MS_ANVIL_MINIMAL_HITS * math.ceil(1 / math.min((temp/TUNING.MS_SMELT_TEMP[inst.ingot.prefab]), 1)) 
  if temp < TUNING.MS_SMELT_TEMP[inst.ingot.prefab]/3 then
    return false
  end
  if hits >= hits_min then
    if math.random() < (hits-hits_min)/3 then
      inst.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
      return true
    end
  end
  inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
  return false
end

local function onhitleft(inst, attacker)
  if inst.ingot then
    if inst.master then 
      if not inst.master.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.master.AnimState:PlayAnimation("center_hit")
        inst.master.AnimState:PushAnimation("center_idle", false)
      end
      
      inst.master.hits_left = inst.master.hits_left + 1 
      inst.hits_left = inst.master.hits_left
    else
      if not inst.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.AnimState:PlayAnimation("center_hit")
        inst.AnimState:PushAnimation("center_idle", false)
      end
      inst.hits_left = inst.hits_left + 1
    end
    if comparehitstotemp(inst, inst.ingot, inst.hits_left) then
      
      inst.ingot._wasworked:set(inst.ingot._wasworked:value() .. "l")
      inst.ingot.name = inst.ingot._wasworked:value()
      inst.ingot:RefreshImage("_left")
      inst.ingot:PushEvent("onforged")
      if inst.master then 
        inst.master.AnimState:PlayAnimation("center_hit_sparkle")
        inst.master.AnimState:PushAnimation("center_idle", false)
        inst.master.hits_left = 0 
      else
        inst.AnimState:PlayAnimation("center_hit_sparkle")
        inst.AnimState:PushAnimation("center_idle", false)  
      end
      inst.hits_left = 0
    end
  end
end
  
local function onhitright(inst, attacker)
  if inst.ingot then
    if inst.master then 
      if not inst.master.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.master.AnimState:PlayAnimation("center_hit")
        inst.master.AnimState:PushAnimation("center_idle", false)
      end
      
      inst.master.hits_right = inst.master.hits_right + 1 
      inst.hits_right = inst.master.hits_right
    else
      if not inst.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.AnimState:PlayAnimation("center_hit")
        inst.AnimState:PushAnimation("center_idle", false)
      end
      inst.hits_right = inst.hits_right + 1
    end
    if comparehitstotemp(inst, inst.ingot, inst.hits_right) then
      inst.ingot._wasworked:set(inst.ingot._wasworked:value() .. "r")
      inst.ingot.name = inst.ingot._wasworked:value()
      inst.ingot:RefreshImage("_right")
      inst.ingot:PushEvent("onforged")
      if inst.master then 
        inst.master.AnimState:PlayAnimation("center_hit_sparkle")
        inst.master.AnimState:PushAnimation("center_idle", false)
        inst.master.hits_right = 0 
      else
        inst.AnimState:PlayAnimation("center_hit_sparkle")
        inst.AnimState:PushAnimation("center_idle", false)  
      end
      inst.hits_right = 0
    end
  end
end
  
local function onhit(inst, attacker)
  if inst.ingot then
   if inst.master then 
      if not inst.master.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.master.AnimState:PlayAnimation("center_hit")
        inst.master.AnimState:PushAnimation("center_idle", false)
      end
     
      inst.master.hits_center = inst.master.hits_center + 1 
      inst.hits_center = inst.master.hits_center
    else
      if not inst.AnimState:IsCurrentAnimation("center_hit_sparkle") then
        inst.AnimState:PlayAnimation("center_hit")
        inst.AnimState:PushAnimation("center_idle", false)
      end
      inst.hits_center = inst.hits_center + 1
    end
    
    if comparehitstotemp(inst, inst.ingot, inst.hits_center) then
      inst.ingot._wasworked:set(inst.ingot._wasworked:value() .. "c")
      inst.ingot.name = inst.ingot._wasworked:value()
      inst.ingot:RefreshImage("_forward")
      inst.ingot:PushEvent("onforged")
      if inst.master then 
        inst.master.hits_center = 0 
        inst.master.AnimState:PlayAnimation("center_hit_sparkle")
        inst.master.AnimState:PushAnimation("center_idle", false)
      else
        inst.AnimState:PlayAnimation("center_hit_sparkle")
        inst.AnimState:PushAnimation("center_idle", false)
      end
      inst.hits_center = 0
    end
  end
end
local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()

  
  inst:AddTag("decortable")

  --inst.Transform:SetScale(2,2,2)

  inst.AnimState:SetBank("ms_anvil")
  inst.AnimState:SetBuild("ms_anvil")
  inst.AnimState:PlayAnimation("center_idle")
  inst.AnimState:HideSymbol("swap_object")
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
  inst.components.workable:SetWorkLeft(2000)
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
    inst.right_helper.master = inst
    inst.right_helper.components.workable:SetOnWorkCallback(onhitright)

    inst.left_helper = SpawnPrefab("ms_anvil_helper")
    inst.left_helper.Transform:SetPosition(mx, 0, mz)
    inst.left_helper.AnimState:PlayAnimation("left_idle")
    inst.left_helper.master = inst
    inst.left_helper.components.workable:SetOnWorkCallback(onhitleft)
    
  end)

  -- No, we do not want to save this. Who the fuck will remember 2-4 hits on a anvil?
  inst.hits_left = 0
  inst.hits_right = 0
  inst.hits_center = 0
  
  return inst
end


return Prefab("ms_anvil", fn, assets, nil), Prefab("ms_anvil_helper", fn_helper, assets, nil)
  
