local assets = { }

local function IsInvalidTileTerraformer(tile)
  return not TileGroupManager:IsLandTile(tile)
  and tile ~= WORLD_TILES.VOID_TECHNICAL  
end

local function IsMsTile(tile)
  return tile == WORLD_TILES.MS_HIGHLAND or
         tile == WORLD_TILES.MS_CAVE or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_2 or
         tile == WORLD_TILES.MS_MOUNTAIN_HIGH or
         tile == WORLD_TILES.MS_PERMAFROST or
         tile == WORLD_TILES.MS_SNOW 
end

local function IsMsTechnicalTile(tile)
  return tile == WORLD_TILES.VOID_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL or
         tile == WORLD_TILES.MS_PERMAFROST_TECHNICAL
end
  

local function SetTileOrNoiseOrNoise(tile, rarity, x, z, snow_randomseed, snow_rarity, level)
  level = level + 1
  local current
  if type(tile) == "table" then
    local random = perlin(x/8+0.001,0,z/8+0.001)
    --local random = rarity + math.sin(x+snow_randomseed) + math.sin(z+snow_randomseed)
    current =  random<rarity and tile[1] or tile[2]
    TheWorld.Map:SetTile(x,z, current)  
  else
    current = tile
    TheWorld.Map:SetTile(x,z, tile)  
  end
  if snow_randomseed and math.cos(math.tan((x+snow_randomseed)*z) +math.tan((x+snow_randomseed)/z)) > snow_rarity then  
    TheWorld.Map:SetTile(x,z, WORLD_TILES.MS_SNOW)
      
    if TheWorld.components.undertile ~= nil then
      TheWorld.components.undertile:SetTileUnderneath(x, z, current)
    end
  end
  -- Luigi: Just doing it is cheaper then doing checks, i think?
  for i = -10, 10 do
    for j = -10, 10 do
      TheWorld.net.components.dungeonmapoverwatch.cloud_tiles_planned_cords[x+i][z+j] = true
    end
  end
  -- Now check if this is the furthest point.
  local centerx, centery = TheWorld.net.components.dungeonmapoverwatch._map_points_level_x:value()[level], TheWorld.net.components.dungeonmapoverwatch._map_points_level_y:value()[level]
  if centerx - x < -TheWorld.net.components.dungeonmapoverwatch.level_limits_xp[level] then
    TheWorld.net.components.dungeonmapoverwatch.level_limits_xp[level] = x - centerx 
  end
  if centerx - x > TheWorld.net.components.dungeonmapoverwatch.level_limits_xn[level]  then
    TheWorld.net.components.dungeonmapoverwatch.level_limits_xn[level] = centerx - x
  end
  if centery - z < -TheWorld.net.components.dungeonmapoverwatch.level_limits_yp[level] then
    TheWorld.net.components.dungeonmapoverwatch.level_limits_yp[level] = z - centery 
  end
  if centery - z > TheWorld.net.components.dungeonmapoverwatch.level_limits_yn[level] then
    TheWorld.net.components.dungeonmapoverwatch.level_limits_yn[level] = centery - z
  end
  TheWorld.net.components.dungeonmapoverwatch:AddSpawnPointsForTile(level, x, z)
end

   
-- Yes, this is practically worldgen. Now what?
local function MakeTerraformer(name, tiles, tile_rarity, snow_randomseed, snow_rarity, size, randomness_size, r_edge_min, r_edge_max, l_edge_min, l_edge_max, d_edge_min, d_edge_max, u_edge_min, u_edge_max, next_terraformer, spawn_offset_x, spawn_offset_y)
  local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst:AddTag("ms_terraformer")
    if not TheWorld.ismastersim then 
      return inst        
    end

    -- Position not being initialised? 
    inst:DoTaskInTime(0.05, function()
        local posx, posy, posz = inst.Transform:GetWorldPosition()
         if inst.prefab == "terraformer_mountain_dungeon_level_1" then
   
          local level, _ = string.gsub(inst.prefab,"terraformer_mountain_dungeon_level_", "")
          level =  tonumber(level)
          TheWorld.net.components.dungeonmapoverwatch:AddPoint(level, posx, posz)
        end
        

      
      if not TileGroupManager:IsLandTile(TheWorld.Map:GetTileAtPoint(posx, posy, posz)) and
        not inst.prefab == "terraformer_mountain_dungeon_level_7" then -- on level 7 there is so little space, that it causes all terraformers to be deleted. whoops.
          inst:Remove()
        end
      
      end)
    inst:DoTaskInTime(0.1, function()

        -- Actual tile replacement

        local posx, posy, posz = inst.Transform:GetWorldPosition()
        local level, _ = string.gsub(inst.prefab,"terraformer_mountain_dungeon_level_", "")
        level =  tonumber(level)
        local centerx, centery = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(level)
            
        local posx, posy, posz = inst.Transform:GetWorldPosition()

        inst.Transform:SetPosition(math.floor((centerx+posx+posx)/12)*4, posy, math.floor((centery+posz+posz)/12)*4)

        local posx, posy, posz = inst.Transform:GetWorldPosition()
        
        -- Now check if we are near other terraformers. If do, it kills itself.
        local nearest_terraformers = TheSim:FindEntities(posx, posy, posz, 40, {"ms_terraformer"})
        if nearest_terraformers then for k,v in pairs(nearest_terraformers) do v:Remove() end end
        
        local center_x, center_y = TheWorld.Map:GetTileXYAtPoint(posx, posy, posz)
        
        if level ~= 1 then
          -- Not efficient, but more is better in this case. 
          for i = -3, 3 do
            for j = -3, 3 do 
              local plug = SpawnPrefab("giant_plug_marker")
              plug.Transform:SetPosition(posx+i*10*4, 0, posz+j*10*4)  
            end
          end
        end
        
        
      
        -- Measure distance to the edge in tiles

        local rightrandom = r_edge_min
        local leftrandom = l_edge_min
        local downrandom = d_edge_min
        local uprandom = u_edge_min
        local water_tile = false

        -- Making array of numbers in the right order
        -- So we have 0, 1, 2, -1, -2 instead of -2, -1, 0, 1, 2

        local sorted_cords_x = {0}
        local sorted_cords_y = {0}

        for x=1,size+math.random(-randomness_size,randomness_size) do
          table.insert(sorted_cords_x, x)
        end
        for x=-1,-size+math.random(-randomness_size,randomness_size), -1 do

          table.insert(sorted_cords_x, x)
        end
        for y=1,size+math.random(-randomness_size,randomness_size) do
          table.insert(sorted_cords_y, y)
        end
        for y=-1,-size+math.random(-randomness_size,randomness_size), -1 do
          table.insert(sorted_cords_y, y)
        end


        --And now do the terraforming

        for _, tilex in pairs(sorted_cords_x) do
          for _, tiley in pairs(sorted_cords_y) do
            if not((center_x + tilex - leftrandom) < 0 or (center_x + tilex + rightrandom) > 700 or (center_y + tiley - uprandom) < 0 or (center_y + tiley + downrandom) >  700) then
            if (tilex*4)*(tilex*4)+(tiley*4)*(tiley*4) + math.random(-40, 40) < (size-10)*(size-10)*16 then

              water_tile = false


              -- Check for all tiles that are not part of ms ones.

              if IsInvalidTileTerraformer(TheWorld.Map:GetTileAtPoint(posx+tilex*4+4*rightrandom, 0, posz+tiley*4)) then 
                water_tile= true
                if math.random() < 0.1 and water_tile == false then rightrandom = math.clamp(rightrandom + math.random(-1,1), r_edge_min,r_edge_max) end 
              elseif IsInvalidTileTerraformer(TheWorld.Map:GetTileAtPoint(posx+tilex*4-4*leftrandom, 0, posz+tiley*4)) then
                water_tile= true
                if math.random() < 0.1 and water_tile == false then leftrandom = math.clamp(leftrandom + math.random(-1,1), l_edge_min,l_edge_max) end
              elseif IsInvalidTileTerraformer(TheWorld.Map:GetTileAtPoint(posx+tilex*4, 0, posz+tiley*4+4*downrandom)) then
                water_tile= true
                if math.random() < 0.1 and water_tile == false then downrandom = math.clamp(downrandom + math.random(-1,1), d_edge_min,d_edge_max) end 
              elseif IsInvalidTileTerraformer(TheWorld.Map:GetTileAtPoint(posx+tilex*4, 0, posz+tiley*4-4*uprandom)) then
                water_tile= true
                if math.random() < 0.1 and water_tile == false then uprandom = math.clamp(uprandom + math.random(-1,1), u_edge_min,u_edge_max) end  
              elseif IsInvalidTileTerraformer(TheWorld.Map:GetTileAtPoint(posx+tilex*4+4*rightrandom, 0, posz+tiley*4-4*uprandom)) 
              or IsInvalidTileTerraformer(TheWorld.Map:GetTileAtPoint(posx+tilex*4-4*leftrandom, 0, posz+tiley*4-4*uprandom))
              or IsInvalidTileTerraformer(TheWorld.Map:GetTileAtPoint(posx+tilex*4+4*rightrandom, 0, posz+tiley*4+4*downrandom)) 
              or IsInvalidTileTerraformer(TheWorld.Map:GetTileAtPoint(posx+tilex*4-4*leftrandom, 0, posz+tiley*4+4*downrandom)) then
                water_tile= true
              end
            else

              water_tile = true 
            end

            -- Check if it is land. If so, checks if must go to the next island. Then transports it to the next level and replaces it with a special void type
            local x,y = TheWorld.Map:GetTileXYAtPoint(posx+tilex*4, posy, posz+tiley*4)
            local thistile = TheWorld.Map:GetTileAtPoint(posx+tilex*4, posy, posz+tiley*4)
            

            
            if IsMsTile(thistile) then
              if water_tile == false then
               
                
                -- first level needs to go to a specific spot, so it has separate logic.
                if inst.prefab == "terraformer_mountain_dungeon_level_1" then
                  local deltax, deltay = TheWorld.net.components.dungeonmapoverwatch:GetTileDiffForLevel(1)
                  TheWorld.Map:SetTile(x,y, WORLD_TILES.VOID_TECHNICAL)
                  SetTileOrNoiseOrNoise(tiles, tile_rarity, x-deltax+70,y-deltay+70, snow_randomseed, snow_rarity, level)
          
              else
                 TheWorld.Map:SetTile(x,y, WORLD_TILES.VOID_TECHNICAL)
                  SetTileOrNoiseOrNoise(tiles, tile_rarity, x+spawn_offset_x,y+spawn_offset_y, snow_randomseed, snow_rarity, level)
                end
              else
                
                if inst.prefab == "terraformer_mountain_dungeon_level_1" then
                  local deltax, deltay = TheWorld.net.components.dungeonmapoverwatch:GetTileDiffForLevel(1)
                  TheWorld.Map:SetTile(x,y, WORLD_TILES.VOID_TECHNICAL)
                  SetTileOrNoiseOrNoise(tiles, tile_rarity, x-deltax+70,y-deltay+70, snow_randomseed, snow_rarity, level)
                else
                  TheWorld.Map:SetTile(x+spawn_offset_x,y+spawn_offset_y, WORLD_TILES.CLOUDS_DARK)
                end
              end
            end
          end
          end
        end
    -- spawn the next one!
    --
    if inst.prefab == "terraformer_mountain_dungeon_level_1" then
      local next_terraformer_inst = SpawnPrefab("terraformer_mountain_dungeon_level_2")
      local x, y, z = inst:GetPosition():Get()
      local deltax, deltay = TheWorld.net.components.dungeonmapoverwatch:GetTileDiffForLevel(1)
      next_terraformer_inst.Transform:SetPosition(x-4*deltax+280, y, z-4*deltay+280)
    else
      if next_terraformer ~= nil then
        local next_terraformer_inst = SpawnPrefab(next_terraformer)
        local x, y, z = inst:GetPosition():Get()
        next_terraformer_inst.Transform:SetPosition(x+spawn_offset_x*4, y, z+4*spawn_offset_y)
      end
    end
    if level == 8 then
      
      

      TheWorld:PushEvent("terraforming_finished")
      inst:Remove()
    end
    inst:Remove()
  end)
  
    
return inst
end

return Prefab(name, fn, assets, prefabs)
end
-- 
return MakeTerraformer("terraformer_mountain_dungeon_level_1", {WORLD_TILES.MS_MOUNTAIN_LOW, WORLD_TILES.MS_MOUNTAIN_LOW_2}, 0.55, math.random(10000,20000), 1, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0), -- super-duper special case 
MakeTerraformer("terraformer_mountain_dungeon_level_2", {WORLD_TILES.MS_MOUNTAIN_LOW, WORLD_TILES.MS_MOUNTAIN_LOW_2}, 0.55, math.random(10000,20000), 1, 50, 3, 3, 4, 3, 4, 3, 4, 3, 4, "terraformer_mountain_dungeon_level_3", TUNING.MS_TERRAFORMER_OFFSET_X[2], TUNING.MS_TERRAFORMER_OFFSET_Y[2]),
MakeTerraformer("terraformer_mountain_dungeon_level_3", WORLD_TILES.MS_MOUNTAIN_HIGH, 0.55, math.random() * 100, 1, 40, 3, 2, 4, 2, 4, 2, 4, 2, 4, "terraformer_mountain_dungeon_level_4", TUNING.MS_TERRAFORMER_OFFSET_X[3], TUNING.MS_TERRAFORMER_OFFSET_Y[3]),
MakeTerraformer("terraformer_mountain_dungeon_level_4", WORLD_TILES.MS_MOUNTAIN_HIGH, 0.6, math.random(10000,20000), 1, 35, 3, 1, 3, 1, 3, 1, 3, 1, 3, "terraformer_mountain_dungeon_level_5", TUNING.MS_TERRAFORMER_OFFSET_X[4], TUNING.MS_TERRAFORMER_OFFSET_Y[4]),
MakeTerraformer("terraformer_mountain_dungeon_level_5", WORLD_TILES.MS_MOUNTAIN_HIGH, 0.6, math.random(10000,20000), 0.7, 30, 3, 1, 3, 1, 3, 1, 3, 1, 3, "terraformer_mountain_dungeon_level_6",  TUNING.MS_TERRAFORMER_OFFSET_X[5], TUNING.MS_TERRAFORMER_OFFSET_Y[5]),

MakeTerraformer("terraformer_mountain_dungeon_level_6", WORLD_TILES.MS_PERMAFROST, 0.6, math.random(10000,20000), 0.4, 25, 2, 1, 2, 1, 2, 1, 2, 1, 2, "terraformer_mountain_dungeon_level_7",  TUNING.MS_TERRAFORMER_OFFSET_X[6], TUNING.MS_TERRAFORMER_OFFSET_Y[6]),
MakeTerraformer("terraformer_mountain_dungeon_level_7", WORLD_TILES.MS_PERMAFROST, 0.4, math.random(10000,20000), 0.2, 20, 2, 1, 2, 1, 2, 1, 2, 1, 2, "terraformer_mountain_dungeon_level_8",  TUNING.MS_TERRAFORMER_OFFSET_X[7], TUNING.MS_TERRAFORMER_OFFSET_Y[7]),
MakeTerraformer("terraformer_mountain_dungeon_level_8", WORLD_TILES.MS_PERMAFROST, 0.4, math.random(10000,20000), 0.1, -100, 0, 20,20,20,20,20,20,20,20, nil,  TUNING.MS_TERRAFORMER_OFFSET_X[8], TUNING.MS_TERRAFORMER_OFFSET_Y[8])