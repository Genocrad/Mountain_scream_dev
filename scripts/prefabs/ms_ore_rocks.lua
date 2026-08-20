local assets =
{
    Asset("ANIM", "anim/ms_ore_boulders.zip"),
}



local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "ms_alu_ore",
    "ms_copper_ore",
    "ms_coal"
}

SetSharedLootTable( 'ms_alu_rock',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'ms_alu_ore',  1.00},
    {'flint',  1.00},
    {'ms_alu_ore',  0.50},
    {'ms_alu_ore',  0.25},
    {'flint',  0.60},
})

SetSharedLootTable( 'ms_copper_rock',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'ms_copper_ore',  1.00},
    {'flint',  1.00},
    {'ms_copper_ore',  0.50},
    {'ms_copper_ore',  0.25},
    {'flint',  0.60},
})

SetSharedLootTable( 'ms_coal_rock',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'ms_coal',  1.00},
    {'flint',  1.00},
    {'ms_coal',  0.50},
    {'ms_coal',  0.25},
    {'flint',  0.60},
})

SetSharedLootTable( 'ms_geode_rock',
{
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'rocks',  1.00},
    {'ms_geode',  1.00},
    {'ms_geode',  0.25},
    {'flint',  1.00},
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
        inst:Remove()
    else
		local anim = 
            (workleft < TUNING.ROCKS_MINE / 3 and "idle_1_" .. inst.oretype) or
            (workleft < TUNING.ROCKS_MINE * 2 / 3 and "idle_2_" .. inst.oretype) or
            "idle_3_" .. inst.oretype

	

		inst.AnimState:PlayAnimation(anim)
    end
end

local function MakeRock(oretype)
  local function fn()  
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.oretype = oretype
     
    inst.MiniMapEntity:SetIcon("ms_" .. oretype .. "_rock.tex")
    
    

    inst.AnimState:SetBank("ms_ore_boulders")
    inst.AnimState:SetBuild("ms_ore_boulders")

    inst.AnimState:PlayAnimation("idle_3_" .. oretype )
 

    MakeSnowCoveredPristine(inst)

    inst:AddTag("boulder")
  
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('ms_' .. oretype .. "_rock")
    
    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.MINE)
    workable:SetWorkLeft(TUNING.ROCKS_MINE)
    workable:SetOnWorkCallback(OnWork)

    inst:AddComponent("inspectable")

    MakeHauntableWork(inst)

    return inst
end
return Prefab("ms_" .. oretype .. "_rock", fn, assets, prefabs)
end

return MakeRock("alu"), MakeRock("coal"), MakeRock("copper"), MakeRock("geode")

