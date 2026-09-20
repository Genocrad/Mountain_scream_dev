

local DungeonWallSpawner = Class(function(self, inst)
    self.inst = inst
    self.walls = {}
    self.cave_doors = {}
    self.exits = {}
    self.entrances = {}
  end)

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

local function IsMsTechnicalTile(tile)
  
  return tile == WORLD_TILES.VOID_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL or
  tile == WORLD_TILES.MS_PERMAFROST_TECHNICAL or 
  tile == WORLD_TILES.MS_BRIDGE or 
  (not tile == 1 and not TileGroupManager:IsLandTile(tile))
end

local function comparelevelborder(level,x,z)
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
end


function DungeonWallSpawner:SpawnMainEntrance()
  local center_x, center_y = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(2)
  local attempts = 200
  local success
  while success ~= true and attempts> 0 do
    attempts = attempts -1
    local x = center_x+math.random(-50, 50)*4
    local z = center_y+math.random(-50, 50)*4
    if IsMsTile(TheWorld.Map:GetTileAtPoint(x, 0, z)) then
      local scene = SpawnPrefab("ms_worldmigrator_up_scene")
      scene.Transform:SetPosition(x, 0, z)
      self.exits[2] = scene:Build()
      success = true
    end
  end
  --Luigi: If we cant find a position on a first level, it means that worldgen is fucked up and we have island, extra small level or something like that.
  --Regenerate the world, for sake of our own sanity.
  if attempts < 1 then
    c_regenerateshard()
  end
  attempts = 200
  success = nil
  while success ~= true and attempts>0 do
    attempts = attempts - 1
    local x = center_x+math.random(-50, 50)*4
    local z = center_y+math.random(-50, 50)*4
    if IsMsTile(TheWorld.Map:GetTileAtPoint(x, 0, z)) then
      local scene = SpawnPrefab("ms_shortcut_scene")
      scene.Transform:SetPosition(x, 0, z)
      self.shortcut = scene:Build()
      success = true
    end
  end
  if attempts < 1 then
    c_regenerateshard()
  end
  self:SanityCheck(self.shortcut, self.exits[2])
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
      for i = -10, 10 do 
        for j = -10, 10 do
          if TheWorld.Map:GetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8]) == 1 and math.sqrt(i*i+j*j) < 50 then
            TheWorld.Map:SetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8], WORLD_TILES.CLOUDS_WHITE)  
          end
        end
      end
          
      for i = -2, 2 do 
        for j = -2, 2 do
          TheWorld.Map:SetTile(tile_x + i, tile_z + j, WORLD_TILES.MS_PERMAFROST) 
          comparelevelborder(8,tile_x + i, tile_z + j)
        end
      end
      for i = -1, 1 do 
        for j = -1, 1 do
          TheWorld.Map:SetTile(tile_x + i, tile_z + j, WORLD_TILES.VOID_TECHNICAL) 
          TheWorld.Map:SetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8], WORLD_TILES.MS_SNOW)
          comparelevelborder(9,tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8])
          if TheWorld.components.undertile ~= nil then
            TheWorld.components.undertile:SetTileUnderneath(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8], WORLD_TILES.MS_PERMAFROST)
          end
        end
      end
      
      local top = SpawnPrefab("mountain_top")
      top.Transform:SetPosition(x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4, 0, z + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4) 
      for i = -3, 3 do
        for j = -3, 3 do 
          local plug = SpawnPrefab("giant_plug_marker")
          plug.Transform:SetPosition(x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + i*10*4, 0, z + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4+j*10*4)  
        end
      end
      
      success = true
    end
  end

  -- Now spawn the arena.
  local arena_width = { 4, 5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 6, 5, 4 }
  local tile_x, tile_z = TheWorld.Map:GetTileXYAtPoint(center_x, 0, center_y)
  for i = -14, 14 do 
    for j = -14, 14 do
      if TheWorld.Map:GetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9] ) == 1 then
          TheWorld.Map:SetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9], WORLD_TILES.CLOUDS_WHITE)  
      end
    end
  end
  for i = -7, 7 do 
    for j = -arena_width[i+8], arena_width[i+8] do
      TheWorld.Map:SetTile(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9], WORLD_TILES.MS_SNOW) 
      if TheWorld.components.undertile ~= nil then
        TheWorld.components.undertile:SetTileUnderneath(tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9], WORLD_TILES.MS_PERMAFROST)
        comparelevelborder(10,tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9])
      end
      TheWorld.net.components.dungeonmapoverwatch:AddSpawnPointsForTile(9, tile_x + i + TUNING.MS_TERRAFORMER_OFFSET_X[8] + TUNING.MS_TERRAFORMER_OFFSET_X[9], tile_z + j + TUNING.MS_TERRAFORMER_OFFSET_Y[8] + TUNING.MS_TERRAFORMER_OFFSET_Y[9])
    end
  end
  for i = -3, 3 do
    for j = -3, 3 do 
      local plug = SpawnPrefab("giant_plug_marker")
      plug.Transform:SetPosition(center_x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_X[9] * 4 + i*10*4, 0, center_y + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_Y[9] * 4 + j*10*4)  
    end
  end
  local golem, platform = SpawnPrefab("mountain_golem_pillar"), SpawnPrefab("mountain_golem_platform")
  golem.Transform:SetPosition(center_x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_X[9] * 4 ,0, center_y + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_Y[9]*4)
  platform.Transform:SetPosition(center_x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_X[9] * 4 ,0, center_y + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_Y[9]*4)
  success = nil
  -- Spawn arena teleporter + shortcut exit as one 4x2 / 2x4 brick scene.
  attempts = 100
  while success ~= true and attempts >= 0 do
    local x = center_x+math.random(-200, 200)
    local y
    local z = center_y+math.random(-200, 200)
    attempts = attempts - 1
    if attempts <= 0 then x,y,z = self.exits[8].Transform:GetWorldPosition() x = x + math.random(-32, 32) y = y + math.random(-32, 32) end
    if (TileGroupManager:IsLandTile(TheWorld.Map:GetTileAtPoint(x, 0, z)) and not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(x, 0, z))) or attempts <= 0 then
      local scene = SpawnPrefab("ms_twin_portal_scene")
      scene.Transform:SetPosition(x, 0, z)
      local teleporter, shortcut_exit = scene:Build()
      local tilex, tilez = TheWorld.Map:GetTileXYAtPoint(x, 0, z)
      comparelevelborder(8, tilex, tilez)
      local exit = SpawnPrefab("ms_arenateleporter_exit")
      exit.Transform:SetPosition(center_x + TUNING.MS_TERRAFORMER_OFFSET_X[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_X[9] * 4 ,0, center_y + TUNING.MS_TERRAFORMER_OFFSET_Y[8] * 4 + TUNING.MS_TERRAFORMER_OFFSET_Y[9]*4 - 12)
      exit:SetExitTarget(teleporter)
      teleporter:SetExitTarget(exit)

      self.shortcut:SetExitTarget(shortcut_exit)
      shortcut_exit:SetExitTarget(self.shortcut)

      success = true
      self:SanityCheck(teleporter, self.exits[8])
      self:SanityCheck(shortcut_exit, self.exits[8])
    end
  end
end

local function spawn_5x5_area(self, level, x,y, wall, normal_tile, technical_tile)
  local tilex, tiley = TheWorld.Map:GetTileXYAtPoint(x,0,y)
  for i = -2, 2 do 
    for j = -2, 2 do
      TheWorld.Map:SetTile(tilex + i, tiley + j, normal_tile) 
      comparelevelborder(level, tilex + i, tiley + j)
      TheWorld.net.components.dungeonmapoverwatch.cloud_tiles_planned_cords[tilex + i][tiley + j] = true
    end
  end
  for i = -1, 1 do 
    for j = -1, 1 do
      TheWorld.Map:SetTile(tilex + i, tiley + j, technical_tile) 
    end
  end
  
  local function spawnwall(dx, dy, angle)
    local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
    new_wall.Transform:SetPosition(x+dx , 0, y+dy)
    new_wall.Transform:SetRotation(angle)
  end
  spawnwall(4.82, 0, 90)
  spawnwall(-4.82, 0, 90)
  spawnwall(0, 4.82, 0)
  spawnwall(0, -4.82, 0)
  spawnwall(3.414, 3.414, 45)
  spawnwall(3.414, -3.414, 135)
  spawnwall(-3.414, 3.414, 135)
  spawnwall(-3.414, -3.414, 45)
  local random_x, random_y = math.random(-30, 30), math.random(-30, 30)
  for i = -1, 1 do 
    for j = -1, 1 do
      TheWorld.Map:SetTile(tilex + i + TUNING.MS_TERRAFORMER_OFFSET_X[level] + random_x, tiley + j + TUNING.MS_TERRAFORMER_OFFSET_Y[level] + random_y, normal_tile) 
      TheWorld.net.components.dungeonmapoverwatch.cloud_tiles_planned_cords[tilex + i + TUNING.MS_TERRAFORMER_OFFSET_X[level] + random_x][tiley + j + TUNING.MS_TERRAFORMER_OFFSET_Y[level] + random_y] = true
      comparelevelborder(level+1, tilex + i + TUNING.MS_TERRAFORMER_OFFSET_X[level] + random_x, tiley + j + TUNING.MS_TERRAFORMER_OFFSET_Y[level] + random_y)
    end
  end
  self.exits[level+1] = SpawnPrefab("ms_climbing_down")
  self.exits[level+1].Transform:SetPosition(x + TUNING.MS_TERRAFORMER_OFFSET_X[level] * 4 + random_x * 4, 0, y + TUNING.MS_TERRAFORMER_OFFSET_Y[level] * 4 + random_y * 4)
  -- Pad center is technical; small nudge onto the outer land ring.
  self.exits[level+1].components.teleporter.teleport_offset = { x = 0, y = 0, z = 3 }
  self.entrances[level]:SetExitTarget(self.exits[level+1])
  self.exits[level+1]:SetExitTarget(self.entrances[level])

end

function DungeonWallSpawner:SpawnWallsAroundPoint(level, wall, size, normal_tile, technical_tile)
  local center_x, center_y = TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(level)
  center_x = center_x
  center_y = center_y


  -- First, we check for holes, cavities and other stuff that messes our wall placement.
  for x = -size , size  do 
    for y = -size , size  do
      local tile_x, tile_y = TheWorld.Map:GetTileXYAtPoint(center_x+x*4, 0, center_y+y*4)
      if IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x, tile_y)) then
        local l,r,d,u,ld,lu,rd,ru = nil, nil, nil, nil, nil, nil, nil, nil
        -- Check neaby tiles
        if not IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x+1, tile_y)) then 
          r = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x-1, tile_y)) then 
          l = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x, tile_y+1)) then 
          d = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x, tile_y-1)) then
          u = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x+1, tile_y+1)) then 
          ru = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x+1, tile_y-1)) then 
          rd = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x-1, tile_y+1)) then 
          lu = 1
        end
        if not IsMsTechnicalTile(TheWorld.Map:GetTile(tile_x-1, tile_y-1))  then 
          ld = 1
        end
       
        
        
        if l and d and r and u then
          TheWorld.Map:SetTile(tile_x, tile_y, normal_tile)
        elseif  (r and l and u and (ld or rd)) then
          TheWorld.Map:SetTile(tile_x, tile_y, normal_tile)
        elseif (r and l and d and (lu or ru)) then 
          TheWorld.Map:SetTile(tile_x, tile_y, normal_tile)
        elseif (u and l and d and (ru or rd)) then
          TheWorld.Map:SetTile(tile_x, tile_y, normal_tile)
        elseif (r and u and d and (lu or ld)) then
          TheWorld.Map:SetTile(tile_x, tile_y, normal_tile)
        elseif (u and d and not r and not l) then
          TheWorld.Map:SetTile(tile_x, tile_y, normal_tile)
        elseif (r and l and not u and not d) then
          TheWorld.Map:SetTile(tile_x, tile_y, normal_tile)
        elseif r or l or d or u or rd or ld or lu or ru then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
      end  
    end
  end

  -- Some variables for exits and entrance spawns
  local spawned 
  local spawned_cave_entrance 
  local last_entrance_x, last_entrance_y, last_exit_x, last_exit_y, last_r, last_l, last_d, last_u = center_x,center_y,center_x+TUNING.MS_TERRAFORMER_OFFSET_X[level]*4,center_y+TUNING.MS_TERRAFORMER_OFFSET_Y[level]*4, 0,0,0,0

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
          local function spawnwallcorner(angle1, angle2)
            local new_wall_r = SpawnPrefab("ms_mountain_corner_wall_right" .. wall)
            new_wall_r.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
            new_wall_r.Transform:SetRotation(angle1)          
            local new_wall_l = SpawnPrefab("ms_mountain_corner_wall_left" .. wall)
            new_wall_l.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
            new_wall_l.Transform:SetRotation(angle2)
          end
          TheWorld.net.components.dungeonmapoverwatch:AddSpawnPointsForWall(level, center_x+x*4, center_y+y*4, r-l, d-u)
          if l == 1 and d == 1 then
            spawnwallcorner(90, 180)
          end
          if l == 1 and u == 1 then
            spawnwallcorner(0, 90)
          end
          if r == 1 and d == 1 then
            spawnwallcorner(180, 270)
          end
          if r == 1 and u == 1 then
            spawnwallcorner(270, 0)
          end
        else
          -- Check if we should spawn an entrance to the next level. More distance = more chance.
          if (l == 1 or r == 1 or d == 1 or u == 1)  then
            TheWorld.net.components.dungeonmapoverwatch:AddSpawnPointsForWall(level, center_x+x*4, center_y+y*4, r-l, d-u, true)
            local spawned_climb = false
            if not spawned then
              last_entrance_x, last_entrance_y, last_exit_x, last_exit_y, last_r, last_l, last_d, last_u = center_x+x*4 + (r * 4 - l *4) * 0.05, center_y+y*4 + (d*4 - u *4) * 0.05,
                                                                                                           center_x+x*4 + l - r + TUNING.MS_TERRAFORMER_OFFSET_X[level]*4,
                                                                                                           center_y+y*4 + u - d + TUNING.MS_TERRAFORMER_OFFSET_Y[level]*4,
                                                                                                           r, l, d, u
              if math.random() < self.exits[level]:GetDistanceSqToPoint(center_x+x*4, 0, center_y+y*4)/(TUNING.MS_TERRAFORMER_SIZE[level] * TUNING.MS_TERRAFORMER_SIZE[level] * 16 * 10) then
                self.entrances[level] = SpawnPrefab("ms_climbing")
                self.entrances[level].Transform:SetPosition(center_x+x*4 + (r * 4 - l *4) * 0.05, 0, center_y+y*4 + (d*4 - u *4) * 0.05)
                self.entrances[level].Transform:SetRotation((r==1 or l==1) and 90 or 0)
                self.exits[level+1] = SpawnPrefab("ms_climbing_down")
                self.exits[level+1].Transform:SetPosition(center_x+x*4 + l - r + TUNING.MS_TERRAFORMER_OFFSET_X[level]*4, 0, center_y+y*4 + u - d + TUNING.MS_TERRAFORMER_OFFSET_Y[level]*4)
                -- Down only: land outside the mountain (same side as the ladder face).
                self.exits[level+1].components.teleporter.teleport_offset = {x = (r - l) * 4, y = 0, z = (d - u) * 4 }
                self.entrances[level]:SetExitTarget(self.exits[level+1])
                self.exits[level+1]:SetExitTarget(self.entrances[level])
                spawned = true
                spawned_climb = true
              end
            end
            if not spawned_cave_entrance and not spawned_climb then
              if math.random() < self.exits[level]:GetDistanceSqToPoint(center_x+x*4- l * 4 + r * 4, 0, center_y+y*4+ (-u * 4 + d * 4)*(r-1)*(l-1))/(TUNING.MS_TERRAFORMER_SIZE[level] * TUNING.MS_TERRAFORMER_SIZE[level] * 16 * 10) and self.cave_doors[level] then
                local entrance = SpawnPrefab("ms_cave_entrance_vertical")
                entrance.Transform:SetPosition(center_x+x*4 + (r * 4 - l *4) * 0.05, 0, center_y+y*4 + (d*4 - u *4) * 0.05)
                entrance.Transform:SetRotation(r==1 and 90 or (l==1 and 270 or (u==1 and 180 or 0))) 
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
          end
          if l == 1 then 
            local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
            new_wall.Transform:SetPosition(center_x+x*4 , 0, center_y+y*4)
            new_wall.Transform:SetRotation(90)
            new_wall.debuginfo = {center_x+x*4 , 0, center_y+y*4, "-x"}
          end
          if d == 1 then 
            local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
            new_wall.Transform:SetPosition(center_x+x*4, 0, center_y+y*4)
            new_wall.Transform:SetRotation(0)
            new_wall.debuginfo = {center_x+x*4, 0, center_y+y*4, "+y"}
          end
          if u == 1 then
            local new_wall = SpawnPrefab("ms_mountain_wall" .. wall)
            new_wall.Transform:SetPosition(center_x+x*4, 0, center_y+y*4)
            new_wall.Transform:SetRotation(0)
            new_wall.debuginfo = {center_x+x*4, 0, center_y+y*4, "-y"}
          end

        end  
      end  
    end
  end

  if not spawned then
    -- No walls spawned on this level. Create some for visuals.
   
    if last_d + last_u + last_r + last_l == 0 then
       print("EXTREME SPAWN 0 ",  level, last_entrance_x, last_entrance_y, last_exit_x, last_exit_y, last_r, last_l, last_d, last_u)
      self.entrances[level] = SpawnPrefab("ms_climbing")
      self.entrances[level].Transform:SetPosition(last_entrance_x, 0, last_entrance_y+1.1)
      spawn_5x5_area(self, level, last_entrance_x, last_entrance_y-4, wall, normal_tile, technical_tile)
    else
       print("EXTREME SPAWN", "level", level, "ex", last_entrance_x, "ey", last_entrance_y, "ox", last_exit_x, "oy", last_exit_y, "r", last_r, "l" ,last_l, "d", last_d, "u", last_u)
      self.entrances[level] = SpawnPrefab("ms_climbing")
      self.entrances[level].Transform:SetPosition(last_entrance_x, 0, last_entrance_y)
      self.entrances[level].Transform:SetRotation((last_r == 1 or last_l == 1) and 90 or 0)
      self.exits[level+1] = SpawnPrefab("ms_climbing_down")
      self.exits[level+1].Transform:SetPosition(last_exit_x, 0, last_exit_y)
      self.exits[level+1].components.teleporter.teleport_offset = {x = (last_r - last_l) * 4, y = 0, z = (last_d - last_u) * 4 }
      self.entrances[level]:SetExitTarget(self.exits[level+1])
      self.exits[level+1]:SetExitTarget(self.entrances[level])
    end
  end
  self:SanityCheck(self.entrances[level], self.exits[level])
end

local type_to_points = {
  ["tri"] = {{13,-20}, {13,-9}, {0,0}, {-13,-9}, {-13,-20}, {13,-20}},
  ["round"] = {{-13,-20}, {-13,-8}, {-7,0}, {7,0}, {13,-8}, {13,-20}, {-13,-20}},
  ["rect"] = { {-13,-20}, {-13,0}, {13,0}, {13,-20}, {-13,-20}},
}

local layour_door_coords = {
  ["tri"] = {["right"] = {13.5, -15}, ["left"] = {-13.5, -15}, ["up"] = {0,0}, ["down"] = {0, -22}},
  ["round"] = {["right"] = {13.5, -15}, ["left"] = {-13.5, -15}, ["up"] = {0,0}, ["down"] = {0, -22}},
  ["rect"] = {["right"] = {13.5, -11}, ["left"] = {-13.5, -11}, ["up"] = {0,0}, ["down"] = {0, -22}},
}

--Luigi: about 30 points should be enough. Also, this does not work for non-convex shapes, if that ever comes up.
local function addmobpointsforcaves(level,x,y,r,l,d,u,floor_type)
  for i=1, 30 do
    local point = {math.random() * 24 - 12, -math.random() * 20}
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
  for i = 1, 10 do
    local wall = math.random(1,#type_to_points[floor_type]-2)
    if type_to_points[floor_type][wall][1] - type_to_points[floor_type][wall+1][1] ~= 0 then
      print("x", floor_type, wall, x, y, type_to_points[floor_type][wall][1], type_to_points[floor_type][wall+1][1],  type_to_points[floor_type][wall][2], type_to_points[floor_type][wall+1][2])
      local min_x, max_x = math.min(type_to_points[floor_type][wall][1], type_to_points[floor_type][wall+1][1]), math.max(type_to_points[floor_type][wall][1], type_to_points[floor_type][wall+1][1])
      local min_y, max_y = math.min(type_to_points[floor_type][wall][2], type_to_points[floor_type][wall+1][2]), math.max(type_to_points[floor_type][wall][2], type_to_points[floor_type][wall+1][2])
      local point_x = math.random(min_x, max_x)
      local point_y = -((point_x-min_x) * (max_y - min_y))/(max_x - min_x)
      local angle = 90
      
      if min_y == max_y then
        point_y = min_y
      elseif point_x > 0 then
        angle = 135
      else
        angle = 45
      end
       TheWorld.net.components.dungeonmapoverwatch:AddPointForWall(level, x + point_x, y + math.max(point_y-1, -20), angle)
    else -- Now handle the case where wall is o. the z axis
      local min_x, max_x = math.min(type_to_points[floor_type][wall][1], type_to_points[floor_type][wall+1][1]), math.max(type_to_points[floor_type][wall][1], type_to_points[floor_type][wall+1][1])
      local min_y, max_y = math.min(type_to_points[floor_type][wall][2], type_to_points[floor_type][wall+1][2]), math.max(type_to_points[floor_type][wall][2], type_to_points[floor_type][wall+1][2])
      local point_y = math.random(min_y, max_y)

      local angle = 0
      if min_x > 0 then
        angle = 180
      end
      print("y", min_x, angle)
      TheWorld.net.components.dungeonmapoverwatch:AddPointForWall(level, x + min_x, y + math.max(point_y-1, -20), angle)
    end
      -- XK, i have no idea why this would not work at all, so sadly i have to do a sipler dumber idea.
      --[[ if point_y > 1000 or point_y ~= point_y then
        point_y = 0.1
      end
      local angle = math.deg(math.atan2(point_x,(-22 - point_y)))
      if point_y == 0 then point_y = min_y end
      if point_x == 0 then point_x = min_x end
      local angle = math.deg(math.acos(point_x/math.sqrt(point_x * point_x + (-42 - point_y) * (-42 - point_y))))
      if angle<0 then angle = 360 - angle end
      if angle>360 then angle = angle - 360 end
      print(point_x, point_y, angle)
      TheWorld.net.components.dungeonmapoverwatch:AddPointForWall(level, x + point_x, y + point_y, angle)
    else
      print("y", floor_type, wall, x, y, type_to_points[floor_type][wall][1], type_to_points[floor_type][wall+1][1],  type_to_points[floor_type][wall][2], type_to_points[floor_type][wall+1][2])
      local min_x, max_x = math.min(type_to_points[floor_type][wall][1], type_to_points[floor_type][wall+1][1]), math.max(type_to_points[floor_type][wall][1], type_to_points[floor_type][wall+1][1])
      local min_y, max_y = math.min(type_to_points[floor_type][wall][2], type_to_points[floor_type][wall+1][2]), math.max(type_to_points[floor_type][wall][2], type_to_points[floor_type][wall+1][2])
      local point_y = math.random(min_y, max_y)
      local point_x = (point_y * (max_x - min_x))/(max_y - min_y)
      
      if point_x > 1000 or point_x ~= point_x then
        point_x = 0.1
      end
      
      
      if point_y == 0 then point_y = min_y end
      if point_x == 0 then point_x = min_x end
      print(math.sqrt(point_x * point_x + (-22 - point_y) * (-22 - point_y))/point_x, math.sqrt(point_x * point_x + (-12 - point_y) * (-12 - point_y)),point_x, (math.abs(point_x)/point_x))
      local angle = math.deg(math.acos((point_y*point_y)/point_x * point_x + (-12 - point_y) * (-12 - point_y))) * (math.abs(point_x)/point_x)
      if angle<0 then angle = 360 - angle end
      if angle>360 then angle = angle - 360 end
      
      print(point_x, point_y, angle)
      TheWorld.net.components.dungeonmapoverwatch:AddPointForWall(level, x + point_x, y + point_y, angle)
      ]]
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

function DungeonWallSpawner:SanityCheck(entrance, exit)
  if not entrance or not exit then
    return
  end
  local x,y,z = entrance.Transform:GetWorldPosition()
  local x1,y1,z1 = exit.Transform:GetWorldPosition()
  local sanity_x, sanity_y = {}, {}
  local insane_gen
  -- Luigi: We only check for WORLD_TILES.VOID aka 1 and clouds, as we assume that if there are technical tiles inbetween entrance
  -- and the exit, it probably means that they are on the same island and no intrusion is needed.
  for i = x, x1, math.abs(x1-x)/(x1-x) * 4 do
    sanity_x[i] = 0
    local deltaz = math.abs(z1-z)/(z1-z) * 4
    for j = z - deltaz * 5, z1 + deltaz * 5, deltaz do 
      local tile = TheWorld.Map:GetTileAtPoint(i, 0, j)
      if tile ~= 1 and tile ~= WORLD_TILES.CLOUDS_WHITE and tile ~= WORLD_TILES.CLOUDS_DARK then
        sanity_x[i] = sanity_x[i] + 1
      end
    end
  end
  for j = z, z1, math.abs(z1-z)/(z1-z) * 4 do 
    sanity_y[j] = 0
    local deltax = math.abs(x1-x)/(x1-x) * 4
    for i = x - deltax * 5, x1 + deltax * 5, deltax do
      local tile = TheWorld.Map:GetTileAtPoint(i, 0, j)
      if tile ~= 1 and tile ~= WORLD_TILES.CLOUDS_WHITE and tile ~= WORLD_TILES.CLOUDS_DARK then
        sanity_y[j] = sanity_y[j] + 1
      end
    end
  end
  for k, v in pairs(sanity_x) do
    if v == 0 then insane_gen = true end
  end
  for k, v in pairs(sanity_y) do
    if v == 0 then insane_gen = true end
  end
  if insane_gen then
    local deltax, deltay = (x - x1)/math.max(math.abs(x-x1), math.abs(z-z1)), (z - z1)/math.max(math.abs(x-x1), math.abs(z-z1))
    for i = 0, math.max(math.abs(x-x1), math.abs(z-z1)) do
      local tile = TheWorld.Map:GetTileAtPoint(x - deltax * i, 0, z - deltay * i)
      if tile == 1 or tile == WORLD_TILES.CLOUDS_WHITE or tile == WORLD_TILES.CLOUDS_DARK then
        local tile_x, tile_y = TheWorld.Map:GetTileXYAtPoint(x - deltax * i, 0, z - deltay * i)
        for i = -7, 7 do
          for j = -7, 7 do
            TheWorld.net.components.dungeonmapoverwatch.cloud_tiles_planned_cords[tile_x+i][tile_y+j] = true
          end
        end
        TheWorld.Map:SetTile(tile_x, tile_y, WORLD_TILES.MS_BRIDGE)
      end
    end
  end
end

function DungeonWallSpawner:SpawnClouds()
  local dungeonow  = TheWorld.net.components.dungeonmapoverwatch
  for level = 2, TUNING.MS_CAVES_START do
    local centerx, centery = dungeonow._map_points_level_x:value()[level], dungeonow._map_points_level_y:value()[level]
    local xp, xn, yp, yn = dungeonow.level_limits_xp[level], dungeonow.level_limits_xn[level], dungeonow.level_limits_yp[level], dungeonow.level_limits_yn[level]
    for i = -(xn+10), (xp+10) do
      for j = -(yn+10), (yp+10) do
        local tile = TheWorld.Map:GetTile(centerx + i, centery + j) 
        
        if dungeonow.cloud_tiles_planned_cords[centerx + i][centery + j] == true then
          if (not TileGroupManager:IsLandTile(tile)) and not (tile == WORLD_TILES.CLOUDS_DARK) and not (tile == WORLD_TILES.VOID_TECHNICAL) then
            TheWorld.Map:SetTile(centerx + i, centery + j, WORLD_TILES.CLOUDS_WHITE)
          end
        end
      end
    end
  end
end

return DungeonWallSpawner
