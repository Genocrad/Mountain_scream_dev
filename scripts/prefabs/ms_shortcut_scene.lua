local prefabs =
{
	"ms_shortcut",
	"ms_broken_pillar",
}

local PILLAR_STAGES = { "full", "med", "short" }

-- Opposite corner pairs for a 2x2 pad (outer corners at ±4 from center).
local DIAGONAL_PILLAR_PAIRS =
{
	{
		{  4,  4 },
		{ -4, -4 },
	},
	{
		{  4, -4 },
		{ -4,  4 },
	},
}

local function SpawnPillar(x, z)
	local pillar = SpawnPrefab("ms_broken_pillar")
	pillar.Transform:SetPosition(x, 0, z)
	pillar:SetStage(PILLAR_STAGES[math.random(#PILLAR_STAGES)])
	return pillar
end

local function Build(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local tx, tz = TheWorld.Map:GetTileXYAtPoint(x, 0, z)

	for dx = 0, 1 do
		for dz = 0, 1 do
			TheWorld.Map:SetTile(tx + dx, tz + dz, WORLD_TILES.MS_BRICK)
		end
	end

	-- Snap to the 2x2 junction so turf and pillars stay aligned.
	local x1, _, z1 = TheWorld.Map:GetTileCenterPoint(tx, tz)
	local x2, _, z2 = TheWorld.Map:GetTileCenterPoint(tx + 1, tz + 1)
	local cx, cz = (x1 + x2) * 0.5, (z1 + z2) * 0.5

	local shortcut = SpawnPrefab("ms_shortcut")
	shortcut.Transform:SetPosition(cx, 0, cz)

	local pair = DIAGONAL_PILLAR_PAIRS[math.random(#DIAGONAL_PILLAR_PAIRS)]
	for _, offset in ipairs(pair) do
		SpawnPillar(cx + offset[1], cz + offset[2])
	end

	inst:Remove()
	return shortcut
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

return Prefab("ms_shortcut_scene", fn, nil, prefabs)
