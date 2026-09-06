local assets =
{
    Asset("ANIM", "anim/ms_worldmigrator.zip"),
}

local function SetOpenMinimapIcon(inst, off)
    inst.MiniMapEntity:SetIcon(off and "minimap_migrator_off.tex" or "minimap_migrator.tex")
end

local function OnWork(inst, worker, workleft)
    if workleft <= 0 then
      local pt = inst:GetPosition()
      SpawnPrefab("rock_break_fx").Transform:SetPosition(pt:Get())
      inst.components.lootdropper:DropLoot(pt)
      inst.components.worldmigrator:SetHideActions(false)
      inst.broken = true
      local off = inst.components.worldmigrator._status == 1
      SetOpenMinimapIcon(inst, off)
    end
    inst.AnimState:PlayAnimation(
      (workleft <= 0 and (inst.components.worldmigrator._status == 1 and "idle_off" or "idle")) or
      (workleft < TUNING.ROCKS_MINE / 4 and "idle_1/4") or
      (workleft < TUNING.ROCKS_MINE * 2 / 4 and "idle_2/4") or
      (workleft < TUNING.ROCKS_MINE * 3 / 4 and "idle_3/4") or
      "idle_full"
    )
end

local function getstatus(inst)
  if inst.AnimState:IsCurrentAnimation("idle") then return "ON" end
  if inst.AnimState:IsCurrentAnimation("idle_off") then return "OFF" end
  return "DEFAULT"
end
local function MakeWM(name, up)
  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .4)

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("minimap_migrator.tex")

    inst.AnimState:SetBank("ms_worldmigrator")
    inst.AnimState:SetBuild("ms_worldmigrator")
    inst.AnimState:PlayAnimation("idle_full")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
      return inst
    end
    
    local lootdropper = inst:AddComponent("lootdropper")
    lootdropper:SetLoot({ "rocks", "rocks", "flint", "flint", "flint" })
    
    local inspectable = inst:AddComponent("inspectable")
    inspectable.getstatus = getstatus
    local worldmigrator = inst:AddComponent("worldmigrator")
    
    if up == true then
      inst.AnimState:PlayAnimation("idle")
      worldmigrator.shard_name = "Master" 
      TheWorld.ms_worldmigrator = inst
    else
      worldmigrator.shard_name = "Caves"
      worldmigrator:SetHideActions(true)
      local workable = inst:AddComponent("workable")
      workable:SetWorkAction(ACTIONS.MINE)
      workable:SetWorkLeft(TUNING.ROCKS_MINE)
      workable:SetOnWorkCallback(OnWork)
      inst.MiniMapEntity:SetIcon("minimap_migrator_full.tex")
    end
    worldmigrator:SetID("mountain_scream")

    inst.OnSave = function(inst, data) if inst.broken then data.broken = true end end
    inst.OnLoad = function(inst, data) if data ~= nil and data.broken then inst.components.lootdropper:SetLoot({}) inst.components.workable:SetWorkLeft(-1) inst.components.workable:WorkedBy_Internal(TheWorld, 1) end end
    
    inst:ListenForEvent("migration_unavailable", function(inst)
      if inst.components.workable and inst.components.workable.workleft < 1 then
        inst.AnimState:PlayAnimation("idle_off")
        SetOpenMinimapIcon(inst, true)
      end
    end)
    inst:ListenForEvent("migration_available", function(inst)
      if inst.components.workable and inst.components.workable.workleft < 1 then
        inst.AnimState:PlayAnimation("idle")
        SetOpenMinimapIcon(inst, false)
      end
    end)
    return inst
  end
  return Prefab(name, fn, assets)
end

return MakeWM("ms_worldmigrator_up", true),
MakeWM("ms_worldmigrator_down", false)