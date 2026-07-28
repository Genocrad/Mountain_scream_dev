local assets = {
    Asset("ANIM", "anim/ms_arenateleporter.zip"),
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
	end
end

local function OnLoad(inst, data)
	if data ~= nil and data.target_x then
    local exit = SpawnPrefab("ms_cave_exit")
    exit.Transform:SetPosition(data.target_x, data.target_y, data.target_z)
    exit:SetExitTarget(inst)
    inst:SetExitTarget(exit)
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
  inst:AddTag("vault_teleporter")


  inst.AnimState:SetBank("ms_arenateleporter")
  inst.AnimState:SetBuild("ms_arenateleporter")
  inst.AnimState:PlayAnimation("idle")  

  inst.MiniMapEntity:SetIcon("minimap_ms_arenateleporter.tex")

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

return MakeTeleporter("ms_arenateleporter", nil, function(inst) inst.OnSave = OnSave inst.OnLoad = OnLoad end),
MakeTeleporter("ms_arenateleporter_exit", function(inst) inst.persists = false end, nil)