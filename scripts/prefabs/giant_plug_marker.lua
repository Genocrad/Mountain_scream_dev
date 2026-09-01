local assets =
{
    Asset("MINIMAP_IMAGE", "moonstormmarker0"),
}

local prefabs =
{
    "globalmapicon",
}


local function UpdatePosition(inst)
	local x, y, z = inst._target.Transform:GetWorldPosition()
    if inst._x ~= x or inst._z ~= z then
        inst._x = x
        inst._z = z
        inst.Transform:SetPosition(x, 0, z)
    end
end

local function TrackEntity(inst, target, restriction, icon, noupdate)
    -- TODO(JBK): This function is not able to be ran twice without causing issues.
    inst._target = target
    if restriction ~= nil then
        inst.MiniMapEntity:SetRestriction(restriction)
    end
    if icon ~= nil then
        inst.MiniMapEntity:SetIcon(icon)
    elseif target.MiniMapEntity ~= nil then
        inst.MiniMapEntity:CopyIcon(target.MiniMapEntity)
    else
        inst.MiniMapEntity:SetIcon(target.prefab..".png")
    end
    inst:ListenForEvent("onremove", function() inst:Remove() end, target)

	
    UpdatePosition(inst, target)
end

local function common_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddMiniMapEntity()

    inst:AddTag("globalmapicon")
    inst:AddTag("CLASSIFIED")

    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetIsProxy(true)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)

    inst.entity:SetCanSleep(false)
    inst.TrackEntity = TrackEntity
    inst.persists = false
    return inst
end

local function UpdateTemp(inst)
  local x,y,z = inst.Transform:GetWorldPosition()
  if TheWorld.net.components.dungeonmapoverwatch then
    local level = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z)
      if level then
        inst.components.temperatureoverrider:SetTemperature(math.clamp(TheWorld.state.temperature - TUNING.MS_LEVEL_TO_TEMP[level].delta, TUNING.MS_LEVEL_TO_TEMP[level].min, TUNING.MS_LEVEL_TO_TEMP[level].max))
      end
  end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.entity:SetCanSleep(false)

    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()
    
    inst:DoTaskInTime(0, function(inst)
    inst.icon = SpawnPrefab("giant_plug_marker_local")
    inst.icon:TrackEntity(inst)
    inst.icon.MiniMapEntity:SetIcon("ms_giant_plug.tex")
    end)
    inst:ListenForEvent("hideallplugs", function()
      inst.icon.MiniMapEntity:SetIcon("invisible_plug.tex")
		end, TheWorld)  
    inst:ListenForEvent("showallplugs", function()
      inst.icon.MiniMapEntity:SetIcon("ms_giant_plug.tex")
		end, TheWorld)  
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("temperatureoverrider")
    inst.components.temperatureoverrider:SetRadius(60)
    inst.components.temperatureoverrider:SetTemperature(0)
    inst.components.temperatureoverrider:Enable()
    
    inst:DoTaskInTime(0, UpdateTemp)
    inst:WatchWorldState("OnPhase", UpdateTemp)
    return inst
end

return Prefab("giant_plug_marker", fn, assets, prefabs),
Prefab("giant_plug_marker_local", common_fn, assets, prefabs)