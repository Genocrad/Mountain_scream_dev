local assets =
{
    Asset("ANIM", "anim/ms_ingot.zip"),
    Asset("ANIM", "anim/swap_flower.zip"),
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

-- I should have really kept those name consistent, huh? 
local formtoanim = {
  _forward = "idle_center",
  _left = "idle_left_c",
  _right = "idle_right_c",
}

local function RefreshImage(inst, form)
  
  if form == nil then form = "" end
  local cur_temp = inst.components.temperature:GetCurrent()
  local temp = ""
  if cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] then
    temp = "_melt"
  end
  if cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] * 2/3 and  cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] then
    temp = "_hot"
  end
  if cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] * 1/3 and  cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] * 2/3 then
    temp = "_warm"
  end
  
  local imagename = tostring(inst.prefab) .. form .. temp
	if inst.components.inventoryitem.imagename ~= imagename then
		inst.components.inventoryitem:ChangeImageName(imagename)
    inst.AnimState:PlayAnimation(formtoanim[form] and formtoanim[form] .. temp or "idle_unchanged" .. temp) 
	end
end

local function TemperatureChange(inst, data)
  local cur_temp = inst.components.temperature:GetCurrent()
  local imagename =  inst.components.inventoryitem.imagename or "ms_copper_ingot"
  if imagename then
  local form = string.match(imagename, "forward") and "_forward" or (string.match(imagename, "left") and "_left" or (string.match(imagename, "right") and "_right" or nil))
  local temp = string.match(imagename, "melt") and "melt" or (string.match(imagename, "hot") and "hot" or (string.match(imagename, "warm") and "warm" or nil))
  if temp == "melt" and cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] then
    inst:RefreshImage(form)
  end
  if temp == "hot" and (cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] or cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] * 2/3) then 
    inst:RefreshImage(form)
  end
  if temp == "warm" and (cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] * 2/3 or cur_temp <= TUNING.MS_SMELT_TEMP[inst.prefab] * 1/3) then 
    inst:RefreshImage(form)
  end
  if temp == nil and cur_temp >= TUNING.MS_SMELT_TEMP[inst.prefab] * 1/3 then
     inst:RefreshImage(form)
  end
  end
end

local function OnForged(inst)
  local state = inst._wasworked:value()
  for k,v in pairs(FORGING[inst.prefab]) do
    if state == v then
      local result = SpawnPrefab("golden" .. k)
      local x, y, z = inst.Transform:GetWorldPosition()
      result.Transform:SetPosition(x, 4, z)
      inst:Remove()
    end
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


local function ingot_getstatus(inst)
	local imagename =  inst.components.inventoryitem.imagename
  return string.match(imagename, "melt") and "MELT" or (string.match(imagename, "hot") and "HOT" or (string.match(imagename, "warm") and "WARM" or nil))
end

local function onwasworkeddirty(inst)
  inst.name = inst._wasworked:value()
end

local function clientimagechange(inst)
  inst.replica.inventoryitem:SetAtlas("images/inventoryimages/inventoryimages_ingots.xml")
end

-- SAVE/LOAD

local function OnSave(inst)
 local data = {}
  if inst._wasworked:value() then
    data.wasworked = inst._wasworked:value()
  end
  return data
end

local function OnLoad(inst, data)
	--backward compatible savedata
	if data and data.wasworked then
		inst._wasworked:set(data.wasworked)
	end
end

--
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
    inst.AnimState:PlayAnimation("idle_unchanged")
    inst.AnimState:SetFinalOffset(2)
    inst.AnimState:SetManualBB(0,-20, 100, 50)
	--furnituredecor (from furnituredecor component) added to pristine state for optimization
    inst:AddTag("furnituredecor")

	--vase (from vase component) added to pristine state for optimization
    inst:AddTag("ms_ingot")

    inst:AddTag("ms_ignorenormalinsulation")
  
  
  
    inst.Light:SetFalloff(0.9)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(1.5)
    inst.Light:SetColour(169/255, 231/255, 245/255)
    inst.Light:Enable(false)

    MakeInventoryFloatable(inst, "small", 0.2)
    
    inst._wasworked = net_string(inst.GUID, "ms_ingot._wasworked", "wasworkeddirty")

    inst:ListenForEvent("wasworkeddirty", onwasworkeddirty)
    inst:ListenForEvent("imagechange", clientimagechange)
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    --
    local furnituredecor = inst:AddComponent("furnituredecor")

    --
    local inspectable = inst:AddComponent("inspectable")
    inspectable.getstatus = ingot_getstatus

    --
    local inventoryitem = inst:AddComponent("inventoryitem")
  
    
    
    
    -- Luigi: No heater component, players would overheat just from being close to them.
    
    inst:AddComponent("temperature")
    inst.components.temperature.current = TheWorld.state.temperature
    inst.components.temperature.inherentinsulation = TUNING.INSULATION_MED
    inst.components.temperature.inherentsummerinsulation = TUNING.INSULATION_MED
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

    return inst
end

return Prefab("ms_copper_ingot", fn, assets)