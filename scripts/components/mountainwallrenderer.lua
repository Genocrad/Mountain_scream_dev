-- Client-side streaming renderer for MountainWalls edge / corner / slope data.
-- Collision stays on tile edges (Map TileCollisionSet); these entities are FX only.

local KIND_PREFAB = {
	straight = "ms_mountain_wall",
	corner_right = "ms_mountain_corner_wall_right",
	corner_left = "ms_mountain_corner_wall_left",
	slope = "ms_mountain_slope",
}

local MountainWallRenderer = Class(function(self, inst)
	self.inst = inst
	self.radius = 18 * TILE_SCALE
	self.tiles = {} -- [id] = wall entity
	self.currenttile = Vector3(0, 0, 0)
	self.rebuild = nil

	self.inst:StartUpdatingComponent(self)
end)

local function ParseId(id)
	local x, z = string.match(id, "^([^|]+)|([^|]+)")
	if x == nil then
		return nil, nil
	end
	return tonumber(x), tonumber(z)
end

function MountainWallRenderer:SpawnWall(id, data)
	if data == nil then
		return
	end

	local kind = data.kind or "straight"
	local wall_type = data.type or ""
	local base = KIND_PREFAB[kind] or KIND_PREFAB.straight
	local wall = SpawnPrefab(base .. wall_type)
	if wall == nil then
		return
	end

	wall.persists = false

	local x = data.x
	local z = data.z
	if x == nil or z == nil then
		x, z = ParseId(id)
	end
	if x == nil then
		wall:Remove()
		return
	end

	local rot = data.rot
	if rot == nil then
		-- Legacy straight entries: derive yaw from void side.
		local void_x = data.void_x or x
		local void_z = data.void_z or z
		if math.abs((void_x or x) - x) > math.abs((void_z or z) - z) then
			rot = 90
		else
			rot = 0
		end
	end

	wall.Transform:SetPosition(x, 0, z)
	wall.Transform:SetRotation(rot)

	self.tiles[id] = wall
end

function MountainWallRenderer:RemoveWall(id)
	local ent = self.tiles[id]
	if ent ~= nil and ent:IsValid() then
		ent:Remove()
	end
	self.tiles[id] = nil
end

function MountainWallRenderer:RebuildAll()
	for id in pairs(self.tiles) do
		self:RemoveWall(id)
	end

	if ThePlayer ~= nil and TheWorld ~= nil and TheWorld.Map ~= nil then
		local x, y, z = ThePlayer.Transform:GetWorldPosition()
		local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(x, y, z)
		if cx ~= nil then
			self.currenttile = Vector3(cx, cy, cz)
			self:Rebuild()
			return
		end
	end

	self.currenttile = Vector3(0, 0, 0)
	self.rebuild = true
end

function MountainWallRenderer:OnUpdate()
	if ThePlayer == nil then
		return
	end
	if TheWorld == nil or TheWorld.Map == nil then
		return
	end
	local mountain_walls = rawget(_G, "MountainWalls")
	if mountain_walls == nil then
		return
	end

	local x, y, z = ThePlayer.Transform:GetWorldPosition()
	local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(x, y, z)
	if cx == nil then
		return
	end
	local pos = Vector3(cx, cy, cz)

	if pos.x ~= self.currenttile.x or pos.z ~= self.currenttile.z or self.rebuild then
		self.currenttile = pos
		self:Rebuild()
	end
end

function MountainWallRenderer:Rebuild()
	local list = {}
	local half = self.radius * 0.5
	local px, pz = self.currenttile.x, self.currenttile.z
	local mountain_walls = rawget(_G, "MountainWalls")

	if mountain_walls ~= nil then
		for id, data in pairs(mountain_walls) do
			local wx = data.x
			local wz = data.z
			if wx == nil or wz == nil then
				wx, wz = ParseId(id)
			end
			if wx ~= nil and math.abs(wx - px) <= half and math.abs(wz - pz) <= half then
				list[id] = true
				if self.tiles[id] == nil or (self.rebuild ~= nil and self.rebuild[id]) then
					if self.tiles[id] ~= nil then
						self:RemoveWall(id)
					end
					self:SpawnWall(id, data)
				end
			end
		end
	end

	for id in pairs(self.tiles) do
		if not list[id] then
			self:RemoveWall(id)
		end
	end

	self.rebuild = nil
end

return MountainWallRenderer
