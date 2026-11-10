local RegisterShaderMouse = require("ms_shader_mouse").Register
local RegisterOcclusionProp = require("ms_wall_occlusion").RegisterProp

local assets =
{
    Asset("ANIM", "anim/ms_wall_stone.zip"),
}

local prefabs =
{
  "mountain_suspicious_ore"
}

local function OnWork(inst, worker, workleft)
    local pt = inst:GetPosition()
    SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
    local angle = math.rad(inst.Transform:GetRotation())
    local item = SpawnPrefab("mountain_suspicious_ore")
    item.Transform:SetPosition(pt.x + math.cos(angle)*3, pt.y, pt.z-math.sin(angle)*3)
    LaunchAt(item, item, worker, math.max(2, 5 - pt.y), math.max(pt.y,3.5), 1)
  item.Physics:SetCollisionMask(
		COLLISION.GROUND,
    COLLISION.MS_CLOUDS,
    COLLISION.SMALLOBSTACLES
	)
    inst:Remove()
end


local function UpdateBillboardParams(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.AnimState:SetFloatParams(x, y, z)
    inst.AnimState:SetSortWorldOffset(0, -y + 0.75, 0)
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

    inst.AnimState:SetBank("ms_wall_stone")
    inst.AnimState:SetBuild("ms_wall_stone")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetDepthTestEnabled(true)
    inst.AnimState:SetDepthWriteEnabled(true)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/rotation_vertical_shader.ksh"))	

    inst.Transform:SetEightFaced()

    RegisterShaderMouse(inst, "rotation")
    RegisterOcclusionProp(inst)
    inst:AddTag("mountain_stalactite")

    if not TheNet:IsDedicated() then
        inst:DoStaticTaskInTime(0, UpdateBillboardParams)
    end

    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.MINE)
    workable:SetWorkLeft(1)
    workable:SetOnWorkCallback(OnWork)
    workable:SetWorkable(false)

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "ROCK"

    inst:AddComponent("savedrotation")

    MakeHauntableWork(inst)
    
    return inst

end

return Prefab("ms_wall_stone", fn, assets, prefabs)


