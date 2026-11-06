local RegisterShaderMouse = require("ms_shader_mouse").Register

local assets =

{
    Asset("ANIM", "anim/ms_wall_tree.zip"),
}

local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "moonrocknugget",
    "moonglass",
    "moonrockseed",
    "rock_break_fx",
    "collapse_small",
}

local function OnWork(inst, worker, workleft)

  local pt = inst:GetPosition()
  local angle = inst.Transform:GetRotation()
  local item = SpawnPrefab("mountain_wooden_box")
  item.Transform:SetPosition(pt.x + math.cos(angle)*3, pt.y, pt.z-math.sin(angle)*3)
  LaunchAt(item, item, worker, math.max(1, 5 - pt.y), math.max(pt.y,3.5), 1)
  item.Physics:SetCollisionMask(
		COLLISION.GROUND,
    COLLISION.MS_CLOUDS,
    COLLISION.SMALLOBSTACLES
	)
  inst.components.lootdropper:DropLoot(pt)
  inst:RemoveTag("mountain_throw_target")
  
  if inst.components.workable ~= nil then
    inst.components.workable:SetWorkLeft(0)
    inst.components.workable:SetWorkable(false)
  end
  
    inst.AnimState:ClearOverrideSymbol("tree")
    inst.components.timer:StartTimer("regenerate", TUNING.MS_MOUNTAIN_BUSH_REGEN_DURATION + math.random(-TUNING.MS_MOUNTAIN_BUSH_REGEN_VARIATION, TUNING.MS_MOUNTAIN_BUSH_REGEN_VARIATION))
end



local function OnTimerDone(inst)
  inst.AnimState:OverrideSymbol("tree", "ms_wall_tree", "tree_full")
  inst.components.workable:SetWorkLeft(1)
  inst.components.workable:SetWorkable(false)
  inst:AddTag("mountain_throw_target")
end

local function OnInit(inst)
  if not( inst.components.timer and inst.components.timer:TimerExists("regenerate")) and inst.AnimState:IsCurrentAnimation("idle") then
    if math.random() > 0.66 then
      OnTimerDone(inst)
    else
      inst.components.timer:StartTimer("regenerate", TUNING.MS_MOUNTAIN_BUSH_REGEN_DURATION + math.random(-TUNING.MS_MOUNTAIN_BUSH_REGEN_VARIATION, TUNING.MS_MOUNTAIN_BUSH_REGEN_VARIATION))
    end
  else
    OnTimerDone(inst)
  end
end



local function UpdateBillboardParams(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.AnimState:SetFloatParams(x, y, z)
    inst.AnimState:SetSortWorldOffset(0, -y + 2, 0)
end

local function fn()
    local inst = CreateEntity()

    -- Must be the first tag, before adding AnimState (see wagdrone_flying).
    inst:AddTag("can_offset_sort_pos")
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ms_wall_tree")
    inst.AnimState:SetBuild("ms_wall_tree")

    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/rotation_vertical_shader.ksh"))	

    inst.MiniMapEntity:SetIcon("ms_wall_bush.tex")

    inst.Transform:SetEightFaced()
    RegisterShaderMouse(inst, "rotation")

    if not TheNet:IsDedicated() then
        inst:DoStaticTaskInTime(0, UpdateBillboardParams)
    end

    inst.entity:SetPristine()



    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.CHOP)
    workable.maxwork = 1
    workable:SetWorkLeft(1)
    workable:SetOnWorkCallback(OnWork)
    inst.components.workable:SetWorkable(false)

    inst:AddComponent("inspectable")
    inst:AddComponent("savedrotation")
    inst:AddComponent("timer")

    inst:ListenForEvent("timerdone", OnTimerDone)

    inst:DoTaskInTime(0, OnInit)

    
    --MakeHauntableWork(inst)

    return inst
end

return Prefab("ms_wall_bush", fn, assets, prefabs)


