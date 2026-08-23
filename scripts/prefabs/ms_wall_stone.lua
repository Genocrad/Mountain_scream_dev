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
    local angle = inst.Transform:GetRotation()
    SpawnPrefab("mountain_suspicious_ore").Transform:SetPosition(pt.x + math.cos(angle)*2, pt.y, pt.z-math.sin(angle)*2)
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

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

    inst:AddTag("mountain_stalactite")
 
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

   


    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.MINE)
    workable:SetWorkLeft(1)
    workable:SetOnWorkCallback(OnWork)


    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "ROCK"
  
    inst:AddComponent("savedrotation")
    MakeHauntableWork(inst)

    return inst
end


return Prefab("ms_wall_stone", fn, assets, prefabs)
