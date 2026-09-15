require "prefabutil"

local cooking = require("cooking")

local assets =
{
    Asset("ANIM", "anim/ms_furnace.zip"),
    Asset("ANIM", "anim/ui_cookpot_1x4.zip"),
}

local prefabs =
{
    "collapse_small",
}


local function TossDecorItem(inst)
    local item = inst.components.furnituredecortaker:TakeItem()
    if item then
        inst.components.lootdropper:FlingItem(item)
    end
end

local function onhammered(inst, worker)
    if inst.components.container ~= nil then
      inst.components.container:DropEverything()
    end
    if inst.components.furnituredecortaker ~= nil then
      TossDecorItem(inst)
    end
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
    inst.fire.bellow:Remove()
    inst.fire:Remove()
    inst:Remove()
end

local function onhit(inst, worker)
  if inst.components.stewer.product ~= nil then
    inst.AnimState:PlayAnimation("hit_door_closed")
    if inst.back then
      inst.back.AnimState:PlayAnimation("hit_back")
    end
    if inst.components.stewer:IsCooking() then
      inst.AnimState:PushAnimation("cooking_loop", true)
    else
      inst.AnimState:PushAnimation("cooking_loop_cold", true)
    end
  else
    if inst.components.container ~= nil and inst.components.container:IsOpen() then
      inst.components.container:Close()
      --onclose will trigger sfx already
    else
      inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
    end
    inst.AnimState:PlayAnimation("hit_door_open")
    inst.AnimState:PushAnimation("idle_open", false)
  end
end

--anim and sound callbacks

local function startcookfn(inst)
  inst.AnimState:PlayAnimation("cooking_loop", true)
  inst.SoundEmitter:KillSound("snd")
  inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")
  inst.Light:Enable(true)
end

-- No onopen or onclose, as we have the lid open to default.

local function ShowProduct(inst)
  inst:AddTag("burnt")
  local product = SpawnPrefab(inst.components.stewer.product)
  if product.components.temperature then
    product.components.temperature:SetTemperature(inst.components.temperature:GetCurrent())
  end
  inst.components.furnituredecortaker:AcceptDecor(product)
  inst.components.stewer.product = nil
  inst.components.stewer:StopCooking()
end

local function donecookfn(inst)
  inst.AnimState:PlayAnimation("cooking_post")
  inst.AnimState:PushAnimation("idle_open", false)
  inst:DoTaskInTime(0.3, function() 
  inst:RemoveTag("donecooking")
  end)
  ShowProduct(inst)
  inst.SoundEmitter:KillSound("snd")
  inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_finish")
  inst.Light:Enable(false)
  
end

local function continuedonefn(inst)
  -- Fix for "reloading causes a ingot to appear out of thin air and then break the furnace."
  local cur_temp = inst.components.temperature:GetCurrent()
  local product = inst.components.stewer.product
    if cur_temp < TUNING.MS_SMELT_TEMP[product] then
      inst.AnimState:PlayAnimation("cooking_loop_cold", true)
      inst.components.stewer:StopSmeltingemperatureLow()
    else
      inst.AnimState:PlayAnimation("cooking_loop", true)
      inst.components.stewer:RestartSmelting()
    end
end

local function continuecookfn(inst)
    inst.AnimState:PlayAnimation("cooking_loop", true)
    inst.Light:Enable(true)
    inst.SoundEmitter:KillSound("snd")
    inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_rattle", "snd")

end

local function harvestfn(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("idle")
        inst.SoundEmitter:PlaySound("dontstarve/common/cookingpot_close")
    end
end


local function descriptionfn(inst)
  return subfmt(STRINGS.MS_FURNACE.HEATED_DESC, {
    temp = string.format("%.1f", inst.components.temperature:GetCurrent()),
  })
end

-- Hierarchy is as such here: furnace (persists) -> campfire(persits) -> firefx and bellow (do not persist)

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle_open", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/cook_pot_craft")
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.fire = SpawnPrefab("ms_furnace_campfire")
    inst.fire.Transform:SetPosition(x,y,z)
    inst.fire.furnace = inst
end


local function TemperatureChange(inst, data)
  local cur_temp = inst.components.temperature:GetCurrent()
  inst.AnimState:SetAddColour(cur_temp/10000,cur_temp/30000,0,1)
  local product = inst.components.stewer.product
  if product then
    --print(cur_temp, TUNING.MS_SMELT_TEMP[product], inst.components.stewer.targettime)
    if cur_temp < TUNING.MS_SMELT_TEMP[product] then
      if inst.components.stewer.task then
        inst.components.stewer:StopSmeltingemperatureLow()
       
      end
       inst.AnimState:PlayAnimation("cooking_loop_cold", true)
    else
      if inst.components.stewer.task == nil then
        inst.components.stewer:RestartSmelting()
        inst.AnimState:PlayAnimation("cooking_loop", true)
      end
    end
  end
end

-- Furnituretaker

local function AbleToAcceptDecor(inst, item, giver)
    return (item ~= nil) and item:HasTag("ms_ingot") and inst.components.stewer.product == nil
end

local function OnDecorGiven(inst, item, giver)
    if not item then return end
    inst.SoundEmitter:PlaySound("wintersfeast2019/winters_feast/table/food")
    inst:AddTag("burnt") -- A hack to disable stewer functional without doing a shit ton of work
    inst.AnimState:SetManualBB(0, 0, 0, 0)   
    item.AnimState:SetFinalOffset(20)
    if item.Physics then item.Physics:SetActive(false) end
    if item.Follower then item.Follower:FollowSymbol(inst.GUID, "swap_food") end
end

local function OnDecorTaken(inst, item)
    -- Item might be nil if it's taken in a way that destroys it.
    if item then
        if item.Physics then item.Physics:SetActive(true) end
        if item.Follower then item.Follower:StopFollowing() end
    end
    inst:RemoveTag("burnt")
    item.AnimState:SetFinalOffset(0)
    inst.AnimState:SetManualBB(0, -300, 600, 500)   
    if inst.components.container ~= nil then
      inst.components.container.canbeopened = true
    end
end

-- Save/load

local function onloadpostpass(inst, newents, data)
    if data and data.additems and inst.components.container then
        for i, itemname in ipairs(data.additems)do
            local ent = SpawnPrefab(itemname)
            inst.components.container:GiveItem( ent )
        end
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 1, {"ms_furnace_campfire"})
    inst.fire = ents[1]
    inst.fire.furnace = inst
end

--
local function backfn()
  local inst = CreateEntity()
  
  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  
  inst.AnimState:SetBank("ms_furnace")
  inst.AnimState:SetBuild("ms_furnace")
  inst.AnimState:PlayAnimation("place_back")
  inst.AnimState:PushAnimation("cooking_loop_back")
  inst.AnimState:SetFinalOffset(-2)
  return inst
end

local function OnInit(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  local back = SpawnPrefab("ms_furnace_back")
  back.Transform:SetPosition(x,y,z)
  inst.back = back
end

local function fn()
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()
  inst.entity:AddLight()
  inst.entity:AddNetwork()

  inst:SetDeploySmartRadius(1) --recipe min_spacing/2
  MakeObstaclePhysics(inst, .7)

  inst.Light:Enable(false)
  inst.Light:SetRadius(.6)
  inst.Light:SetFalloff(1)
  inst.Light:SetIntensity(.5)
  inst.Light:SetColour(235/255,62/255,12/255)
  --inst.Light:SetColour(1,0,0)

  inst:AddTag("structure")

  --stewer (from stewer component) added to pristine state for optimization
  inst:AddTag("stewer")
  inst:AddTag("ms_furnace")
  inst:AddTag("ms_ignorenormalinsulation")
  
  inst.AnimState:SetBank("ms_furnace")
  inst.AnimState:SetBuild("ms_furnace")
  inst.AnimState:PlayAnimation("idle_open")
  inst.AnimState:SetManualBB(0, -300, 600, 500)   
  
  inst.MiniMapEntity:SetIcon("ms_furnace.tex")

  MakeSnowCoveredPristine(inst)
  if not TheNet:IsDedicated() then
    inst.back = SpawnPrefab("ms_furnace_back")
    inst.back.entity:SetParent(inst.entity)
  end
  
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst.scrapbook_speechstatus = "EMPTY"

  inst:AddComponent("stewer")
  inst.components.stewer.onstartcooking = startcookfn
  inst.components.stewer.oncontinuecooking = continuecookfn
  inst.components.stewer.oncontinuedone = continuedonefn
  inst.components.stewer.ondonecooking = donecookfn
  inst.components.stewer.onharvest = harvestfn

  inst:AddComponent("container")
  inst.components.container:WidgetSetup("ms_furnace")
  inst.components.container.skipclosesnd = true
  inst.components.container.skipopensnd = true
  inst.components.container:WidgetSetup("ms_furnace")
  
  inst:AddComponent("inspectable")
  inst.components.inspectable.descriptionfn = descriptionfn
  
  inst:AddComponent("temperature")
  inst.components.temperature.current = TheWorld.state.temperature
  inst.components.temperature.maxtemp = 3000
  inst.components.temperature.overheattemp = 4000

  inst:AddComponent("furnituredecortaker")
  inst.components.furnituredecortaker.abletoaccepttest = AbleToAcceptDecor
  inst.components.furnituredecortaker.ondecorgiven = OnDecorGiven
  inst.components.furnituredecortaker.ondecortaken = OnDecorTaken

  inst:AddComponent("lootdropper")
  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(4)
  inst.components.workable:SetOnFinishCallback(onhammered)
  inst.components.workable:SetOnWorkCallback(onhit)

  inst:AddComponent("hauntable")
  inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
  --inst.components.hauntable:SetOnHauntFn(OnHaunt)
  
  
  MakeSnowCovered(inst)
  SetLunarHailBuildupAmountSmall(inst)

  inst:ListenForEvent("onbuilt", onbuilt)
  inst:ListenForEvent("temperaturedelta", TemperatureChange)

  inst.OnLoadPostPass = onloadpostpass

  return inst
end

return Prefab("ms_furnace", fn, assets, prefabs),
      Prefab("ms_furnace_back", backfn, assets, prefabs),
      MakePlacer("ms_furnace_placer", "ms_furnace", "ms_furnace", "placer")