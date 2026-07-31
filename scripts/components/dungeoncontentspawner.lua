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
			return prefab
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
		if x ~= nil and z ~= nil
			and math.random() < chance
			and IsSpawnableMountainTile(map:GetTileAtPoint(x, 0, z))
			and map:IsPassableAtPoint(x, 0, z)
			and IsPointClear(x, z, clear_radius)
		then
			local prefab = PickPrefab(contents.distributeprefabs)
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

function DungeonContentSpawner:SpawnLevel(level)
	-- Herds first so centers are not blocked by decor clutter.
	local herds = self:SpawnLevelHerds(level)
	local decor = self:SpawnLevelDecor(level)
	return decor + herds
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
