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

	--halloween
	"spooked_spider_rock_fx",
}

SetSharedLootTable( 'rock1',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
  --{'nitre',  1.00},
    {'flint',  1.00},
    --{'nitre',  0.25},
    {'flint',  0.60},
})


 
local function OnWork(inst, worker, workleft)
    if workleft <= 0 then
        local pt = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
        inst.components.lootdropper:DropLoot(pt)

        if inst.showCloudFXwhenRemoved then
            local fx = SpawnPrefab("collapse_small")
            fx.Transform:SetPosition(pt.x, pt.y, pt.z)
        end

		if not inst.doNotRemoveOnWorkDone then
	        inst:Remove()
		end
    else
		local anim = 
            (workleft < TUNING.ROCKS_MINE / 3 and "low") or
            (workleft < TUNING.ROCKS_MINE * 2 / 3 and "med") or
            "full"

	

		inst.AnimState:PlayAnimation(anim)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()



    inst.AnimState:SetBank("ms_wall_tree")
    inst.AnimState:SetBuild("ms_wall_tree")

    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetDepthTestEnabled(true)
    inst.AnimState:SetDepthWriteEnabled(true)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/rotation_vertical_shader.ksh"))	
    
    inst.Transform:SetEightFaced()
    
    inst:AddTag("mountain_throw_target")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

   

    --[[inst:AddComponent("lootdropper")

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.CHOP)
    workable:SetWorkLeft(1)
    workable:SetOnWorkCallback(OnWork)
    inst.components.workable:SetWorkable(false)
    ]]--
    inst:AddComponent("inspectable")

    inst:AddComponent("savedrotation")
    
    --MakeHauntableWork(inst)
    
    return inst
end


return Prefab("ms_wall_bush", fn, assets, prefabs)
    