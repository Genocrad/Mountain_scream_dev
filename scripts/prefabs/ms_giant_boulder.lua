local assets =
{
    Asset("ANIM", "anim/giant_boulder.zip"),
}



local prefabs =
{
    "rocks",
    "nitre",
    "flint",
    "ms_alu_ore",
    "ms_copper_ore",
    "ms_coal",
    "thulecite_pieces",
}

local typetonumber = {
  empty = 0,
  coal = 1,
  minerals = 2,
  metals = 3,
  thulecite = 4,
}

local function OnWork(inst, worker, workleft)
    if worker.workleft then
      workleft = worker.workleft
    end
    if workleft < 1 then
      local item = SpawnPrefab(weighted_random_choice(TUNING.MS_GIANT_BOULDER.LOOTS[inst.oretype]))
      LaunchAt(item, inst, worker, 1, 3, 3, 0)
      inst.components.workable:SetWorkLeft(TUNING.MS_GIANT_BOULDER.WORK_PER_DROP[inst.oretype])
    end
		local anim = 
            (workleft <= TUNING.MS_GIANT_BOULDER.WORK_PER_DROP[inst.oretype] and inst.biome .. "_ore" .. typetonumber[inst.oretype]) or
            (workleft < TUNING.MS_GIANT_BOULDER.WORK_LEFT / 3 and inst.biome .. "_crack3") or
            (workleft < TUNING.MS_GIANT_BOULDER.WORK_LEFT *2 / 3 and inst.biome .. "_crack2") or
            (workleft < TUNING.MS_GIANT_BOULDER.WORK_LEFT + TUNING.MS_GIANT_BOULDER.WORK_PER_DROP[inst.oretype]  and inst.biome .. "_crack1") or
            inst.biome .. "_crack0"
    
    if workleft < TUNING.MS_GIANT_BOULDER.WORK_PER_DROP[inst.oretype] then
      inst.MiniMapEntity:SetIcon("giant_boulder_" .. inst.oretype .. ".tex")
    end
    
		inst.AnimState:PlayAnimation(anim)
    
end

local function OnSave(inst, data)
	if inst.oretype then
		data.oretype = inst.oretype
  end
end

local function OnLoad(inst, data)
	if data ~= nil and data.oretype then
    inst.oretype = data.oretype
    -- Otherwise loads before Onload
    OnWork(inst, { workleft = inst.components.workable.workleft })
  end
end

local function MakeRock(biome)
  local function fn()  
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.biome = biome
    inst.oretype = weighted_random_choice(TUNING.MS_GIANT_BOULDER.VARIANTS)
    
    inst.MiniMapEntity:SetIcon("giant_boulder.tex")
    
    

    inst.AnimState:SetBank("giant_boulder")
    inst.AnimState:SetBuild("giant_boulder")

    inst.AnimState:PlayAnimation(biome .. "_crack0")
 

    MakeSnowCoveredPristine(inst)

    inst:AddTag("boulder")
  
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    
    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.MINE)
    workable:SetWorkLeft(TUNING.MS_GIANT_BOULDER.WORK_LEFT + TUNING.MS_GIANT_BOULDER.WORK_PER_DROP[inst.oretype])
    workable:SetOnWorkCallback(OnWork)
    workable.savestate = true
    
    inst:AddComponent("inspectable")
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    
    MakeHauntableWork(inst)

    return inst
end
return Prefab("ms_giant_boulder_" .. biome, fn, assets, prefabs)
end

return MakeRock("grass"), MakeRock("rock"), MakeRock("snow")

