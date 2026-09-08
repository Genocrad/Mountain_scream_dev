local prefabs =
{
	"ms_arenateleporter",
	"ms_shortcut_exit",
	"ms_broken_pillar",
}

local PILLAR_STAGES = { "full", "med", "short" }

-- Relative to the first (arena) pad center; second pad is +8 along the long axis.
local PILLAR_OFFSETS_ALONG_X =
{
	{ -4,  4 },
	{ -4, -4 },
	{  4,  4 },
	{  4, -4 },
	{ 12,  4 },
	{ 12, -4 },
}

local PILLAR_OFFSETS_ALONG_Z =
{
	{  4, -4 },
	{ -4, -4 },
	{  4,  4 },
	{ -4,  4 },
	{  4, 12 },
	{ -4, 12 },
}

local function SpawnPillar(x, z)
	local pillar = SpawnPrefab("ms_broken_pillar")
	pillar.Transform:SetPosition(x, 0, z)
	pillar:SetStage(PILLAR_STAGES[math.random(#PILLAR_STAGES)])
	return pillar
end

local function TileJunctionCenter(tx, tz)
	local x1, _, z1 = TheWorld.Map:GetTileCenterPoint(tx, tz)
	local x2, _, z2 = TheWorld.Map:GetTileCenterPoint(tx + 1, tz + 1)
	return (x1 + x2) * 0.5, (z1 + z2) * 0.5
end

local function Build(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local tx, tz = TheWorld.Map:GetTileXYAtPoint(x, 0, z)
	local along_x = math.random() < 0.5

	local arena_cx, arena_cz
	local shortcut_cx, shortcut_cz
	local pillar_offsets

	if along_x then
		-- 4x2: arena on the left, shortcut_exit on the right.
		for dx = 0, 3 do
			for dz = 0, 1 do
				TheWorld.Map:SetTile(tx + dx, tz + dz, WORLD_TILES.MS_BRICK)
			end
		end
		arena_cx, arena_cz = TileJunctionCenter(tx, tz)
		shortcut_cx, shortcut_cz = TileJunctionCenter(tx + 2, tz)
		pillar_offsets = PILLAR_OFFSETS_ALONG_X
	else
		-- 2x4: arena on the near side, shortcut_exit on the far side.
		for dx = 0, 1 do
			for dz = 0, 3 do
				TheWorld.Map:SetTile(tx + dx, tz + dz, WORLD_TILES.MS_BRICK)
			end
		end
		arena_cx, arena_cz = TileJunctionCenter(tx, tz)
		shortcut_cx, shortcut_cz = TileJunctionCenter(tx, tz + 2)
		pillar_offsets = PILLAR_OFFSETS_ALONG_Z
	end

	local arenateleporter = SpawnPrefab("ms_arenateleporter")
	arenateleporter.Transform:SetPosition(arena_cx, 0, arena_cz)

	local shortcut_exit = SpawnPrefab("ms_shortcut_exit")
	shortcut_exit.Transform:SetPosition(shortcut_cx, 0, shortcut_cz)

	for _, offset in ipairs(pillar_offsets) do
		SpawnPillar(arena_cx + offset[1], arena_cz + offset[2])
	end

	inst:Remove()
	return arenateleporter, shortcut_exit
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()

	inst:AddTag("CLASSIFIED")
	inst:AddTag("NOBLOCK")
	inst:AddTag("NOCLICK")

	inst.persists = false
	inst.Build = Build

	return inst
end

return Prefab("ms_twin_portal_scene", fn, nil, prefabs)
