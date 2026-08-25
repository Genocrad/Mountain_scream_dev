 local prefabs = {
  "mountain_snowpiles",
  "mountain_gravel_pile"
}
 
 local function IsMsTile(tile)
  return tile == WORLD_TILES.MS_HIGHLAND or
  tile == WORLD_TILES.MS_CAVE or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_2 or
  tile == WORLD_TILES.MS_MOUNTAIN_HIGH or
  tile == WORLD_TILES.MS_PERMAFROST or
  tile == WORLD_TILES.MS_SNOW or 
  tile == WORLD_TILES.ROCKY
end

local function MakeSpawner(name, prefab)
 local function fn()
      local inst = CreateEntity()
      -- spawner, non-networked
      inst.entity:AddTransform()
      
      inst:DoTaskInTime(0, function(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if TheWorld.net.components.dungeonmapoverwatch then
          local level = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z)
          local centerx, centerz
          if level then
            
            centerx, centerz = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(level)
          end
          
          if centerx and centerz then
            local direction = Vector3(centerx - x, 0, centerz - z)
            direction:Normalize()
            local angle1 = math.acos(direction:Dot(Vector3(1, 0, 0)))
            local angle2 
            local near_wall = TheSim:FindEntities(x, y, z, 50, {"ms_wall"})
            
            if near_wall and near_wall[1] then
                local x1, y1, z1 = near_wall[1].Transform:GetWorldPosition()
                direction = Vector3(x-x1, 0, z - z1)
                direction:Normalize()
                angle2 = math.acos(direction:Dot(Vector3(1, 0, 0)))
              angle1 = angle2
            end
            for i = -28, 28, 2 do 
              local stepx, stepz = (i + math.random(-1,1)/2)  * math.cos(angle1) ,(i + math.random(-1,1)/2)  * math.sin(angle1)
              if IsMsTile(TheWorld.Map:GetTileAtPoint(x+stepx, 0, z+stepz)) 
                or IsMsTile(TheWorld.Map:GetTileAtPoint(x+1+stepx, 0, z+stepz))
                or IsMsTile(TheWorld.Map:GetTileAtPoint(x-1+stepx, 0, z+stepz))
                or IsMsTile(TheWorld.Map:GetTileAtPoint(x+stepx, 0, z+1+stepz))
                or IsMsTile(TheWorld.Map:GetTileAtPoint(x+stepx, 0, z-1+stepz)) then
                print(inst, x+stepx, z+stepz)
                local pile = SpawnPrefab(prefab)
                pile.Transform:SetPosition(x+stepx, 0, z+stepz)
              else
                if i > 28 then
                  break
                end
              end
            end
            x = x + math.random() > 0.5 and -5 or 5
            z= z + math.random() > 0.5 and -5 or 5
            for i = -28, 28, 2 do 
              local stepx, stepz = (i + math.random(-1,1)/2)  * math.cos(angle1) ,(i + math.random(-1,1)/2)  * math.sin(angle1)
              if IsMsTile(TheWorld.Map:GetTileAtPoint(x+stepx, 0, z+stepz)) 
                or IsMsTile(TheWorld.Map:GetTileAtPoint(x+1+stepx, 0, z+stepz))
                or IsMsTile(TheWorld.Map:GetTileAtPoint(x-1+stepx, 0, z+stepz))
                or IsMsTile(TheWorld.Map:GetTileAtPoint(x+stepx, 0, z+1+stepz))
                or IsMsTile(TheWorld.Map:GetTileAtPoint(x+stepx, 0, z-1+stepz)) then
                print(inst, x+stepx, z+stepz)
                local pile = SpawnPrefab(prefab)
                pile.Transform:SetPosition(x+stepx, 0, z+stepz)
              else
                if i > 28 then
                  break
                end
              end
            end
          end
        end
        inst:Remove()
      end)
      return inst
  end
  
  return Prefab(name, fn, nil, prefabs)
end

return MakeSpawner("ms_barricade_spawner_gravel","mountain_gravel_pile"), 
       MakeSpawner("ms_barricade_spawner_snow","mountain_snowpile")
