

local DungeonWallSpawner = Class(function(self, inst)
    self.inst = inst
    self.walls = {}
    self.cave_doors = {}
    self.exits = {}
  end)

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


function DungeonWallSpawner:SpawnMainEntrance()
  local center_x, center_y = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(2)
  local success
  while success ~= true do
    local x = center_x+math.random(-50, 50)*4
    local z = center_y+math.random(-50, 50)*4
    if IsMsTile(TheWorld.Map:GetTileAtPoint(x, 0, z)) then
      self.exits[2] = SpawnPrefab("ms_worldmigrator_up")
      self.exits[2].Transform:SetPosition(x,0,z)
      success = true
    end
  end
end

function DungeonWallSpawner:SpawnArenaTeleporter()
  local center_x, center_y = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(8)
  local success
  -- First, find a point at level 8 that is far enough from entrance to level.
  local attempts = 100
  while success ~= true and attempts > 0 do
    attempts = attempts - 1
    local x = center_x+math.random(-50, 50)
    local z = center_y+math.random(-50, 50)
    -- FUCK YOU YOU FUCKING PIECE OF SHIT! GET YOUR FUCKING EMERGERCY EXIT AND SHUIT UP AND STOP GETTING MY FUCKING CAVES_SERVER_LOG OVER 1 FUCKING GIGABYTE!!!!
    if attempts <= 0 then x,z = center_x, center_y end
    if (IsMsTile(TheWorld.Map:GetTileAtPoint(x, 0, z)) and self.exits[8]:GetDistanceSqToPoint(x,0,z) > 128) or attempts <= 0 then
      local tile_x, tile_z = TheWorld.Map:GetTileXYAtPoint(x, 0, z)
      for i = -50, 50 do 
        for j = -50, 50 do
          if TheWorld.Map:GetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8]) == 1 and math.sqrt(i*i+j*j) < 50 then
            TheWorld.Map:SetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8], WORLD_TILES.CLOUDS_WHITE)  
          end
        end
      end
          
      for i = -1, 1 do 
        for j = -1, 1 do
          TheWorld.Map:SetTile(tile_x + i, tile_z + j, WORLD_TILES.VOID_TECHNICAL) 
          TheWorld.Map:SetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8], WORLD_TILES.MS_PERMAFROST)
        end
      end
      local light = SpawnPrefab("light_fake_overworld")
      light.Transform:SetPosition(x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4, 0, z + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4) 
      for i = -3, 3 do
        for j = -3, 3 do 
          local plug = SpawnPrefab("giant_plug_marker")
          plug.Transform:SetPosition(x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + i*16.66*4, 0, z + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4+j*16.66*4)  
        end
      end
      
      success = true
    end
  end

  -- Now spawn the arena.
  local arena_width = { 4, 5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 6, 5, 4 }
  local tile_x, tile_z = TheWorld.Map:GetTileXYAtPoint(center_x, 0, center_y)
  for i = -50, 50 do 
    for j = -50, 50 do
      if TheWorld.Map:GetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9] ) == 1 and math.sqrt(i*i+j*j) < 50 then
          TheWorld.Map:SetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9], WORLD_TILES.CLOUDS_WHITE)  
      end
    end
  end
  for i = -7, 7 do 
    for j = -arena_width[i+8], arena_width[i+8] do
      TheWorld.Map:SetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9], WORLD_TILES.MS_PERMAFROST) 
    end
  end
  local light = SpawnPrefab("light_fake_overworld")
  light.Transform:SetPosition(center_x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_X[9] * 4, 0, center_y + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_Y[9] * 4)   
  for i = -3, 3 do
    for j = -3, 3 do 
      local plug = SpawnPrefab("giant_plug_marker")
      plug.Transform:SetPosition(center_x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_X[9] * 4 + i*16.66*4, 0, center_y + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_Y[9] * 4 + j*16.66*4)  
    end
  end
  success = nil
  -- Spawn the teleporter to and from arena. 
  attempts = 100
  while success ~= true and attempts <= 0 do

    local x = center_x+math.random(-200, 200)
    local y
    local z = center_y+math.random(-200, 200)
    print("TRYING TO GENERATE TELEPORTER",x,z, TheWorld.Map:GetTileAtPoint(x, 0, z)) 
    if attempts <= 0 then x,y,z = self.exits[8].Transform:GetWorldPosition() end
    if (TileGroupManager:IsLandTile(TheWorld.Map:GetTileAtPoint(x, 0, z)) and not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(x, 0, z))) or attempts <= 0 then
      local teleporter = SpawnPrefab("ms_arenateleporter")
      local exit = SpawnPrefab("ms_arenateleporter_exit")
      exit.Transform:SetPosition(center_x + 4 + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_X[9] * 4 ,0, center_y + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_Y[9]*4)
      TheWorld.Map:SetTile(TheWorld.Map:GetTileXYAtPoint(x+1,0,z), WORLD_TILES.MS_PERMAFROST)
      teleporter.Transform:SetPosition(x,0,z)
      exit:SetExitTarget(teleporter)
      teleporter:SetExitTarget(exit)
      success = true
    end
  end
end

function DungeonWallSpawner:SpawnWallsAroundPoint(level, wall, size, technical_tile)
  local center_x, center_y = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(level)
  print("POINT IS", TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(level))
  center_x = center_x
  center_y = center_y


  -- First, we check for holes, cavities and other stuff that messes our wall placement.
  for x = -size, size do 
    for y = -size, size do

      if IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4, 0, center_y+y*4)) then
        local l,r,d,u,ld,lu,rd,ru = nil, nil, nil, nil, nil, nil, nil, nil
        -- Check neaby tiles
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 + 4, 0, center_y+y*4)) then 
          r = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 - 4, 0, center_y+y*4)) then 
          l = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4, 0, center_y+y*4 + 4)) then 
          d = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4, 0, center_y+y*4 - 4)) then
          u = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 + 4, 0, center_y+y*4 + 4)) then 
          ru = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 + 4, 0, center_y+y*4 - 4)) then 
          rd = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 - 4, 0, center_y+y*4+4)) then 
          lu = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 - 4, 0, center_y+y*4-4)) then 
          ld = 1
        end
        local tile_x, tile_y = TheWorld.Map:GetTileXYAtPoint(center_x+x*4, 0, center_y+y*4)

        if r or l or d or u or rd or ld or lu or ru then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
        if l and d and r and u then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
        -- for 1 tile intrusions that do not fit with out wall generating algorythm
        if  (r and l and u and (ld or rd)) then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
        if (r and l and d and (lu or ru)) then 
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
        if (u and l and d and (ru or rd)) then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
        if (r and u and d and (lu or ld)) then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
        if (u and d and not r and not l) then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
        if (r and l and not u and not d) then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)


        end

      end  
    end
  end

  -- Some variables for exits and entrance spawns
  local spawned 
  local spawned_cave_entrance 
  local last_entrance_x, last_entrance_y, last_exit_x, last_exit_y = center_x,center_y,center_x+TUNING.MS_TERRAFORMER_OFFSET_X[level]*4,center_y+TUNING.MS_TERRAFORMER_OFFSET_Y[level]*4 

  for x = -size, size do 
    for y = -size, size do

      if IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4, 0, center_y+y*4)) then
        local l,r,d,u,ld,lu,rd,ru = 0,0,0,0,0,0,0,0
        -- Check neaby tiles
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 + 4, 0, center_y+y*4)) then 
          r = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 - 4, 0, center_y+y*4)) then 
          l = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4, 0, center_y+y*4 + 4)) then 
          d = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4, 0, center_y+y*4 - 4)) then
          u = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 + 4, 0, center_y+y*4 + 4)) then 
          ru = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 + 4, 0, center_y+y*4 - 4)) then 
          rd = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 - 4, 0, center_y+y*4+4)) then 
          lu = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(center_x+x*4 - 4, 0, center_y+y*4-4)) then 
          ld = 1
        end
        print("INFO DUMP", center_x+x*4, 0, center_y+y*4, r,l,d,u,ld,lu,rd,ru)


        if (ru == 1 or rd == 1 or lu == 1 or ld == 1) and l == 0 and r == 0 and u == 0 and d == 0 then
          local new_wall_r = SpawnPrefab("ms_mountain_corner_wall_right" .. wall)
          new_wall_r.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
          local new_wall_l = SpawnPrefab("ms_mountain_corner_wall_left" .. wall)
          new_wall_l.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
          if ru == 1 then
            new_wall_r.Transform:SetRotation(270)
            new_wall_l.Transform:SetRotation(180)
            new_wall_l.debuginfo = "outer_ru"
          end
          if rd == 1 then
            new_wall_r.Transform:SetRotation(90)
            new_wall_l.Transform:SetRotation(180)
            new_wall_l.debuginfo = "outer_rd"
          end 
          if lu == 1 then
            new_wall_r.Transform:SetRotation(270)
            new_wall_l.Transform:SetRotation(0)
            new_wall_l.debuginfo = "outer_lu"
          end 
          if ld == 1 then
            new_wall_r.Transform:SetRotation(90)
            new_wall_l.Transform:SetRotation(0)
            new_wall_l.debuginfo = "outer_ld"
          end 
        elseif u+r+l+d > 2 then 
          -- Handling case where we have walls from 3 sides. 
          local new_slope = SpawnPrefab("ms_mountain_slope" .. wall)
          local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
          new_slope.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
          if l == 1 and d == 1 and u == 1 then
            new_slope.Transform:SetRotation(90)
            new_wall.Transform:SetPosition(center_x+x*4 + 4 , 0, center_y+y*4)
            new_wall.Transform:SetRotation(90)
          elseif r == 1 and d == 1 and u == 1 then
            new_slope.Transform:SetRotation(270)
            new_wall.Transform:SetPosition(center_x+x*4 - 4 , 0, center_y+y*4)
            new_wall.Transform:SetRotation(90)
          elseif l == 1 and r == 1 and u == 1 then
            new_slope.Transform:SetRotation(0)
            new_wall.Transform:SetPosition(center_x+x*4, 0, center_y+y*4 + 4)
          else
            new_slope.Transform:SetRotation(180)
            new_wall.Transform:SetPosition(center_x+x*4, 0, center_y+y*4 - 4)
          end
        elseif u+r+l+d > 1 then 
          local new_wall_r = SpawnPrefab("ms_mountain_corner_wall_right" .. wall)
          new_wall_r.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
          local new_wall_l = SpawnPrefab("ms_mountain_corner_wall_left" .. wall)
          new_wall_l.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
          new_wall_l.Transform:SetRotation(90)
          print("corner", center_x+x*4 , 0, center_y+y*4, r,l,d,u) 
          TheWorld.net.components.dungeonmapoverwatch:AddSpawnPointsForWall(level, center_x+x*4, center_y+y*4, r-l, d-u)
          if l == 1 and d == 1 then


            new_wall_r.Transform:SetRotation(90)
            new_wall_l.Transform:SetRotation(180)
          end
          if l == 1 and u == 1 then

            new_wall_r.Transform:SetRotation(0)
            new_wall_l.Transform:SetRotation(90)
          end
          if r == 1 and d == 1 then


            new_wall_r.Transform:SetRotation(180)
            new_wall_l.Transform:SetRotation(270)
          end
          if r == 1 and u == 1 then


            new_wall_r.Transform:SetRotation(270)
            new_wall_l.Transform:SetRotation(0)
          end
        else
          -- Check if we should spawn an entrance to the next level. More distance = more chance.
          if (l == 1 or r == 1 or d == 1 or u == 1)  then
            TheWorld.net.components.dungeonmapoverwatch:AddSpawnPointsForWall(level, center_x+x*4, center_y+y*4, r-l, d-u)
            if not spawned then
              last_entrance_x, last_entrance_y, last_exit_x, last_exit_y = center_x+x*4 - l * 4 + r * 4, center_y+y*4 - u * 4 + d * 4, center_x+x*4 + TUNING.MS_TERRAFORMER_OFFSET_X[level]*4, center_y+y*4+ TUNING.MS_TERRAFORMER_OFFSET_Y[level] * 4
              if math.random() < self.exits[level]:GetDistanceSqToPoint(center_x+x*4, 0, center_y+y*4)/(TUNING.MS_TERRAFORMER_SIZE[level] * TUNING.MS_TERRAFORMER_SIZE[level] * 16 * 10) then
                local entrance = SpawnPrefab("ms_climbing")
                entrance.Transform:SetPosition(center_x+x*4 - l * 4 + r * 4, 0, center_y+y*4 - u * 4 + d * 4)
                self.exits[level+1] = SpawnPrefab("ms_climbing_down")
                self.exits[level+1].Transform:SetPosition(center_x+x*4 + l - r + TUNING.MS_TERRAFORMER_OFFSET_X[level]*4, 0, center_y+y*4 + u - d +  TUNING.MS_TERRAFORMER_OFFSET_Y[level]*4)
                entrance:SetExitTarget(self.exits[level+1])
                self.exits[level+1]:SetExitTarget(entrance)
                spawned = true
              end
            end
            if not spawned_cave_entrance then
              if math.random() < self.exits[level]:GetDistanceSqToPoint(center_x+x*4- l * 4 + r * 4, 0, center_y+y*4+ (-u * 4 + d * 4)*(r-1)*(l-1))/(TUNING.MS_TERRAFORMER_SIZE[level] * TUNING.MS_TERRAFORMER_SIZE[level] * 16 * 10) and self.cave_doors[level] then
                local entrance = SpawnPrefab("ms_cave_entrance_vertical")
                entrance.Transform:SetPosition(center_x+x*4, 0, center_y+y*4)
                entrance.Transform:SetRotation(r>0 and 90 or (l>0 and 270 or (u and 180 or 0))) 
                entrance:SetExitTarget(self.cave_doors[level])
                entrance.components.teleporter.teleport_offset = {x = r * 4 - l *4, y= 0, z = d*4 - u *4}
                self.cave_doors[level]:SetExitTarget(entrance)
                spawned_cave_entrance = true
              end
            end
          end
          if r == 1 then 
            local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
            new_wall.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
            new_wall.Transform:SetRotation(90)
            new_wall.debuginfo = {center_x+x*4 , 0, center_y+y*4, "+x"}
            print(center_x+x*4+4 , 0, center_y+y*4, "+x")
          end
          if l == 1 then 
            local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
            new_wall.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
            new_wall.Transform:SetRotation(90)
            new_wall.debuginfo = {center_x+x*4 , 0, center_y+y*4, "-x"}
            print(center_x+x*4 - 4 , 0, center_y+y*4, "-x")
          end
          if d == 1 then 
            local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
            new_wall.Transform:SetPosition(center_x+x*4, 0, center_y+y*4)
            new_wall.Transform:SetRotation(0)
            new_wall.debuginfo = {center_x+x*4, 0, center_y+y*4, "+y"}
            print(center_x+x*4, 0, center_y+y*4+4, "+y")
          end
          if u == 1 then
            local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
            new_wall.Transform:SetPosition(center_x+x*4, 0, center_y+y*4)
            new_wall.Transform:SetRotation(0)
            new_wall.debuginfo = {center_x+x*4, 0, center_y+y*4, "-y"}
            print(center_x+x*4, 0, center_y+y*4-4, "-y")
          end

        end  
      end  
    end
  end

  if not spawned then
    local entrance = SpawnPrefab("ms_climbing")
    entrance.Transform:SetPosition(last_entrance_x, 0, last_entrance_y)
    self.exits[level+1] = SpawnPrefab("ms_climbing_down")
    self.exits[level+1].Transform:SetPosition(last_exit_x, 0, last_exit_y)
    entrance:SetExitTarget(self.exits[level+1])
    self.exits[level+1]:SetExitTarget(entrance)
  end
end

local type_to_points = {
  ["tri"] = {{13,-9}, {0,0}, {-13,-9}, {-13,-20}, {13,-20}, {13,-9}},
  ["round"] = {{-13,-8}, {-7,0}, {7,0}, {13,-8}, {13,-20}, {-13,-20}, {-13,-8}},
  ["rect"] = {{-13,0}, {13,0}, {13,-20}, {-13,-20}, {-13,0}},
}

local layour_door_coords = {
  ["tri"] = {["right"] = {13.5, -15}, ["left"] = {-13.5, -15}, ["up"] = {0,0}, ["down"] = {0, -22}},
  ["round"] = {["right"] = {13.5, -15}, ["left"] = {-13.5, -15}, ["up"] = {0,0}, ["down"] = {0, -22}},
  ["rect"] = {["right"] = {13.5, -11}, ["left"] = {-13.5, -11}, ["up"] = {0,0}, ["down"] = {0, -22}},
}

--Luigi: about 30 points should be enough. Also, this does not work for non-convex shapes, if that ever comes up.
local function addmobpointsforcaves(level,x,y,r,l,d,u,floor_type)
  for i=1, 30 do
    local point = {math.random() * 26 - 13, -math.random() * 20}
    local valid = true
    for j=1, #type_to_points[floor_type]-1 do
      if math2d.LineIntersectsLine(type_to_points[floor_type][j][1], type_to_points[floor_type][j][2], type_to_points[floor_type][j+1][1], type_to_points[floor_type][j+1][2],
        point[1], point[2], 0, -10.75) then
        valid = false
      end
    end
    if r and math2d.DistSq(point[1], point[2], layour_door_coords[floor_type]["right"][1], layour_door_coords[floor_type]["right"][2]) < 16 then valid = false end
    if l and math2d.DistSq(point[1], point[2], layour_door_coords[floor_type]["left"][1], layour_door_coords[floor_type]["left"][2]) < 16 then valid = false end
    if d and math2d.DistSq(point[1], point[2], layour_door_coords[floor_type]["down"][1], layour_door_coords[floor_type]["down"][2]) < 16 then valid = false end
    if u and math2d.DistSq(point[1], point[2], layour_door_coords[floor_type]["up"][1], layour_door_coords[floor_type]["up"][2]) < 16 then valid = false end
    if valid then
      TheWorld.net.components.dungeonmapoverwatch:AddSpawnPointsForCave(level, x+point[1], y+point[2])
    else
      i = i -1
    end
  end
end

local function checkcoordsexits(x,y, cords)
  for k, v in pairs(cords) do
    if v[1] == x and v[2] == y then
      return true
    end
  end
  return false

end

local function spawndoors(x,y, x1, y1, angle)
  local door = SpawnPrefab("ms_cave_entrance")
  door.Transform:SetPosition(x,0,y)
  door.Transform:SetRotation(angle)
  door.components.teleporter.teleport_offset = {x = math.cos(angle)*2, y = 0, z=math.sin(angle)*-2}
  local door1 = SpawnPrefab("ms_cave_exit")
  local angle2 = angle + 180 < 360 and angle + 180 or angle-180
  door1.Transform:SetPosition(x1,0,y1)
  door1.Transform:SetRotation(angle2)
  door1.components.teleporter.teleport_offset = {x = math.cos(angle2)*2, y = 0, z=math.sin(angle2)*-2}
  door:SetExitTarget(door1)
  door1:SetExitTarget(door)
end


function DungeonWallSpawner:SpawnCaveLayout(start_x, start_y, amount, level, loottable)
  local ready = false
  local remaining_amount = amount
  local cords = {{start_x, start_y}}

  self.cave_doors[level] = SpawnPrefab("ms_cave_exit_light")
  self.cave_doors[level].Transform:SetPosition(start_x + layour_door_coords["rect"]["down"][1], 0, start_y + layour_door_coords["rect"]["down"][2])
  self.cave_doors[level].Transform:SetRotation(270)
  self.cave_doors[level].components.teleporter.teleport_offset = {x = 0, y = 0, z=2}

  for k,v in pairs(cords) do
    print(v[1], v[2])
    local center_x, center_y = TheWorld.Map:GetTileXYAtPoint(v[1], 0, v[2])

    for i = -3, 3 do 
      for j = -5, 0 do
        if TheWorld.Map:GetTile(center_x + i, center_y + j) == 1 then
          TheWorld.Map:SetTile(center_x + i, center_y + j, WORLD_TILES.MS_CAVE_FLOOR)  
        end
      end
    end 
    for i = -8, 8 do 
      for j = -8, 8 do
        if TheWorld.Map:GetTile(center_x + i, center_y + j) == 1 then
          TheWorld.Map:SetTile(center_x + i, center_y + j, WORLD_TILES.VOID_TECHNICAL)  
        end
      end
    end 
    remaining_amount = remaining_amount - 1
    local layout = math.random()> 0.66 and "round" or (math.random()>0.5 and  "rect" or "tri")
    local floor = SpawnPrefab("cave_floor_7x5_" .. layout) 
    local marker = SpawnPrefab("giant_plug_marker")

    marker.Transform:SetPosition(v[1], 0, v[2])
    floor.Transform:SetPosition(v[1], 0, v[2])

    local right, left, up = nil, nil, nil
    if remaining_amount > 1 and math.random()>0.5 and checkcoordsexits(v[1]+60, v[2], cords) == false then
      right = true
      remaining_amount = remaining_amount - 1
      table.insert(cords, {v[1]+60, v[2]})
      spawndoors(v[1]+layour_door_coords[layout]["right"][1], v[2]+layour_door_coords[layout]["right"][2], v[1] + 60 + layour_door_coords[layout]["left"][1], v[2]+layour_door_coords[layout]["left"][2], 180)
    end
    if remaining_amount > 1 and math.random()>0.5 and checkcoordsexits(v[1], v[2]+60, cords) == false and layout ~= "tri" then
      up = true
      remaining_amount = remaining_amount - 1
      table.insert(cords, {v[1], v[2]+60})
      spawndoors(v[1]+layour_door_coords[layout]["up"][1], v[2]+layour_door_coords[layout]["up"][2], v[1] + layour_door_coords[layout]["down"][1], v[2] + 60 + layour_door_coords[layout]["down"][2], 90)
    end
    if remaining_amount > 1 and checkcoordsexits(v[1]-60, v[2], cords) == false and (math.random()>0.5 or (not up and not right)) then
      left = true
      remaining_amount = remaining_amount - 1
      table.insert(cords, {v[1]-60, v[2]})
      spawndoors(v[1]+layour_door_coords[layout]["left"][1], v[2]+layour_door_coords[layout]["left"][2], v[1] - 60 + layour_door_coords[layout]["right"][1], v[2]+layour_door_coords[layout]["right"][2], 0)
    end

    addmobpointsforcaves(level, v[1], v[2],
      TheSim:FindEntities(v[1] + layour_door_coords[layout]["right"][1], 0, v[2] + layour_door_coords[layout]["right"][2], 2, {"ms_teleporter"}) ~= nil,
      TheSim:FindEntities(v[1] + layour_door_coords[layout]["left"][1], 0, v[2] + layour_door_coords[layout]["left"][2], 2, {"ms_teleporter"}) ~= nil,
      TheSim:FindEntities(v[1] + layour_door_coords[layout]["down"][1], 0, v[2] + layour_door_coords[layout]["down"][2], 2, {"ms_teleporter"}) ~= nil,
      TheSim:FindEntities(v[1] + layour_door_coords[layout]["up"][1], 0, v[2] + layour_door_coords[layout]["up"][2], 2, {"ms_teleporter"}) ~= nil,
      layout)
  end
end

return DungeonWallSpawner