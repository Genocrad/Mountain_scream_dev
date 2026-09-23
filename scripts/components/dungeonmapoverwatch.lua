

local DungeonMapOverwatch = Class(function(self, inst)
    self.inst = inst
    
    self.terraformers_points = {}
    self.level_limits_xp = {}
    self.level_limits_xn = {}
    self.level_limits_yn = {}
    self.level_limits_yp = {}
    self.exits = {}
    self.mob_spawn_points = {}
    self.wall_spawn_points = {}
    self.mob_spawn_points_near_walls = {} 
    
    for i = 1, 20 do 
      self.level_limits_xp[i] = 0
      self.level_limits_xn[i] = 0
      self.level_limits_yn[i] = 0
      self.level_limits_yp[i] = 0
      self.terraformers_points[i] = {}
      self.exits[i] = nil
      self.mob_spawn_points[i] = {}
      self.wall_spawn_points[i] = {} -- Not for walls, but on the walls
      self.mob_spawn_points_near_walls[i] = {} -- if we ever want to have something that spawns only near the walls, like fallen boulders or something.
    end
  
    local map = TheWorld.Map
    self.map_width, self.map_height = map:GetSize()
    
    self.cloud_tiles_planned_cords = {} 
    
    for i = -20, self.map_width do
      self.cloud_tiles_planned_cords[i] = {}
       for j = -20, self.map_height do
        self.cloud_tiles_planned_cords[i][j] = false 
      end
    end
    
    self.map_points_level_x = {}
    self._map_points_level_x = net_ushortarray(inst.GUID, "dungeonmapoverwatch._map_points_level_x") -- Arrays are expensive, and we do not need precise cords, really.
    
     self.map_points_level_y = {}
    self._map_points_level_y = net_ushortarray(inst.GUID, "dungeonmapoverwatch._map_points_level_y") -- Arrays are expensive, and we do not need precise cords, really.
    
    self._level_limits_xp = net_ushortarray(inst.GUID, "dungeonmapoverwatch._level_limits_xp") 
    self._level_limits_xn = net_ushortarray(inst.GUID, "dungeonmapoverwatch._level_limits_xn") 
    self._level_limits_yn = net_ushortarray(inst.GUID, "dungeonmapoverwatch._level_limits_yn") 
    self._level_limits_yp = net_ushortarray(inst.GUID, "dungeonmapoverwatch._level_limits_yp") 
    self._base_cave_bounds = net_ushortarray(inst.GUID, "dungeonmapoverwatch._base_cave_bounds")
    self._has_base_cave_bounds = net_bool(inst.GUID, "dungeonmapoverwatch._has_base_cave_bounds")

    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("dungeonmapoverwatch")
    
    if TheWorld.ismastersim then
      -- Capture the generated cave map before the runtime terraformer chain
      -- stamps the synthetic floor maps into it. This is the cave world's own
      -- terrain region; it is not floor 1 (which is also used as a terraformer
      -- anchor by the generated floor layout).
      local min_tile_x, max_tile_x, min_tile_y, max_tile_y
      for tile_x = 0, self.map_width - 1 do
        for tile_y = 0, self.map_height - 1 do
          local tile = map:GetTile(tile_x, tile_y)
          if tile ~= nil and tile ~= 1 and
             tile ~= WORLD_TILES.VOID_TECHNICAL and
             tile ~= WORLD_TILES.CLOUDS_WHITE and
             tile ~= WORLD_TILES.CLOUDS_DARK and
             TileGroupManager:IsLandTile(tile) then
            min_tile_x = min_tile_x == nil and tile_x or math.min(min_tile_x, tile_x)
            max_tile_x = max_tile_x == nil and tile_x or math.max(max_tile_x, tile_x)
            min_tile_y = min_tile_y == nil and tile_y or math.min(min_tile_y, tile_y)
            max_tile_y = max_tile_y == nil and tile_y or math.max(max_tile_y, tile_y)
          end
        end
      end

      if min_tile_x ~= nil then
        self.base_cave_bounds = { min_tile_x, max_tile_x, min_tile_y, max_tile_y }
        self._base_cave_bounds:set(self.base_cave_bounds)
        self._has_base_cave_bounds:set(true)
        print(string.format(
          "[MS BaseCaveBounds] captured initial cave terrain tiles=[x %d..%d, y %d..%d] map_size=(%d,%d)",
          min_tile_x, max_tile_x, min_tile_y, max_tile_y, self.map_width, self.map_height))
      end

      self.map_points_level_x[1] = 0
      self.map_points_level_y[1] = 0
      self.map_points_level_x[2] = 70
      self.map_points_level_y[2] = 70
    
      -- Caves have no terraformer, set manually instead
      self.level_limits_xp[9] = 20
      self.level_limits_xn[9] = 20
      self.level_limits_yn[9] = 20
      self.level_limits_yp[9] = 20
      self.level_limits_xp[10] = 20
      self.level_limits_xn[10] = 20
      self.level_limits_yn[10] = 20
      self.level_limits_yp[10] = 20
      self.level_limits_xp[11] = 50
      self.level_limits_xn[11] = 50
      self.level_limits_yn[11] = 50
      self.level_limits_yp[11] = 50
      self.level_limits_xp[12] = 50
      self.level_limits_xn[12] = 50
      self.level_limits_yn[12] = 50
      self.level_limits_yp[12] = 50 
      
      self._level_limits_xp:set({0, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50})
      self._level_limits_xn:set({0, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50})
      self._level_limits_yp:set({0, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50})
      self._level_limits_yn:set({0, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50})
      
      for i = 3, #TUNING.MS_TERRAFORMER_OFFSET_X do
        self.map_points_level_x[i] = self.map_points_level_x[i-1] +TUNING.MS_TERRAFORMER_OFFSET_X[i-1]
        self.map_points_level_y[i] = self.map_points_level_y[i-1] +TUNING.MS_TERRAFORMER_OFFSET_Y[i-1]
      end
      
      self._map_points_level_y:set(self.map_points_level_y)
      self._map_points_level_x:set(self.map_points_level_x)
      
    end
end)

-- Spawn points 

function DungeonMapOverwatch:AddSpawnPointsForCave(level,x,y)
  table.insert(self.mob_spawn_points[level], {x = x, y = y})
end

function DungeonMapOverwatch:AddSpawnPointsForTile(level,tile_x,tile_y)
  local x,y = -self.map_width*2+tile_x*4, -self.map_height*2+tile_y*4
  for i = 1, math.random(1,5) do
    table.insert(self.mob_spawn_points[level], {x = x + math.random()*4 - 2, y = y + math.random()*4 - 2})
  end
end

function DungeonMapOverwatch:GetMobSpawnPoints(level)
  return self.mob_spawn_points[level]
end

function DungeonMapOverwatch:GetOnWallSpawnPoints(level)
  return self.wall_spawn_points[level]
end

function DungeonMapOverwatch:AddPointForWall(level,x,y,angle)
  table.insert(self.wall_spawn_points[level], {x =  x, y = 2 + math.random() * 2, z = y, angle = angle})
end

function DungeonMapOverwatch:AddSpawnPointsForWall(level,x,y,dx,dy,isfull)
  for i = 1, math.random(1,3) do
    -- Luigi: If this is a full wall, we allow objects to spawn from -1 to 1, if not 0 to 1
    if isfull then
      table.insert(self.wall_spawn_points[level], {x = dx ~= 0 and x + dx/2 or x + math.random()*2 - 1, y = 5 + math.random() * 6, z = dy ~= 0 and y + dy/2 or y + math.random()*2 - 1,
                 angle = dx == 1 and 0 or (dx== -1 and 180 or (dy == -1 and 90 or 270))})
    else 
      -- As corners have both dx and dy, choose one of them.
      if math.random() > 0.5 then
        table.insert(self.wall_spawn_points[level], {x =  x + dx/2, y = 5 + math.random() * 6, z = y - dy - dy * math.random(),
                 angle = dx == 1 and 0 or 180})
      else
        table.insert(self.wall_spawn_points[level], {x = x - dx - dx * math.random(), y = 5 + math.random() * 6, z = y + dy/2,
                 angle = dy == -1 and 90 or 270})
      end
    end
  
  end
  if dx~=0 and dy~= 0 then
    for i = 1, math.random(1,3) do
      local x_or_y = math.random()>0.5 and 1 or 0 
      table.insert(self.mob_spawn_points_near_walls[level], {x =  x + (-math.random()*2*dx + dx*2)*x_or_y + (dx*2 + math.random() * 4) * (1 - x_or_y), 
                                                             y =  y + (-math.random()*2*dy + dy*2)*(1-x_or_y) + (dy*2 + math.random() * 4) * x_or_y})
    end
  else
    for i = 1, math.random(1,3) do
      table.insert(self.mob_spawn_points_near_walls[level], {x = dx ~= 0 and x + math.random()*2*dx + dx*2 or x-2+math.random()*4, y = dy ~= 0 and y + math.random()*2 * dy + dy * 2 or y-2+math.random()*4})
    end
  end
end

-- Map stuff

function DungeonMapOverwatch:AddPoint(level, x, y)
    if self.terraformers_points[level] then
      table.insert(self.terraformers_points[level], {x,y})
    end
end

function DungeonMapOverwatch:GetPointForLevel(level)
    -- Prefer live terraformer centroid when available (any floor, not only level 1).
    if self.terraformers_points[level] and #self.terraformers_points[level] > 0 then
      local x = 0
      local y = 0
      for _, v in pairs(self.terraformers_points[level]) do
        x = x + v[1]
        y = y + v[2]
      end
      x = x / #self.terraformers_points[level]
      y = y / #self.terraformers_points[level]
      if level == 1 and self.map_points_level_x[level] == 0 then
        local tile_x, tile_y = TheWorld.Map:GetTileXYAtPoint(x, 0, y)
        self.map_points_level_x[level] = tile_x
        self.map_points_level_y[level] = tile_y
        self._map_points_level_y:set(self.map_points_level_y)
        self._map_points_level_x:set(self.map_points_level_x)
      end
      return x, y
    end

    local xs = self._map_points_level_x:value()
    local ys = self._map_points_level_y:value()
    if xs == nil or ys == nil or xs[level] == nil or ys[level] == nil then
      return nil, nil
    end
    return -self.map_width * 2 + xs[level] * 4, -self.map_height * 2 + ys[level] * 4
end

function DungeonMapOverwatch:GetBoundsForLevel(level)
    local center_x, center_z = self:GetPointForLevel(level)
    if center_x == nil or center_z == nil then
      return nil, nil, nil, nil
    end

    local limits_xp = self._level_limits_xp:value()
    local limits_xn = self._level_limits_xn:value()
    local limits_yp = self._level_limits_yp:value()
    local limits_yn = self._level_limits_yn:value()
    if limits_xp == nil or limits_xn == nil or limits_yp == nil or limits_yn == nil or
       limits_xp[level] == nil or limits_xn[level] == nil or
       limits_yp[level] == nil or limits_yn[level] == nil then
      return nil, nil, nil, nil
    end

    -- The limits are stored in map tiles. Keep this conversion in sync with
    -- GetNearestLevel: four world units per tile and the same 8-unit margin.
    return center_x - limits_xn[level] * 4 - 8,
           center_x + limits_xp[level] * 4 + 8,
           center_z - limits_yn[level] * 4 - 8,
           center_z + limits_yp[level] * 4 + 8
end

function DungeonMapOverwatch:GetBoundsForBaseCave()
    if not self._has_base_cave_bounds:value() then
      return nil, nil, nil, nil
    end

    local bounds = self._base_cave_bounds:value()
    if bounds == nil or #bounds < 4 then
      return nil, nil, nil, nil
    end

    -- Stored as the min/max initial map tile coordinates. Convert tile centers
    -- to world coordinates and leave the same small edge margin as floor bounds.
    return -self.map_width * 2 + bounds[1] * 4 - 8,
           -self.map_width * 2 + bounds[2] * 4 + 8,
           -self.map_height * 2 + bounds[3] * 4 - 8,
           -self.map_height * 2 + bounds[4] * 4 + 8
end


function DungeonMapOverwatch:GetTileDiffForLevel(level)
    if self.terraformers_points[level] then
      local x = 0
      local y = 0
      for k, v in pairs(self.terraformers_points[level]) do
        x = x + v[1]
        y = y + v[2]
      end
      local tile_x,tile_y = TheWorld.Map:GetTileXYAtPoint(x/#self.terraformers_points[level], 0, y/#self.terraformers_points[level])
      return tile_x, tile_y
    end
end 

function DungeonMapOverwatch:GetNearestLevel(x,y,z)
  local xs = self._map_points_level_x:value()
  if xs == nil or #xs < 1 then
    return nil
  end

  local best_level = nil
  local best_min = math.huge
  local best_min_x = math.huge
  local best_min_z = math.huge

  for i = 1, #xs do
    local point_x, point_y = self:GetPointForLevel(i)
    if point_x ~= nil and point_y ~= nil then
      local dx = x - point_x
      local dz = z - point_y
      local distsq = dx * dx + dz * dz
      if distsq < best_min then
        best_min = distsq
        best_level = i
        best_min_x = dx
        best_min_z = dz
      end
    end
  end

  -- Square territory per floor (not circle).
  if best_level ~= nil and 
     best_min_x < self._level_limits_xp:value()[best_level]*4 + 8 and
     best_min_x > -self._level_limits_xn:value()[best_level]*4 - 8 and
     best_min_z < self._level_limits_yp:value()[best_level]*4 + 8 and
     best_min_z > -self._level_limits_yn:value()[best_level]*4 - 8 then
    return best_level
  end
  return nil
end

-- Save/Load

function DungeonMapOverwatch:OnLoad(data)
    if data ~= nil then
      self.map_points_level_x = data.map_points_level_x
      self.map_points_level_y = data.map_points_level_y
      self._map_points_level_y:set(data.map_points_level_y)
      self._map_points_level_x:set(data.map_points_level_x)

      if data.base_cave_bounds ~= nil and #data.base_cave_bounds >= 4 then
        self.base_cave_bounds = data.base_cave_bounds
        self._base_cave_bounds:set(self.base_cave_bounds)
        self._has_base_cave_bounds:set(true)
      else
        -- Old saves do not contain this separately captured region. Do not use
        -- the constructor-time scan of an already-terraformed saved map as a
        -- substitute; it would include the synthetic floors as well.
        self.base_cave_bounds = nil
        self._has_base_cave_bounds:set(false)
        print("[MS BaseCaveBounds] missing from save; base-cave mask unavailable until a new world is generated")
      end
    end
    if data and data.level_limits_xp ~= nil then
      self.level_limits_xp = data.level_limits_xp -- Luigi: Not needed, but juuuust in case.
      self.level_limits_xn = data.level_limits_xn
      self.level_limits_yn = data.level_limits_yn
      self.level_limits_yp = data.level_limits_yp
      self._level_limits_xp:set(data.level_limits_xp)
      self._level_limits_xn:set(data.level_limits_xn)
      self._level_limits_yn:set(data.level_limits_yn)
      self._level_limits_yp:set(data.level_limits_yp)
    else -- For worlds before the clouds/level change
        self.level_limits_xp[1] = 60
        self.level_limits_xn[1] = 60
        self.level_limits_yn[1] = 60
        self.level_limits_yp[1] = 60
      for i = 2, 20 do
        self.level_limits_xp[i] = 50
        self.level_limits_xn[i] = 50
        self.level_limits_yn[i] = 50
        self.level_limits_yp[i] = 50
      end
      self._level_limits_xp:set(self.level_limits_xp)
      self._level_limits_xn:set(self.level_limits_xn)
      self._level_limits_yn:set(self.level_limits_yn)
      self._level_limits_yp:set(self.level_limits_yp)
    end
end

function DungeonMapOverwatch:OnSave()
    local data = {}
    data.base_cave_bounds = self.base_cave_bounds
    data.map_points_level_x = self.map_points_level_x
    data.map_points_level_y = self.map_points_level_y
    data.level_limits_xp = self.level_limits_xp
    data.level_limits_xn = self.level_limits_xn
    data.level_limits_yn = self.level_limits_yn
    data.level_limits_yp = self.level_limits_yp
    return data
end

return DungeonMapOverwatch
