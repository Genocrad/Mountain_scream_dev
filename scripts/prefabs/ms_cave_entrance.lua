local assets = {
    Asset("ANIM", "anim/ms_cave_entrance.zip"),
}



local function OnActivate(inst, doer)
    if doer:HasTag("player") then
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
    end
end

local function SetExitTarget(inst, targetinst)
    local oldtarget = inst.components.teleporter:GetTarget()
    if oldtarget then
        inst:RemoveEventCallback("onremove", inst._exittarget_onremove, targetinst)
    end

    inst.components.teleporter:Target(targetinst)
    if not targetinst then
        inst.components.teleporter:SetEnabled(false)
        return
    end
    inst.components.teleporter:SetEnabled(true)
    inst:ListenForEvent("onremove", inst._exittarget_onremove, targetinst)
end

local function OnSave(inst, data)
	if inst.components.teleporter.targetTeleporter then
		data.target_x, data.target_y, data.target_z =  inst.components.teleporter.targetTeleporter.Transform:GetWorldPosition()
    data.teleport_offset =  inst.components.teleporter.teleport_offset
    data.saved_angle = inst.Transform:GetRotation()  -- WDYM onload is called before any components?
	end
end

local function OnLoad(inst, data)
	if data ~= nil and data.target_x then
    local exit = SpawnPrefab("ms_cave_exit")
    exit.Transform:SetPosition(data.target_x, data.target_y, data.target_z)
    local angle = data.saved_angle
    exit.Transform:SetRotation(angle + 180 < 360 and angle + 180 or angle-180)
    exit:SetExitTarget(inst)
    inst:SetExitTarget(exit)
	end
  if data ~= nil and data.teleport_offset then
    inst.components.teleporter.teleport_offset = data.teleport_offset
  end
end

local function OnLoadVert(inst, data)
	if data ~= nil and data.target_x then
    local exit = SpawnPrefab("ms_cave_exit_light")
    exit.Transform:SetPosition(data.target_x, data.target_y, data.target_z)
    exit:SetExitTarget(inst)
    inst:SetExitTarget(exit)
	end
  if data ~= nil and data.teleport_offset then
    inst.components.teleporter.teleport_offset = data.teleport_offset
  end
end

local function MakeTeleporter(name, common_postinitfn, master_postinitfn)
local function fn()
  local inst = CreateEntity()
 
 
 
  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddSoundEmitter()
  inst.entity:AddMiniMapEntity()
  inst.entity:AddNetwork()

  inst:AddTag("groundhole")
  inst:AddTag("blocker")
  inst:AddTag("ms_teleporter")


  inst.AnimState:SetBank("ms_cave_entrance")
  inst.AnimState:SetBuild("ms_cave_entrance")
  inst.AnimState:PlayAnimation("idle")  
  
  --NOTE: Shadows are on WORLD_BACKGROUND sort order 1
  --      Hole goes above to hide shadows
  --      Surface goes below to reveal shadows

  inst.MiniMapEntity:SetIcon("ms_cave_door.tex")

  inst.Transform:SetEightFaced()
  MakeObstaclePhysics(inst, 1)
  
  inst:SetDeploySmartRadius(3)
  if common_postinitfn ~= nil then
    common_postinitfn(inst)
  end
  
  inst.entity:SetPristine()

  if not TheWorld.ismastersim then
    return inst
  end

  inst:AddComponent("inspectable")

  local teleporter = inst:AddComponent("teleporter")
  teleporter.onActivate = OnActivate
  teleporter.overrideteleportarrivestate = "idle"
  teleporter.offset = 3
  teleporter.saveenabled = true
  --teleporter:SetSelfManaged(lobbyexit)
  teleporter:SetEnabled(false)
 
  inst.SetExitTarget = SetExitTarget
  

  inst._exittarget_onremove = function()
    inst:SetExitTarget(nil)
  end
  if master_postinitfn ~= nil then
    master_postinitfn(inst)
  end
  return inst
end
return Prefab(name, fn, assets)
end

return MakeTeleporter("ms_cave_entrance", nil, function(inst) inst:AddComponent("savedrotation")  inst.OnSave = OnSave inst.OnLoad = OnLoad end),
MakeTeleporter("ms_cave_exit_light", function(inst) 
    inst.entity:AddLight()     
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(0.3)
    inst.Light:SetIntensity(0.85)
    inst.Light:EnableClientModulation(true)
    inst.Light:SetColour(180/255, 195/255, 150/255)
    inst.persists = false
    inst.Transform:SetRotation(270)
  end, function(inst) inst.components.teleporter.offset = 0 inst.components.teleporter.teleport_offset = {x = 0, y = 0, z=2} end),
MakeTeleporter("ms_cave_entrance_vertical", function(inst)   
       MakeObstaclePhysics(inst, 4)
      inst.AnimState:PlayAnimation("idledown")  
      inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
      inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/clickable_vertical_shader.ksh"))	
      inst.AnimState:SetDepthTestEnabled(true)
      inst.AnimState:SetDepthWriteEnabled(true)
    end, 
    function(inst) 
      inst:AddComponent("savedrotation") 
      inst.components.teleporter.offset = 10
      inst.OnSave = OnSave
      inst.OnLoad = OnLoadVert 
    end),
MakeTeleporter("ms_cave_exit", function(inst) inst.persists = false end, nil)