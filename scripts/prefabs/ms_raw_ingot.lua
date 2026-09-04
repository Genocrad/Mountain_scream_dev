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
  
  if form == nil then form = "_formless" end
  local cur_temp = inst.components.temperature:GetCurrent()

  local imagename = "ms_" .. inst.ingot_group .. "_ingot" .. form .. "_hot"
	if inst.components.inventoryitem.imagename ~= imagename then
		inst.components.inventoryitem:ChangeImageName(imagename)
    inst.AnimState:PlayAnimation( "ms_" .. inst.ingot_group .. "_ingot" .. form .. "_hot" ) 
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
  if cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab]/2 then
     destroy_and_spawn(inst)
  end
end

local function OnForged(inst, direction)
  if direction == "_down" then
    if inst.hits_down > 2 then
      if math.random() > 0.5 then
        local mx, my, mz = inst.Transform:GetWorldPosition()
        local ingot = SpawnPrefab("ms_" .. inst.ingot_group .. "_ingot")
        ingot.Transform:SetPosition(mx, my, mz)
        ingot.components.temperature:SetTemperature(inst.components.temperature:GetCurrent())
        inst:Remove()
      end
    end
    inst.hits_down = inst.hits_down + 1
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

-- SAVE/LOAD

local function OnSave(inst)
 local data = {}
  if inst.hits then
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
local function MakeRaw(name, recipe)
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
      inst.AnimState:PlayAnimation("ms_" .. name .. "_ingot_formless_hot")
      inst.AnimState:SetFinalOffset(2)
      inst.AnimState:SetManualBB(0,-20, 200, 100)
    --furnituredecor (from furnituredecor component) added to pristine state for optimization
      inst:AddTag("furnituredecor")

    --vase (from vase component) added to pristine state for optimization
      inst:AddTag("ms_ingot")

      inst:AddTag("ms_ignorenormalinsulation")
      inst:AddTag("inventoryitemtemperature")
      inst.Light:SetFalloff(0.9)
      inst.Light:SetIntensity(.5)
      inst.Light:SetRadius(0.2)
      inst.Light:SetColour(209/255, 180/255, 30/255)
      inst.Light:Enable(true)

      MakeInventoryFloatable(inst, "small", 0.2)
      
      
      inst:ListenForEvent("imagechange", clientimagechange)
      
      inst.entity:SetPristine()
      if not TheWorld.ismastersim then
          return inst
      end

      --
      local furnituredecor = inst:AddComponent("furnituredecor")

      --
      local inspectable = inst:AddComponent("inspectable")

      --
      local inventoryitem = inst:AddComponent("inventoryitem")

      
      
      
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
  return Prefab("ms_" .. name .. "_ingot_formless", fn, assets)
end

return MakeRaw("alu", {"ms_alu_ore", "ms_alu_ore", "ms_alu_ore"}), MakeRaw("copper", {"ms_copper_ore", "ms_copper_ore", "ms_copper_ore"}), MakeRaw("bronze", {"ms_alu_ore", "ms_copper_ore", "ms_alu_ore"}), MakeRaw("gold", {"goldnugget", "goldnugget", "goldnugget"})