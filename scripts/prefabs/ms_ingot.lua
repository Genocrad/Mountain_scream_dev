local assets =
{
    Asset("ANIM", "anim/ms_ingot.zip"),
    Asset("INV_IMAGE", "ms_copper_ingot"),
    Asset("INV_IMAGE", "ms_copper_ingot_warm"),
    Asset("INV_IMAGE", "ms_copper_ingot_hot"),
    Asset("INV_IMAGE", "ms_copper_ingot_melt"),
    Asset("INV_IMAGE", "ms_copper_ingot_left"),
    Asset("INV_IMAGE", "ms_copper_ingot_left_warm"),
    Asset("INV_IMAGE", "ms_copper_ingot_left_hot"),
    Asset("INV_IMAGE", "ms_copper_ingot_left_melt"),
    Asset("INV_IMAGE", "ms_copper_ingot_forward"),
    Asset("INV_IMAGE", "ms_copper_ingot_forward_warm"),
    Asset("INV_IMAGE", "ms_copper_ingot_forward_hot"),
    Asset("INV_IMAGE", "ms_copper_ingot_forward_melt"),
    Asset("INV_IMAGE", "ms_copper_ingot_right"),
    Asset("INV_IMAGE", "ms_copper_ingot_right_warm"),
    Asset("INV_IMAGE", "ms_copper_ingot_right_hot"),
    Asset("INV_IMAGE", "ms_copper_ingot_right_melt"),
    Asset("ATLAS", "images/inventoryimages/inventoryimages_ingots.xml"),
   
    
}

local function RefreshImage(inst, form)
  local cur_temp = inst.components.temperature:GetCurrent()
  local temp = ""
  if form == nil then 
    form = "" 
    -- only basic ingot has warm animations. 
    inst.Light:Enable(false)
    if cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] * 2/3 then
      temp = "_hot"
      inst.Light:Enable(true)
      inst.Light:SetRadius(0.2)
    end
    if cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] * 1/3 and  cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] * 2/3 then
      temp = "_warm"
      inst.Light:Enable(true)
      inst.Light:SetRadius(0.1)
    end
  else
    -- let ingot destruction be handled by temperature delta instead.
    temp = "_hot"
  end
  local imagename = "ms_" .. inst.ingot_group .. "_ingot" .. form .. temp
    
  if inst.components.inventoryitem.imagename ~= imagename then
		inst.components.inventoryitem:ChangeImageName(imagename)

    inst.AnimState:PlayAnimation( "ms_" .. inst.ingot_group .. "_ingot" .. form .. temp ) 
	end
end

local function destroy_and_spawn(inst)
  local mx, my, mz = inst.Transform:GetWorldPosition()
  local slag = SpawnPrefab("ms_slag")
  slag.Transform:SetPosition(mx, my, mz)
  slag.recipe_table = inst.recipe_table
  inst:Remove()
end

local function TemperatureChange(inst, data)
  local cur_temp = inst.components.temperature:GetCurrent()
  local imagename =  inst.components.inventoryitem.imagename or "ms_" .. inst.ingot_group .. "_ingot"

  local form = string.match(imagename, "forward") and "_forward" or (string.match(imagename, "left") and "_left" or (string.match(imagename, "right") and "_right" or nil))
  local temp = string.match(imagename, "melt") and "melt" or (string.match(imagename, "hot") and "hot" or (string.match(imagename, "warm") and "warm" or nil))
  if form == nil then
    if temp == "hot" and cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] / 3 * 2 then
      inst:RefreshImage(form)
    end
    if temp == "warm" and (cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] * 1/3 or cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] * 2/3) then
      inst:RefreshImage(form)
    end
    if temp == nil and cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] * 1/3 then
      inst:RefreshImage(form)
    end
  else
    if cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] / 2 then
      destroy_and_spawn(inst)
    end
  end
end

local function OnForged(inst, direction)
  if direction == "_down" then
    return
  else 
    local imagename =  inst.components.inventoryitem.imagename or inst.prefab
    local form
    if imagename then
      form = string.match(imagename, "forward") and "_forward" or (string.match(imagename, "left") and "_left" or (string.match(imagename, "right") and "_right" or nil))
    end
    -- If form is nil, then its probably just default state. 
    if not form or (form and direction == form) then
      if inst.hits > 10 then
        local mx, my, mz = inst.Transform:GetWorldPosition()
        local detail = SpawnPrefab("ms_" .. inst.ingot_group .. "_detail")
        detail.Transform:SetPosition(mx, my, mz)
        detail.components.temperature:SetTemperature(inst.components.temperature:GetCurrent())
        inst:Remove()
      else
        local transform_into = math.random() < 0.33 and "_forward" or (math.random() > 0.5 and "_left" or "_right")
        inst:RefreshImage(transform_into)
        inst.hits = inst.hits + 1
      end
    else 
      destroy_and_spawn(inst)
    end
  end
end

local function clientimagechange(inst)
  inst.replica.inventoryitem:SetAtlas("images/inventoryimages/inventoryimages_ingots.xml")
end

local function getstatus(inst)
  local imagename = (inst.components.inventoryitem ~= nil and inst.components.inventoryitem.imagename) or inst.prefab
  if string.find(imagename, "melt", 1, true) then
    return "MELT"
  elseif string.find(imagename, "hot", 1, true) then
    return "HOT"
  elseif string.find(imagename, "warm", 1, true) then
    return "WARM"
  end
  return "GENERIC"
end

-- SAVE/LOAD

local function OnSave(inst)
 local data = {}
  if inst.hits_down then
    data.hits = inst.hits
  end
  return data
end

local function OnLoad(inst, data)
	--backward compatible savedata
	if data and data.hits then
		inst.hits:set(data.hits)
	end
end

--
local function MakeIngot(name, recipe)
  local function fn()
      local inst = CreateEntity()

      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddFollower()
      inst.entity:AddSoundEmitter()
      inst.entity:AddLight()
      inst.entity:AddNetwork()

      MakeInventoryPhysics(inst)

      inst.AnimState:SetBank("ms_ingot")
      inst.AnimState:SetBuild("ms_ingot")
      inst.AnimState:PlayAnimation("ms_" .. name .. "_ingot")
      inst.AnimState:SetFinalOffset(10)
      inst.AnimState:SetManualBB(0,-20, 200, 100)
      
      inst:AddTag("furnituredecor")

      inst:AddTag("ms_ingot")

      inst:AddTag("ms_ignorenormalinsulation")
    
    
    
      inst.Light:SetFalloff(0.9)
      inst.Light:SetIntensity(.5)
      inst.Light:SetRadius(0)
      inst.Light:SetColour(209/255, 180/255, 30/255)
      inst.Light:Enable(false)

      
      
      MakeInventoryFloatable(inst, "small", 0.2)
      
      inst:ListenForEvent("imagechange", clientimagechange)
      
      inst.entity:SetPristine()
      if not TheWorld.ismastersim then
          return inst
      end

      --
      local furnituredecor = inst:AddComponent("furnituredecor")
      -- Fix for "trying to put stack of ingots on the furnace causes one ingot to disappear without trace
      furnituredecor.onputonfurniture = function(inst) 
        if inst:IsInLimbo() then
          inst:ReturnToScene() 
        end
        inst:RemoveComponent("stackable") 
      end
      furnituredecor.ontakeofffurniture = function(inst)  local stackable = inst:AddComponent("stackable") stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM end
      --
      local inspectable = inst:AddComponent("inspectable")
      inspectable.getstatus = getstatus

      --
      local inventoryitem = inst:AddComponent("inventoryitem")
      
      local stackable = inst:AddComponent("stackable")
      stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM
      
      -- Luigi: No heater component, players would overheat just from being close to them.
      
      inst:AddComponent("temperature")
      inst.components.temperature.current = TheWorld.state.temperature
      inst.components.temperature.maxtemp = 3000
      inst.components.temperature.overheattemp = 4000

      --
      MakeHauntable(inst)


      inst:ListenForEvent("temperaturedelta", TemperatureChange)
      inst:ListenForEvent("onforged", OnForged)
      --
      inst.OnLoad = OnLoad
      inst.OnSave = OnSave

      inst.RefreshImage = RefreshImage 

      inst.hits_down = 0
      inst.hits = 0 
      
      inst.ingot_group = name
      inst.recipe_table = recipe
      return inst
  end
  return Prefab("ms_" .. name .. "_ingot", fn, assets)
end

return MakeIngot("alu", {"ms_alu_ore", "ms_alu_ore", "ms_alu_ore"}), MakeIngot("copper", {"ms_copper_ore", "ms_copper_ore", "ms_copper_ore"}), MakeIngot("bronze", {"ms_alu_ore", "ms_copper_ore", "ms_alu_ore"}), MakeIngot("gold", {"goldnugget", "goldnugget", "goldnugget"})