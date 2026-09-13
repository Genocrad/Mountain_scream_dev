

AddPrefabPostInit("forest", function(inst)
  if TheWorld.ismastersim then
    inst:DoTaskInTime(5, function(inst)
      if inst.ms_worldmigrator_down == nil then
        local ents = TheSim:FindEntities(0,0,0, 2000, {"CLASSIFIED"})
        for k,v in pairs(ents) do
          if v.prefab == "meteorspawner" then
            local x,y,z = v.Transform:GetWorldPosition()
            local tile_x, tile_z = TheWorld.Map:GetTileXYAtPoint(x, 0, z)
                
            TheWorld.Map:SetTile(tile_x, tile_z, WORLD_TILES.MS_MOUNTAIN_LOW_2)
            TheWorld.Map:SetTile(tile_x+1, tile_z, WORLD_TILES.MS_MOUNTAIN_LOW_2)
            TheWorld.Map:SetTile(tile_x-1, tile_z, WORLD_TILES.MS_MOUNTAIN_LOW_2)
            TheWorld.Map:SetTile(tile_x, tile_z+1, WORLD_TILES.MS_MOUNTAIN_LOW_2)
            TheWorld.Map:SetTile(tile_x, tile_z-1, WORLD_TILES.MS_MOUNTAIN_LOW_2)
                  
            SpawnPrefab("ms_worldmigrator_down").Transform:SetPosition(x,y,z)
            break
          end
        end
      end 
    end)
  end
end)


