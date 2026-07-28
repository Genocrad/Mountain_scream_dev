

local DungeonMapOverwatch = Class(function(self, inst)
    self.inst = inst
    
    self.terraformers_points = {}
    self.exits = {}
    self.mob_spawn_points = {}
    self.wall_spawn_points = {}
    self.mob_spawn_points_near_walls = {} 
    
    for i = 1, 20 do 
      self.terraformers_points[i] = {}
      self.exits[i] = nil
      self.mob_spawn_points[i] = {}
      self.wall_spawn_points[i] = {} -- Not for walls, but on the walls
      self.mob_spawn_points_near_walls[i] = {} -- if we ever want to have something that spawns only near the walls, like fallen boulders or something.
    end
    
    local map = TheWorld.Map
    self.map_width, self.map_height = map:GetSize()
    
    self.map_points_level_x = {}
    self._map_points_level_x = net_ushortarray(inst.GUID, "dungeonmapoverwatch._map_points_level_x") -- Arrays are expensive, and we do not need precise cords, really.
    
     self.map_points_level_y = {}
    self._map_points_level_y = net_ushortarray(inst.GUID, "dungeonmapoverwatch._map_points_level_y") -- Arrays are expensive, and we do not need precise cords, really.
    
    
    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("dungeonmapoverwatch")
    
    if TheWorld.ismastersim then
      self.map_points_level_x[1] = 0
      self.map_points_level_y[1] = 0
      self.map_points_level_x[2] = 70
      self.map_points_level_y[2] = 70
    
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

function DungeonMapOverwatch:AddSpawnPointsForWall(level,x,y,dx,dy)
  for i = 1, math.random(1,3) do
    table.insert(self.wall_spawn_points[level], {x = dx ~= 0 and x + dx or x + math.random()*4 - 2, y = 1.5 + math.random() * 8, z = dy ~= 0 and y + dy or y + math.random()*4 - 2})
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
    if self.terraformers_points[level] and #self.terraformers_points[level]>0 then
      if level == 1 then
        local x = 0
        local y = 0
        for k, v in pairs(self.terraformers_points[level]) do
          x = x + v[1]
          y = y + v[2]
        end
        if self.map_points_level_x[level] == 0 then
          local tile_x,tile_y = TheWorld.Map:GetTileXYAtPoint(x/#self.terraformers_points[level], 0, y/#self.terraformers_points[level])
          self.map_points_level_x[level] = tile_x
          self.map_points_level_y[level] = tile_y
          self._map_points_level_y:set(self.map_points_level_y)
          self._map_points_level_x:set(self.map_points_level_x)
        end
        return x/#self.terraformers_points[level],y/#self.terraformers_points[level]
      end
    else
     return -self.map_width*2+self._map_points_level_x:value()[level]*4, -self.map_height*2+self._map_points_level_y:value()[level]*4
    end
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
  local level = 1
  local point_x, point_y = self:GetPointForLevel(1)
  local min = (x-point_x) * (x-point_x) + (z-point_y) * (z-point_y)  
  local min_x = 99999
  local min_z = 99999
  for i =2, #self._map_points_level_x:value() do
    point_x, point_y = self:GetPointForLevel(i)
    if min > (x-point_x) * (x-point_x) + (z-point_y) * (z-point_y) then
      min = (x-point_x) * (x-point_x) + (z-point_y) * (z-point_y)  
      level = i
      min_x = math.abs(x-point_x)
      min_z = math.abs(z-point_y)
    end
  end
  -- As we want a square area, not circle area for a level.
  if min_x < 200 and min_z < 200 then
    return level
  end
  return nil
end

-- Save/Load

function DungeonMapOverwatch:OnLoad(data)
    if data ~= nil then
      self.map_points_level_x = data.map_points_level_x
      self.map_points_level_y = data.map_points_level_y
      self._map_points_level_y:set(self.map_points_level_y)
      self._map_points_level_x:set(self.map_points_level_x)
    end
end

function DungeonMapOverwatch:OnSave()
    local data = {}
    data.map_points_level_x = self.map_points_level_x
    data.map_points_level_y = self.map_points_level_y
    return data
end

return DungeonMapOverwatch