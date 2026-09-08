local prefabs =
{
	"ms_worldmigrator_up",
	"ms_broken_pillar",
}

local PILLAR_STAGES = { "full", "med", "short" }

local PILLAR_OFFSETS =
{
	{  4,  4 },
	{  4, -4 },
	{ -4,  4 },
	{ -4, -4 },
}

local function SpawnPillar(x, z)
	local pillar = SpawnPrefab("ms_broken_pillar")
	pillar.Transform:SetPosition(x, 0, z)
	pillar:SetStage(PILLAR_STAGES[math.random(#PILLAR_STAGES)])
	return pillar
end

local function Build(inst)
	local x, y, z = inst.Transform:GetWorldPosition()

	-- Pillars sit one tile out (±4); paint the full 3x3 brick pad under them.
	local tx, tz = TheWorld.Map:GetTileXYAtPoint(x, 0, z)
	for dx = -1, 1 do
		for dz = -1, 1 do
			TheWorld.Map:SetTile(tx + dx, tz + dz, WORLD_TILES.MS_BRICK)
		end
	end

	local migrator = SpawnPrefab("ms_worldmigrator_up")
	migrator.Transform:SetPosition(x, 0, z)

	for _, offset in ipairs(PILLAR_OFFSETS) do
		SpawnPillar(x + offset[1], z + offset[2])
	end

	inst:Remove()
	return migrator
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

return Prefab("ms_worldmigrator_up_scene", fn, nil, prefabs)
