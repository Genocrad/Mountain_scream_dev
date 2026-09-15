local assets =
{
  Asset("ANIM", "anim/ms_anvil.zip"),
}
    
    
--should not come up, but ill leave it just in case

local function TossDecorItem(inst)
    local item = inst.components.furnituredecortaker:TakeItem()
    if item then
        inst.components.lootdropper:FlingItem(item)
    end
end


local function onhitleft(inst, attacker)
  inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
  if inst.ingot then
    inst.components.workable:SetWorkLeft(10)
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
    inst.components.workable:SetWorkLeft(10)
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
    inst.components.workable:SetWorkLeft(10)
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
    inst.components.workable:SetWorkLeft(10)
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

local function onminedmaster(inst, worker)
    if inst.components.furnituredecortaker ~= nil then
      TossDecorItem(inst)
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst.down_helper:Remove()
    inst.right_helper:Remove()
    inst.left_helper:Remove()
    inst:Remove()
end

local function onmined(inst, worker)
  if inst.master then
    onminedmaster(inst.master, worker)
  end
end

local function onhitmine(inst, attacker)
  inst.SoundEmitter:PlaySound("daywalker/pillar/pickaxe_hit_unbreakable")
end

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
      inst.right_helper.components.workable:SetWorkAction(ACTIONS.HAMMER)
      inst.right_helper.components.workable:SetOnWorkCallback(onhitright)
      inst.right_helper.components.workable:SetWorkLeft(100)
      inst.left_helper.components.workable:SetWorkAction(ACTIONS.HAMMER)
      inst.left_helper.components.workable:SetOnWorkCallback(onhitleft)
      inst.left_helper.components.workable:SetWorkLeft(100)
      inst.down_helper.components.workable:SetWorkAction(ACTIONS.HAMMER)
      inst.down_helper.components.workable:SetOnWorkCallback(onhitdown)
      inst.down_helper.components.workable:SetWorkLeft(100)
      inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
      inst.components.workable:SetOnWorkCallback(onhit)
      inst.components.workable:SetWorkLeft(100)
    end
end

local function OnDecorTaken(inst, item)
    -- Item might be nil if it's taken in a way that destroys it.
    if item then
        if item.Physics then item.Physics:SetActive(true) end
        if item.Follower then item.Follower:StopFollowing() end
    end
    inst.ingot = nil
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(10)
    inst.components.workable:SetOnWorkCallback(onhitmine)
    inst.components.workable:SetOnFinishCallback(onminedmaster)
    if inst.left_helper then
      inst.left_helper.ingot = nil
      inst.right_helper.ingot = nil
      inst.down_helper.ingot = nil
      inst.left_helper.components.workable:SetWorkAction(ACTIONS.MINE)
      inst.left_helper.components.workable:SetWorkLeft(10)
      inst.left_helper.components.workable:SetOnWorkCallback(onhitmine)
      inst.left_helper.components.workable:SetOnFinishCallback(onmined)
      inst.right_helper.components.workable:SetWorkAction(ACTIONS.MINE)
      inst.right_helper.components.workable:SetWorkLeft(10)
      inst.right_helper.components.workable:SetOnWorkCallback(onhitmine)
      inst.right_helper.components.workable:SetOnFinishCallback(onmined)
      inst.down_helper.components.workable:SetWorkAction(ACTIONS.MINE)
      inst.down_helper.components.workable:SetWorkLeft(10)
      inst.down_helper.components.workable:SetOnWorkCallback(onhitmine)
      inst.down_helper.components.workable:SetOnFinishCallback(onmined)
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
  inst:AddTag("ms_anvil")

  --inst.Transform:SetScale(2,2,2)

  inst.AnimState:SetBank("ms_anvil")
  inst.AnimState:SetBuild("ms_anvil")
  inst.AnimState:PlayAnimation("center_idle")
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
  inst.components.workable:SetWorkAction(ACTIONS.MINE)
  inst.components.workable:SetWorkLeft(10)
  inst.components.workable:SetOnFinishCallback(onminedmaster)
  if inst.master and inst.master.ingot then
    inst.ingot = inst.master.ingot
  end

  
  return inst
end


local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddNetwork()
  inst.entity:AddMiniMapEntity()
  
  inst:AddTag("decortable")
  inst:AddTag("ms_anvil")

  inst.AnimState:SetBank("ms_anvil")
  inst.AnimState:SetBuild("ms_anvil")
  inst.AnimState:PlayAnimation("center_idle")
  inst.AnimState:HideSymbol("swap_object")
  inst.AnimState:SetFinalOffset(-2)

  inst.MiniMapEntity:SetIcon("ms_anvil.tex")
  
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")


  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.MINE)
  inst.components.workable:SetWorkLeft(10)
  inst.components.workable:SetOnWorkCallback(onhitmine)
  inst.components.workable:SetOnFinishCallback(onminedmaster)
  
  inst:AddComponent("furnituredecortaker")
  inst.components.furnituredecortaker.abletoaccepttest = AbleToAcceptDecor
  inst.components.furnituredecortaker.ondecorgiven = OnDecorGiven
  inst.components.furnituredecortaker.ondecortaken = OnDecorTaken
  
  inst:AddComponent("lootdropper")
  
  inst:DoTaskInTime(0, function(inst)
    local mx, my, mz = inst.Transform:GetWorldPosition()
    inst.right_helper = SpawnPrefab("ms_anvil_helper")
    inst.right_helper.Transform:SetPosition(mx, 0, mz)
    inst.right_helper.AnimState:PlayAnimation("right_idle")
    inst.right_helper.AnimState:SetFinalOffset(-3)
    inst.right_helper.master = inst
    inst.right_helper.components.workable:SetWorkLeft(10)
    inst.right_helper.components.workable:SetOnWorkCallback(onhitmine)
    inst.right_helper.components.workable:SetOnFinishCallback(onmined)
    
    inst.left_helper = SpawnPrefab("ms_anvil_helper")
    inst.left_helper.Transform:SetPosition(mx, 0, mz)
    inst.left_helper.AnimState:PlayAnimation("left_idle")
    inst.left_helper.master = inst
    inst.left_helper.components.workable:SetWorkLeft(10)
    inst.left_helper.components.workable:SetOnWorkCallback(onhitmine)
    inst.left_helper.components.workable:SetOnFinishCallback(onmined)
        
    inst.down_helper = SpawnPrefab("ms_anvil_helper")
    inst.down_helper.Transform:SetPosition(mx, 0, mz)
    inst.down_helper.AnimState:PlayAnimation("down_idle")
    inst.down_helper.AnimState:SetFinalOffset(-3)
    inst.down_helper.master = inst
    inst.down_helper.components.workable:SetWorkLeft(10)
    inst.down_helper.components.workable:SetOnWorkCallback(onhitmine)
    inst.down_helper.components.workable:SetOnFinishCallback(onmined)
    
    local item = inst.components.furnituredecortaker.decor_item -- As helpers are spawned after load...
    if item then
      OnDecorGiven(inst, item)
    end
  end)
  
  return inst
end


return Prefab("ms_anvil", fn, assets, nil), Prefab("ms_anvil_helper", fn_helper, assets, nil),
MakePlacer("ms_anvil_placer", "ms_anvil", "ms_anvil", "placer")
  
