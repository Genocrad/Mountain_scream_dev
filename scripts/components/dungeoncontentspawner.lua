-- Fills mountain floors after terraforming, using weighted tables similar to
-- vanilla Room distributeprefabs (see tmp_ref/scripts/map/rooms/forest/terrain_rocky.lua).

local CLEAR_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR", "CLASSIFIED", "NOBLOCK", "player", "walkableplatform", "walkingplank" }

local function IsSpawnableMountainTile(tile)
	return tile == WORLD_TILES.MS_MOUNTAIN_LOW
		or tile == WORLD_TILES.MS_MOUNTAIN_LOW_2
		or tile == WORLD_TILES.MS_MOUNTAIN_HIGH
		or tile == WORLD_TILES.MS_PERMAFROST
		or tile == WORLD_TILES.MS_SNOW
end

local function IsSpawnableCaveTile(tile)
	return tile == WORLD_TILES.MS_CAVE_FLOOR
end

-- Tuning may list a group name (e.g. mountain_green_stone); resolve to a real _1..n prefab.
local function ResolveVariantPrefab(name)
	local variants = TUNING.MS_VARIANT_GROUPS ~= nil and TUNING.MS_VARIANT_GROUPS[name] or nil
	if variants ~= nil and #variants > 0 then
		return variants[math.random(#variants)]
	end
	return name
end

local function PickPrefab(weights)
	local total = 0
	for _, weight in pairs(weights) do
		total = total + weight
	end
	if total <= 0 then
		return nil
	end

	local rnd = math.random() * total
	for prefab, weight in pairs(weights) do
		rnd = rnd - weight
		if rnd <= 0 then
			return ResolveVariantPrefab(prefab)
		end
	end
end

local function IsPointClear(x, z, radius)
	local ents = TheSim:FindEntities(x, 0, z, radius, nil, CLEAR_CANT_TAGS)
	return ents == nil or #ents == 0
end

local function IsValidSpawnPoint(x, z, clear_radius)
	local map = TheWorld.Map
	return x ~= nil and z ~= nil
		and IsSpawnableMountainTile(map:GetTileAtPoint(x, 0, z))
		and map:IsPassableAtPoint(x, 0, z)
		and IsPointClear(x, z, clear_radius)
end

local function FindMemberPosition(cx, cz, radius, index, count)
	local map = TheWorld.Map
	local angle = (index - 1) * TWOPI / count
	for attempt = 1, 8 do
		local r = radius * (0.55 + math.random() * 0.55)
		local a = angle + (math.random() - 0.5) * 0.35
		local x = cx + math.cos(a) * r
		local z = cz + math.sin(a) * r
		if IsSpawnableMountainTile(map:GetTileAtPoint(x, 0, z)) and map:IsPassableAtPoint(x, 0, z) then
			return x, z
		end
	end
	return cx, cz
end

-- Uniform fill over the disk [0, radius] (area-weighted via sqrt).
local function FindMemberPositionInDisk(cx, cz, radius)
	local map = TheWorld.Map
	for _ = 1, 8 do
		local a = math.random() * TWOPI
		local r = radius * math.sqrt(math.random())
		local x = cx + math.cos(a) * r
		local z = cz + math.sin(a) * r
		if IsSpawnableMountainTile(map:GetTileAtPoint(x, 0, z)) and map:IsPassableAtPoint(x, 0, z) then
			return x, z
		end
	end
	return cx, cz
end

local function PickMemberPosition(cx, cz, radius, index, count, fill)
	if fill == "disk" then
		return FindMemberPositionInDisk(cx, cz, radius)
	end
	return FindMemberPosition(cx, cz, radius, index, count)
end

local function SpawnHerdAt(cx, cz, def)
	local member_prefab = def.prefab or "mountain_goat"
	local size = def.size or (TUNING.MOUNTAIN_GOATHERD and TUNING.MOUNTAIN_GOATHERD.MAX_SIZE) or 8
	local radius = (TUNING.MOUNTAIN_GOATHERD and TUNING.MOUNTAIN_GOATHERD.SPAWN_RADIUS) or 4

	local herd = SpawnPrefab("mountain_goatherd")
	if herd == nil then
		return 0
	end
	herd.Transform:SetPosition(cx, 0, cz)

	local spawned = 0
	for i = 1, size do
		local x, z = FindMemberPosition(cx, cz, radius, i, size)
		local goat = SpawnPrefab(member_prefab)
		if goat ~= nil then
			goat.Transform:SetPosition(x, 0, z)
			if herd.components.herd ~= nil then
				herd.components.herd:AddMember(goat)
			end
			spawned = spawned + 1
		end
	end

	if spawned == 0 then
		herd:Remove()
	end
	return spawned
end

local function BuildCommunityMembers(def)
	local members = {}
	for _, member_def in ipairs(def.members or {}) do
		if member_def.prefab ~= nil then
			local min = member_def.min or 1
			local max = member_def.max or min
			if max < min then
				max = min
			end
			local n = math.random(min, max)
			for _ = 1, n do
				table.insert(members, member_def.prefab)
			end
		end
	end

	for i = #members, 2, -1 do
		local j = math.random(i)
		members[i], members[j] = members[j], members[i]
	end

	return members
end

local function SpawnCommunityAt(cx, cz, def)
	local community_tuning = TUNING.MOUNTAIN_KIKI_COMMUNITY
	local radius = def.radius
		or (community_tuning and community_tuning.SPAWN_RADIUS)
		or 10
  local tile = def.tile 
  local preplacefn = def.preplacefn
	local member_clear = def.member_clear_radius
		or (community_tuning and community_tuning.MEMBER_CLEAR_RADIUS)
		or 1.75
	local fill = def.fill -- nil/"ring" (default) or "disk"
  
  if preplacefn then
    preplacefn(cx, cz)
  end
  
	local members = BuildCommunityMembers(def)
	local count = #members
	if count == 0 then
		return 0
	end

	local spawned = 0
	for i, prefab in ipairs(members) do
		local x, z
		local placed = false
		for _ = 1, 8 do
			x, z = PickMemberPosition(cx, cz, radius, i, count, fill)
			if IsValidSpawnPoint(x, z, member_clear) then
				placed = true
				break
			end
		end
		if not placed then
			x, z = PickMemberPosition(cx, cz, radius, i, count, fill)
			if not (IsSpawnableMountainTile(TheWorld.Map:GetTileAtPoint(x, 0, z))
					and TheWorld.Map:IsPassableAtPoint(x, 0, z)) then
				x, z = cx, cz
			end
		end

		local ent = SpawnPrefab(prefab)
		if ent ~= nil then
			ent.Transform:SetPosition(x, 0, z)
			spawned = spawned + 1
		end
	end
  
  if tile then
    local center_x, center_y = TheWorld.Map:GetTileXYAtPoint(cx, 0, cz)
    local tileradius = def.tileradius or 5
    for tile_i = -tileradius, tileradius do
      for tile_j = -tileradius, tileradius do
        if tile_i * tile_i + tile_j * tile_j < tileradius * tileradius + 4 and
          IsSpawnableMountainTile(TheWorld.Map:GetTile(center_x + tile_i, center_y + tile_j)) then 
            TheWorld.Map:SetTile(center_x + tile_i, center_y + tile_j, tile)
        end
      end
    end
  end
	return spawned
end

local DungeonContentSpawner = Class(function(self, inst)
	self.inst = inst
	self.spawned = false
end)

function DungeonContentSpawner:SpawnLevelDecor(level)
	local contents = TUNING.MS_LEVEL_CONTENTS[level]
	if contents == nil or contents.distributeprefabs == nil then
		return 0
	end

	local overwatch = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch or nil
	if overwatch == nil then
		return 0
	end

	local points = overwatch:GetMobSpawnPoints(level)
	if points == nil or #points == 0 then
		return 0
	end

	local chance = (contents.distributepercent or 0) * (TUNING.MS_CONTENT_POINT_SAMPLE or (1 / 3))
	local clear_radius = TUNING.MS_CONTENT_CLEAR_RADIUS or 1.25
	local map = TheWorld.Map
	local spawned = 0

	for _, point in ipairs(points) do
		local x, z = point.x, point.y
    local current_tile = map:GetTileAtPoint(x, 0, z)
		if x ~= nil and z ~= nil
			and math.random() < chance
			and IsSpawnableMountainTile(current_tile)
			and map:IsPassableAtPoint(x, 0, z)
			and IsPointClear(x, z, clear_radius)
		then
      local full_table = {}
      for k, v in pairs(contents.distributeprefabs["any"]) do 
        full_table[k] = v
      end
      
      if contents.distributeprefabs[TURF_NUMBER_TO_NAME[current_tile]] then
        for k, v in pairs(contents.distributeprefabs[TURF_NUMBER_TO_NAME[current_tile]]) do 
          full_table[k] = v
        end      
      end
			local prefab = PickPrefab(full_table)
			if prefab ~= nil then
				local ent = SpawnPrefab(prefab)
				if ent ~= nil then
					ent.Transform:SetPosition(x, 0, z)
					spawned = spawned + 1
				end
			end
		end
	end

	return spawned
end

function DungeonContentSpawner:SpawnLevelHerds(level)
	local contents = TUNING.MS_LEVEL_CONTENTS[level]
	if contents == nil or contents.herds == nil then
		return 0
	end

	local overwatch = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch or nil
	if overwatch == nil then
		return 0
	end

	local points = overwatch:GetMobSpawnPoints(level)
	if points == nil or #points == 0 then
		return 0
	end

	local clear_radius = (TUNING.MOUNTAIN_GOATHERD and TUNING.MOUNTAIN_GOATHERD.CENTER_CLEAR_RADIUS) or 6
	local attempts = (TUNING.MOUNTAIN_GOATHERD and TUNING.MOUNTAIN_GOATHERD.CENTER_ATTEMPTS) or 40
	local spawned = 0

	for _, def in ipairs(contents.herds) do
		local count = def.count or 1
		for _ = 1, count do
			local placed = false
			for _ = 1, attempts do
				local point = points[math.random(#points)]
				local x, z = point.x, point.y
				if IsValidSpawnPoint(x, z, clear_radius) then
					spawned = spawned + SpawnHerdAt(x, z, def)
					placed = true
					break
				end
			end
			if not placed then
				-- Fallback: first passable mountain point, ignore clutter.
				for _, point in ipairs(points) do
					local x, z = point.x, point.y
					if x ~= nil and z ~= nil
						and IsSpawnableMountainTile(TheWorld.Map:GetTileAtPoint(x, 0, z))
						and TheWorld.Map:IsPassableAtPoint(x, 0, z)
					then
						spawned = spawned + SpawnHerdAt(x, z, def)
						break
					end
				end
			end
		end
	end

	return spawned
end

function DungeonContentSpawner:SpawnLevelCommunities(level)
	local contents = TUNING.MS_LEVEL_CONTENTS[level]
	if contents == nil or contents.communities == nil then
		return 0
	end

	local overwatch = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch or nil
	if overwatch == nil then
		return 0
	end

	local points = overwatch:GetMobSpawnPoints(level)
	if points == nil or #points == 0 then
		return 0
	end

	local community_tuning = TUNING.MOUNTAIN_KIKI_COMMUNITY
	local clear_radius = (community_tuning and community_tuning.CENTER_CLEAR_RADIUS) or 8
	local attempts = (community_tuning and community_tuning.CENTER_ATTEMPTS) or 40
	local spawned = 0

	for _, def in ipairs(contents.communities) do
		local count = def.count
		if count == nil and def.min_count ~= nil then
			count = math.random(def.min_count, def.max_count or def.min_count)
		else
			count = count or 1
		end
		local center_clear = def.clear_radius or clear_radius
		for _ = 1, count do
			local placed = false
			for _ = 1, attempts do
				local point = points[math.random(#points)]
				local x, z = point.x, point.y
				if IsValidSpawnPoint(x, z, center_clear) then
					spawned = spawned + SpawnCommunityAt(x, z, def)
					placed = true
					break
				end
			end
			if not placed then
				for _, point in ipairs(points) do
					local x, z = point.x, point.y
					if x ~= nil and z ~= nil
						and IsSpawnableMountainTile(TheWorld.Map:GetTileAtPoint(x, 0, z))
						and TheWorld.Map:IsPassableAtPoint(x, 0, z)
					then
						spawned = spawned + SpawnCommunityAt(x, z, def)
						break
					end
				end
			end
		end
	end

	return spawned
end

function DungeonContentSpawner:SpawnLevelCaveDecor(level)
	local contents = TUNING.MS_LEVEL_CONTENTS[level]
	local cave = contents ~= nil and contents.cave or nil
	if cave == nil or cave.distributeprefabs == nil then
		return 0
	end

	local overwatch = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch or nil
	if overwatch == nil then
		return 0
	end

	local points = overwatch:GetMobSpawnPoints(level)
	if points == nil or #points == 0 then
		return 0
	end

	-- Cave spawn points are already filtered room samples (~30/room); no POINT_SAMPLE.
	local chance = cave.distributepercent or 0
	local clear_radius = cave.clear_radius or TUNING.MS_CONTENT_CLEAR_RADIUS or 1.25
	local map = TheWorld.Map
	local spawned = 0

	for _, point in ipairs(points) do
		local x, z = point.x, point.y
		if x ~= nil and z ~= nil
			and math.random() < chance
			and IsSpawnableCaveTile(map:GetTileAtPoint(x, 0, z))
			and map:IsPassableAtPoint(x, 0, z)
			and IsPointClear(x, z, clear_radius)
		then
			local prefab = PickPrefab(cave.distributeprefabs)
			if prefab ~= nil then
				local ent = SpawnPrefab(prefab)
				if ent ~= nil then
					ent.Transform:SetPosition(x, 0, z)
					spawned = spawned + 1
				end
			end
		end
	end

  local caves = self:SpawnOnWallEntities(level)
	return spawned + caves
end

function DungeonContentSpawner:SpawnOnWallEntities(level)
  local contents = TUNING.MS_LEVEL_WALL_CONTENTS[level]
  local map = TheWorld.Map
  local points = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch and TheWorld.net.components.dungeonmapoverwatch:GetOnWallSpawnPoints(level)
  if not points or not contents then
    return 0
  end
  local chance = contents.distributepercent
  local spawned = 0
  for _, point in ipairs(points) do
    local x, y, z, angle = point.x, point.y, point.z, point.angle
    local distributeprefabs = contents.distributeprefabs
    if IsSpawnableCaveTile(map:GetTileAtPoint(x, 0, z)) then
      distributeprefabs = contents.cavedistributeprefabs
    end
    if math.random()< chance then
      local prefab = PickPrefab(distributeprefabs)
      local ent = SpawnPrefab(prefab)
      ent.Transform:SetPosition(x, y, z)
      ent.Transform:SetRotation(angle)
      spawned = spawned + 1
    end
  end
  return spawned
end

function DungeonContentSpawner:SpawnLevel(level)
	-- Herds / communities first so centers are not blocked by decor clutter.
	local herds = self:SpawnLevelHerds(level)
	local communities = self:SpawnLevelCommunities(level)
	local decor = self:SpawnLevelDecor(level)
	local cave = self:SpawnLevelCaveDecor(level)
  local walls = self:SpawnOnWallEntities(level)
	return decor + herds + communities + cave + walls
end



function DungeonContentSpawner:SpawnConfiguredLevels()
	if self.spawned then
		return
	end
	self.spawned = true

	for level, _ in pairs(TUNING.MS_LEVEL_CONTENTS) do
		self:SpawnLevel(level)
	end
end

function DungeonContentSpawner:OnSave()
	return {
		spawned = self.spawned,
	}
end

function DungeonContentSpawner:OnLoad(data)
	if data ~= nil then
		self.spawned = data.spawned == true
	end
end

return DungeonContentSpawner
