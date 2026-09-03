local assets = {
    Asset("ANIM", "anim/ms_shortcut.zip"),
}

local prefabs = {
  "mountain_transformation_cube",
}

local function OnActivate(inst, doer)
    if doer:HasTag("player") then
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
    end
end

local function SetShortcutMinimapIcon(inst, enabled)
  inst.MiniMapEntity:SetIcon(enabled and "ms_shortcut.tex" or "ms_shortcut_off.tex")
end

local function OnCubeTaken(inst)
  local teleport_target = inst.components.teleporter:GetTarget()
  if teleport_target then
    inst.components.trader:Enable()
    inst.components.workable:SetWorkable(false)
    inst.AnimState:PlayAnimation("idle")
    inst.components.teleporter:SetEnabled(false)
    SetShortcutMinimapIcon(inst, false)
    teleport_target.components.trader:Enable()
    teleport_target.components.workable:SetWorkable(false)
    teleport_target.AnimState:PlayAnimation("idle")
    teleport_target.components.teleporter:SetEnabled(false)
    SetShortcutMinimapIcon(teleport_target, false)
    if inst.cube_percent then
      local cube = SpawnPrefab("mountain_transformation_cube")
      cube.components.finiteuses:SetPercent(inst.cube_percent)
      cube.Transform:SetPosition(inst.Transform:GetWorldPosition())
      Launch(cube, inst, 2)
    end
    inst.cube_percent = nil
    teleport_target.cube_percent = nil
  end
end

local function ItemTradeTest(inst, item)
    if item == nil then
        return false
    elseif item.prefab ~= "mountain_transformation_cube" then
        return false, "NOTCUBEITEM"
    end
    return true
end

local function OnCubeGiven(inst, giver, item)
  local teleport_target = inst.components.teleporter:GetTarget()
  if teleport_target then
    inst.components.trader:Disable()
    inst.components.workable:SetWorkable(true)
    inst.components.teleporter:SetEnabled(true)
    inst.cube_percent = item.components.finiteuses:GetPercent()
    inst.AnimState:PlayAnimation("idle_on")
    SetShortcutMinimapIcon(inst, true)
    teleport_target.components.trader:Disable()
    teleport_target.components.workable:SetWorkable(true)
    teleport_target.components.teleporter:SetEnabled(true)
    teleport_target.cube_percent = item.components.finiteuses:GetPercent()
    teleport_target.AnimState:PlayAnimation("idle_on")
    SetShortcutMinimapIcon(teleport_target, true)
  end
    if giver ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/atrium_gate/key_in")
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
    inst:ListenForEvent("onremove", inst._exittarget_onremove, targetinst)
end

local function OnSave(inst, data)
	if inst.components.teleporter.targetTeleporter then
		data.target_x, data.target_y, data.target_z =  inst.components.teleporter.targetTeleporter.Transform:GetWorldPosition()
	end
  if inst.cube_percent then
    data.cube_percent = inst.cube_percent
  end
end

local function OnLoad(inst, data)
	if data ~= nil and data.target_x then
    local exit = SpawnPrefab("ms_shortcut_exit")
    exit.Transform:SetPosition(data.target_x, data.target_y, data.target_z)
    exit:SetExitTarget(inst)
    inst:SetExitTarget(exit)
	end
  if data ~= nil and data.cube_percent then
    local cube = SpawnPrefab("mountain_transformation_cube")
    cube.components.finiteuses:SetPercent(data.cube_percent)
    OnCubeGiven(inst, nil, cube)
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


  inst.AnimState:SetBank("ms_shortcut")
  inst.AnimState:SetBuild("ms_shortcut")
  inst.AnimState:PlayAnimation("idle")  

  inst.MiniMapEntity:SetIcon("ms_shortcut_off.tex")

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
  
  inst:AddComponent("workable")
  inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
  inst.components.workable:SetWorkLeft(2000000)
  inst.components.workable:SetOnWorkCallback(OnCubeTaken)
  inst.components.workable:SetWorkable(false)

  inst:AddComponent("trader")
  inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
  inst.components.trader.deleteitemonaccept = true
  inst.components.trader.onaccept = OnCubeGiven
    
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

return MakeTeleporter("ms_shortcut", nil, function(inst) inst.OnSave = OnSave inst.OnLoad = OnLoad end),
MakeTeleporter("ms_shortcut_exit", function(inst) inst.persists = false end, nil)