local AddPrefabPostInit = AddPrefabPostInit

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local function onterraformingfinished(inst)
  inst.components.dungeonwallspawner:SpawnMainEntrance()
  local x, y = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(11)
  inst.components.dungeonwallspawner:SpawnCaveLayout(x,y-120, 10,3)
  local x, y = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(12)
  inst.components.dungeonwallspawner:SpawnCaveLayout(x,y-120, 20,5)
  -- SpawnWallsAroundPoint(level, wall, size, normal_tile, technical_tile)
  inst.components.dungeonwallspawner:SpawnWallsAroundPoint(2, "", 65, WORLD_TILES.MS_MOUNTAIN_LOW_2, WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL)
  inst.components.dungeonwallspawner:SpawnWallsAroundPoint(3, "", 45, WORLD_TILES.MS_MOUNTAIN_LOW_2, WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL)
  inst.components.dungeonwallspawner:SpawnWallsAroundPoint(4, "", 35, WORLD_TILES.MS_MOUNTAIN_LOW_2, WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL)
  inst.components.dungeonwallspawner:SpawnWallsAroundPoint(5, "_high", 35, WORLD_TILES.MS_MOUNTAIN_HIGH, WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL)
  inst.components.dungeonwallspawner:SpawnWallsAroundPoint(6, "_high", 35, WORLD_TILES.MS_MOUNTAIN_HIGH, WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL)
  inst.components.dungeonwallspawner:SpawnWallsAroundPoint(7, "_snow", 25, WORLD_TILES.MS_PERMAFROST, WORLD_TILES.MS_PERMAFROST_TECHNICAL)
  inst.components.dungeonwallspawner:SpawnArenaTeleporter()
  inst.components.dungeonwallspawner:SpawnWallsAroundPoint(8, "_snow", 25, WORLD_TILES.MS_PERMAFROST, WORLD_TILES.MS_PERMAFROST_TECHNICAL)

  -- After walls: decorate configured floors (level 1–2 green foothills for now).
  if inst.components.dungeoncontentspawner ~= nil then
    inst.components.dungeoncontentspawner:SpawnConfiguredLevels()
  end

  inst:RemoveEventCallback("terraforming_finished", inst.onterraformingfinished)
end

AddPrefabPostInit("cave", function(inst)
    
  inst:AddTag("mountain_scream_dungeons")
  
    inst.Map:AddTileCollisionSet(
        COLLISION.MS_CLOUDS,
        TileGroups.MS_CLOUDS, false,
        TileGroups.MS_CLOUDS, true,
        0, 64
    )
        inst.Map:AddTileCollisionSet(
        COLLISION.LAND_OCEAN_LIMITS,
        TileGroups.MS_TECHNICAL, true,
        TileGroups.MS_TECHNICAL, false,
        0.15, 64
    )
    inst.Map:AddTileCollisionSet(
        COLLISION.SMALLOBSTACLES,
        TileGroups.MS_TECHNICAL, true,
        TileGroups.MS_TECHNICAL, false,
        0.4, 64
    )
 if not TheNet:IsDedicated() then
  inst.entity:AddWaveComponent()
    inst.WaveComponent:SetWaveParams(13.5, 2.5, 0)    			-- wave texture u repeat, forward distance between waves
    inst.WaveComponent:SetWaveSize(80, 3.5)							-- wave mesh width and height
    inst.WaveComponent:SetWaveMotion(.3, .5, .35) 
    inst.WaveComponent:SetWaveTexture(resolvefilepath("images/wave_null.tex"))
    inst.WaveComponent:SetWaveEffect("shaders/waves.ksh")
  end
  inst.wavemanager_on = false
  inst:ListenForEvent("wavemanager_off", function(inst)
    if not TheNet:IsDedicated() then
      inst.WaveComponent:SetWaveTexture(resolvefilepath("images/wave_null.tex"))
      inst.wavemanager_on = false
    end
  end)
  inst:ListenForEvent("wavemanager_on", function(inst)
    if not TheNet:IsDedicated() then
      inst.WaveComponent:SetWaveTexture(resolvefilepath("images/wave_clouds.tex"))
      inst.wavemanager_on = true
    end
  end)
  if not TheWorld.ismastersim then
    return inst
  end
  inst:AddComponent("dungeonwallspawner")
  inst:AddComponent("dungeoncontentspawner")

  inst.onterraformingfinished = onterraformingfinished
  inst:ListenForEvent("terraforming_finished", inst.onterraformingfinished)


end)

AddPrefabPostInit("cave_network", function(inst)
  inst:AddComponent("dungeonmapoverwatch")    
end)


