

-- Edge-midpoint wall data shared with clients (renderer reads this).
-- Use rawget/rawset: DST's strict.lua forbids reading undeclared globals.
if rawget(_G, "MountainWalls") == nil then
  rawset(_G, "MountainWalls", {})
end

local ORTHO_OFFS = {
  { 1,  0 },
  {-1,  0 },
  { 0,  1 },
  { 0, -1 },
}

local DungeonWallSpawner = Class(function(self, inst)
    self.inst = inst
    self.walls = {}
    self.cave_doors = {}
    self.exits = {}
    self._wall_uv_toggle = 0

    inst:ListenForEvent("ms_playerjoined", function(_, player)
      self:SyncWallsToPlayer(player)
    end)
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

local function WallId(x, z)
  return string.format("%.4f|%.4f", x, z)
end

local function PieceId(x, z, tag)
  return string.format("%.4f|%.4f|%s", x, z, tag)
end

local function GetMountainWalls()
  local walls = rawget(_G, "MountainWalls")
  if walls == nil then
    walls = {}
    rawset(_G, "MountainWalls", walls)
  end
  return walls
end

function DungeonWallSpawner:SetMountainWallEntry(id, data)
  GetMountainWalls()[id] = data
  self.walls[id] = data
end

function DungeonWallSpawner:SetMountainWall(x, z, data)
  data.x = data.x or x
  data.z = data.z or z
  data.kind = data.kind or "straight"
  self:SetMountainWallEntry(WallId(x, z), data)
end

function DungeonWallSpawner:ClearMountainWall(x, z)
  local walls = GetMountainWalls()
  local to_clear = {}
  for id, data in pairs(walls) do
    local px = data.x
    local pz = data.z
    if px == nil or pz == nil then
      local a, b = string.match(id, "^([^|]+)|([^|]+)")
      px, pz = tonumber(a), tonumber(b)
    end
    if px ~= nil and pz ~= nil and math.abs(px - x) < 0.05 and math.abs(pz - z) < 0.05 then
      table.insert(to_clear, id)
    end
  end
  for _, id in ipairs(to_clear) do
    walls[id] = nil
    self.walls[id] = nil
  end
end

local function PackWallRpc(data)
  return data.type or "",
    data.uv or 0,
    data.void_x or 0,
    data.void_z or 0,
    data.kind or "straight",
    data.rot or 0,
    data.x or 0,
    data.z or 0
end

function DungeonWallSpawner:SyncWallsToPlayer(player)
  if player == nil or (player.userid and player.userid == "") then
    return
  end
  for id, data in pairs(GetMountainWalls()) do
    local t, uv, vx, vz, kind, rot, x, z = PackWallRpc(data)
    SendModRPCToClient(GetClientModRPC("MountainScream", "mountainWallData"), player.userid, id, t, uv, vx, vz, false, kind, rot, x, z)
  end
  SendModRPCToClient(GetClientModRPC("MountainScream", "mountainWallsRebuild"), player.userid)
end

function DungeonWallSpawner:SyncAllWalls(rebuild)
  for id, data in pairs(GetMountainWalls()) do
    local t, uv, vx, vz, kind, rot, x, z = PackWallRpc(data)
    SendModRPCToClient(GetClientModRPC("MountainScream", "mountainWallData"), nil, id, t, uv, vx, vz, false, kind, rot, x, z)
  end
  if rebuild then
    SendModRPCToClient(GetClientModRPC("MountainScream", "mountainWallsRebuild"), nil)
    if TheWorld.components.mountainwallrenderer ~= nil then
      TheWorld.components.mountainwallrenderer:RebuildAll()
    end
  end
end

function DungeonWallSpawner:OnSave()
  local walls = {}
  for id, data in pairs(GetMountainWalls()) do
    walls[id] = {
      type = data.type,
      uv = data.uv,
      void_x = data.void_x,
      void_z = data.void_z,
      kind = data.kind,
      rot = data.rot,
      x = data.x,
      z = data.z,
    }
  end
  return { mountain_walls = walls }
end

function DungeonWallSpawner:OnLoad(data)
  if data == nil or data.mountain_walls == nil then
    return
  end
  local walls = {}
  rawset(_G, "MountainWalls", walls)
  self.walls = {}
  for id, wall in pairs(data.mountain_walls) do
    walls[id] = wall
    self.walls[id] = wall
  end
  self.inst:DoTaskInTime(1, function()
    if TheWorld.components.mountainwallrenderer ~= nil then
      TheWorld.components.mountainwallrenderer:RebuildAll()
    end
  end)
end

-- Seal VOID→technical where it touches land (ortho or diagonal), plus the old
-- intrusion fills so corner/slope neighborhoods still form cleanly.
local function SealTechnicalBoundary(center_x, center_y, size, technical_tile)
  for x = -size, size do
    for y = -size, size do
      local wx, wz = center_x + x * 4, center_y + y * 4
      if IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz)) then
        local l, r, d, u, ld, lu, rd, ru = nil, nil, nil, nil, nil, nil, nil, nil
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx + 4, 0, wz)) then r = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx - 4, 0, wz)) then l = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz + 4)) then d = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz - 4)) then u = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx + 4, 0, wz + 4)) then ru = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx + 4, 0, wz - 4)) then rd = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx - 4, 0, wz + 4)) then lu = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx - 4, 0, wz - 4)) then ld = 1 end

        local tile_x, tile_y = TheWorld.Map:GetTileXYAtPoint(wx, 0, wz)
        local should_seal = r or l or d or u or rd or ld or lu or ru
          or (l and d and r and u)
          or (r and l and u and (ld or rd))
          or (r and l and d and (lu or ru))
          or (u and l and d and (ru or rd))
          or (r and u and d and (lu or ld))
          or (u and d and not r and not l)
          or (r and l and not u and not d)

        if should_seal and TheWorld.Map:GetTileAtPoint(wx, 0, wz) == WORLD_TILES.VOID_TECHNICAL then
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        elseif should_seal then
          -- Already a technical variant; keep ring consistent with level tile.
          TheWorld.Map:SetTile(tile_x, tile_y, technical_tile)
        end
      end
    end
  end
end

local function CollectClimbSpawnEdges(self, level, center_x, center_y, size, wall_suffix)
  local spawned
  local spawned_cave_entrance
  local last_entrance_x, last_entrance_y = center_x, center_y
  local last_exit_x = center_x + TUNING.MS_TERRAFORMER_OFFSET_X[level] * 4
  local last_exit_y = center_y + TUNING.MS_TERRAFORMER_OFFSET_Y[level] * 4

  for x = -size, size do
    for y = -size, size do
      local wx, wz = center_x + x * 4, center_y + y * 4
      if IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz)) then
        local l, r, d, u = 0, 0, 0, 0
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx + 4, 0, wz)) then r = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx - 4, 0, wz)) then l = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz + 4)) then d = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz - 4)) then u = 1 end

        if l == 1 or r == 1 or d == 1 or u == 1 then
          TheWorld.net.components.dungeonmapoverwatch:AddSpawnPointsForWall(level, wx, wz, r - l, d - u)

          if not spawned and self.exits[level] ~= nil then
            last_entrance_x = wx - l * 4 + r * 4
            last_entrance_y = wz - u * 4 + d * 4
            last_exit_x = wx + TUNING.MS_TERRAFORMER_OFFSET_X[level] * 4
            last_exit_y = wz + TUNING.MS_TERRAFORMER_OFFSET_Y[level] * 4
            local chance = self.exits[level]:GetDistanceSqToPoint(wx, 0, wz)
              / (TUNING.MS_TERRAFORMER_SIZE[level] * TUNING.MS_TERRAFORMER_SIZE[level] * 16 * 10)
            if math.random() < chance then
              local entrance = SpawnPrefab("ms_climbing")
              entrance.Transform:SetPosition(last_entrance_x, 0, last_entrance_y)
              self.exits[level + 1] = SpawnPrefab("ms_climbing_down")
              self.exits[level + 1].Transform:SetPosition(
                wx + l - r + TUNING.MS_TERRAFORMER_OFFSET_X[level] * 4,
                0,
                wz + u - d + TUNING.MS_TERRAFORMER_OFFSET_Y[level] * 4
              )
              entrance:SetExitTarget(self.exits[level + 1])
              self.exits[level + 1]:SetExitTarget(entrance)
              spawned = true

              -- Clear all pieces tied to this face: tech cell, edge midpoint, and corner.
              self:ClearMountainWall(wx, wz)
              self:ClearMountainWall(wx - l * 2 + r * 2, wz - u * 2 + d * 2)
              self:ClearMountainWall(wx + (r - l) * 2, wz + (d - u) * 2)
            end
          end

          if not spawned_cave_entrance and self.cave_doors[level] and self.exits[level] ~= nil then
            local chance = self.exits[level]:GetDistanceSqToPoint(
              wx - l * 4 + r * 4,
              0,
              wz + (-u * 4 + d * 4) * (r - 1) * (l - 1)
            ) / (TUNING.MS_TERRAFORMER_SIZE[level] * TUNING.MS_TERRAFORMER_SIZE[level] * 16 * 10)
            if math.random() < chance then
              local entrance = SpawnPrefab("ms_cave_entrance_vertical")
              entrance.Transform:SetPosition(wx, 0, wz)
              entrance.Transform:SetRotation(r > 0 and 90 or (l > 0 and 270 or (u > 0 and 180 or 0)))
              entrance:SetExitTarget(self.cave_doors[level])
              entrance.components.teleporter.teleport_offset = { x = r * 4 - l * 4, y = 0, z = d * 4 - u * 4 }
              self.cave_doors[level]:SetExitTarget(entrance)
              spawned_cave_entrance = true
            end
          end
        end
      end
    end
  end

  if not spawned then
    local entrance = SpawnPrefab("ms_climbing")
    entrance.Transform:SetPosition(last_entrance_x, 0, last_entrance_y)
    self.exits[level + 1] = SpawnPrefab("ms_climbing_down")
    self.exits[level + 1].Transform:SetPosition(last_exit_x, 0, last_exit_y)
    entrance:SetExitTarget(self.exits[level + 1])
    self.exits[level + 1]:SetExitTarget(entrance)
  end
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
  wall = wall or ""
  if wall == "ms_mountain_wall" then
    wall = ""
  elseif type(wall) == "string" and string.find(wall, "^ms_mountain_wall") then
    wall = string.gsub(wall, "^ms_mountain_wall", "")
  end

  if technical_tile ~= nil then
    SealTechnicalBoundary(center_x, center_y, size, technical_tile)
  end

  local function add_piece(x, z, kind, rot, void_x, void_z, tag)
    self._wall_uv_toggle = 1 - self._wall_uv_toggle
    self:SetMountainWallEntry(PieceId(x, z, tag or kind), {
      type = wall,
      kind = kind,
      rot = rot or 0,
      uv = self._wall_uv_toggle,
      x = x,
      z = z,
      void_x = void_x,
      void_z = void_z,
    })
  end

  -- Edge-aligned walls, no overlapping pieces on the same edge:
  --   * Every land|tech edge → one full straight at the edge midpoint.
  --   * Inner corners: those two edges are just two straights (no half-edge corner art).
  --   * Outer corners: also add the two bridge straights on this tech cell that meet the tip.
  --   * 3-side: slope art is authored for the tech cell center and IS the wall (points at the
  --     open side). Do not wrap it with land-edge straights — that put rectangles outside and
  --     buried the triangle inside. Those three land edges stay slope-owned.
  local slope_owned = {} -- [WallId(mid)] = true
  local straights = {} -- [WallId(mid)] = {x,z,rot,void_x,void_z}
  local outers = {}
  local slopes = {}

  local function mark_slope_owned(mx, mz)
    slope_owned[WallId(mx, mz)] = true
  end

  local function try_straight(mx, mz, rot, void_x, void_z)
    local id = WallId(mx, mz)
    if slope_owned[id] or straights[id] ~= nil then
      return
    end
    straights[id] = {
      x = mx,
      z = mz,
      rot = rot,
      void_x = void_x,
      void_z = void_z,
    }
  end

  -- Pass 1: find outers / slopes; reserve 3-side land edges for the triangle.
  for x = -size, size do
    for y = -size, size do
      local wx, wz = center_x + x * 4, center_y + y * 4
      if IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz)) then
        local l, r, d, u, ld, lu, rd, ru = 0, 0, 0, 0, 0, 0, 0, 0
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx + 4, 0, wz)) then r = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx - 4, 0, wz)) then l = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz + 4)) then d = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz - 4)) then u = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx + 4, 0, wz + 4)) then ru = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx + 4, 0, wz - 4)) then rd = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx - 4, 0, wz + 4)) then lu = 1 end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx - 4, 0, wz - 4)) then ld = 1 end

        local ortho = l + r + d + u
        local cell = {
          wx = wx, wz = wz,
          l = l, r = r, d = d, u = u,
          ld = ld, lu = lu, rd = rd, ru = ru,
        }

        if (ru == 1 or rd == 1 or lu == 1 or ld == 1) and ortho == 0 then
          table.insert(outers, cell)
        elseif ortho > 2 then
          table.insert(slopes, cell)
          -- Triangle owns the three land faces; no full straights under it.
          if r == 1 then mark_slope_owned(wx + 2, wz) end
          if l == 1 then mark_slope_owned(wx - 2, wz) end
          if d == 1 then mark_slope_owned(wx, wz + 2) end
          if u == 1 then mark_slope_owned(wx, wz - 2) end
        end
      end
    end
  end

  -- Pass 2: one full straight per land|tech edge (inner corners included; 3-side skipped).
  for x = -size, size do
    for y = -size, size do
      local wx, wz = center_x + x * 4, center_y + y * 4
      if IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz)) then
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx + 4, 0, wz)) then
          try_straight(wx + 2, wz, 90, wx, wz)
        end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx - 4, 0, wz)) then
          try_straight(wx - 2, wz, 90, wx, wz)
        end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz + 4)) then
          try_straight(wx, wz + 2, 0, wx, wz)
        end
        if IsMsTile(TheWorld.Map:GetTileAtPoint(wx, 0, wz - 4)) then
          try_straight(wx, wz - 2, 0, wx, wz)
        end
      end
    end
  end

  -- Pass 3: outer tip — two bridge straights on this tech cell (deduped).
  for _, cell in ipairs(outers) do
    local wx, wz = cell.wx, cell.wz
    if cell.ru == 1 then
      try_straight(wx + 2, wz, 90, wx, wz)
      try_straight(wx, wz + 2, 0, wx, wz)
    elseif cell.rd == 1 then
      try_straight(wx + 2, wz, 90, wx, wz)
      try_straight(wx, wz - 2, 0, wx, wz)
    elseif cell.lu == 1 then
      try_straight(wx - 2, wz, 90, wx, wz)
      try_straight(wx, wz + 2, 0, wx, wz)
    else
      try_straight(wx - 2, wz, 90, wx, wz)
      try_straight(wx, wz - 2, 0, wx, wz)
    end
  end

  for id, s in pairs(straights) do
    add_piece(s.x, s.z, "straight", s.rot, s.void_x, s.void_z, "s_" .. id)
  end

  -- Slope mesh is center-authored: sit on the tech cell, rotate toward the open side.
  -- No land-edge straights around it, and no neighbor-center cap wall.
  for _, cell in ipairs(slopes) do
    local wx, wz = cell.wx, cell.wz
    local slope_rot = 180
    if cell.l == 1 and cell.d == 1 and cell.u == 1 then
      slope_rot = 90
    elseif cell.r == 1 and cell.d == 1 and cell.u == 1 then
      slope_rot = 270
    elseif cell.l == 1 and cell.r == 1 and cell.u == 1 then
      slope_rot = 0
    end
    add_piece(wx, wz, "slope", slope_rot, nil, nil, "slope")
  end

  CollectClimbSpawnEdges(self, level, center_x, center_y, size, wall)
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