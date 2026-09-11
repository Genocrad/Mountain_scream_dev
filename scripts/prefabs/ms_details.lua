local BronzeRepair = require("ms_bronze_repair")

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

local function RefreshImage(inst)
  local cur_temp = inst.components.temperature:GetCurrent()
  local temp = ""

  if cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] / 2 then
    temp = "_hot"
  end

  local imagename = "ms_" .. inst.ingot_group .. "_detail" .. temp
    
  if inst.components.inventoryitem.imagename ~= imagename then
		inst.components.inventoryitem:ChangeImageName(imagename)

    inst.AnimState:PlayAnimation( "ms_" .. inst.ingot_group .. "_detail" .. temp ) 
	end
end

local function TemperatureChange(inst, data)
  local cur_temp = inst.components.temperature:GetCurrent()
  local imagename =  inst.components.inventoryitem.imagename or "ms_" .. inst.ingot_group .. "_detail"

  local temp = string.match(imagename, "melt") and "melt" or (string.match(imagename, "hot") and "hot" or (string.match(imagename, "warm") and "warm" or nil))
    if temp == "hot" and cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] / 2 then
      inst:RefreshImage()
      inst.Light:SetRadius(0)
    end
    if temp == nil and cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] / 2 then
      inst:RefreshImage()
      inst.Light:SetRadius(1.5)
    end
  end





local function OnUpdateLight(inst, radius, intensity, falloff)
	if radius > 0 then
		inst.AnimState:SetLightOverride(0.3)
		inst.Light:SetRadius(radius)
		inst.Light:SetIntensity(intensity)
		inst.Light:SetFalloff(falloff)
		inst.Light:Enable(true)
	else
		inst.AnimState:SetLightOverride(0)
		inst.Light:Enable(false)
	end
end




local function clientimagechange(inst)
  inst.replica.inventoryitem:SetAtlas("images/inventoryimages/inventoryimages_ingots.xml")
end

local function getstatus(inst)
  local imagename = (inst.components.inventoryitem ~= nil and inst.components.inventoryitem.imagename) or inst.prefab
  if string.find(imagename, "hot", 1, true) or string.find(imagename, "melt", 1, true) then
    return "HOT"
  end
  return "GENERIC"
end

--
local function MakeDetail(name)
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
      inst.AnimState:PlayAnimation("ms_".. name .. "_detail")

      
      inst:AddTag("ms_ignorenormalinsulation")
    
    
    
      inst.Light:SetFalloff(0.9)
      inst.Light:SetIntensity(.5)
      inst.Light:SetRadius(0)
      inst.Light:SetColour(169/255, 231/255, 245/255)
      inst.Light:Enable(false)

      inst.ingot_group = name
      
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

      if name == "bronze" then
        BronzeRepair.MakeBronzeRepairKit(inst)
      end

      inst:ListenForEvent("temperaturedelta", TemperatureChange)
      --


      inst.RefreshImage = RefreshImage 

      return inst
  end
  return Prefab("ms_" .. name .. "_detail", fn, assets)
end

return MakeDetail("alu"), MakeDetail("copper"), MakeDetail("bronze"), MakeDetail("gold")