local MountainTiles = require("ms_tiles")

-- Keep the native land membership, including tiles registered by other mods.
TileGroups.MS_LAND_WITH_FALLOFF = TileGroupManager:AddTileGroup(TileGroups.LandTilesWithDefaultFalloff)
TileGroupManager:AddInvalidTile(TileGroups.MS_LAND_WITH_FALLOFF, WORLD_TILES.MS_BRIDGE)

-- Clouds suppress adjacent vanilla cliffs without becoming cliff sources.
TileGroups.MS_DEFAULT_FALLOFF_NEIGHBORS = TileGroupManager:AddTileGroup(TileGroups.LandTilesWithDefaultFalloff)
TileGroupManager:AddValidTile(TileGroups.MS_DEFAULT_FALLOFF_NEIGHBORS, WORLD_TILES.MS_BRIDGE)
for _, region in ipairs(MountainTiles.cloud_regions) do
    TileGroupManager:AddValidTile(TileGroups.MS_DEFAULT_FALLOFF_NEIGHBORS, region.white)
    TileGroupManager:AddValidTile(TileGroups.MS_DEFAULT_FALLOFF_NEIGHBORS, region.dark)
end

SetFalloffProperty(FALLOFF_IDS.FALLOFF, "should_have_falloff", TileGroups.MS_LAND_WITH_FALLOFF)
SetFalloffProperty(FALLOFF_IDS.FALLOFF, "should_have_falloff_result", true)
SetFalloffProperty(FALLOFF_IDS.FALLOFF, "neighbor_needs_falloff", TileGroups.MS_DEFAULT_FALLOFF_NEIGHBORS)
SetFalloffProperty(FALLOFF_IDS.FALLOFF, "neighbor_needs_falloff_result", false)

local next_id = 0
for _, id in pairs(FALLOFF_IDS) do
    next_id = math.max(next_id, id)
end

local function AddMountainFalloff(id_name, texture, land_group, neighbor_group, neighbor_result)
    next_id = next_id + 1
    FALLOFF_IDS[id_name] = next_id
    AddFalloffTexture(next_id, {
        name = texture,
        noise_texture = "square.tex",
        should_have_falloff = land_group,
        should_have_falloff_result = true,
        neighbor_needs_falloff = neighbor_group,
        neighbor_needs_falloff_result = neighbor_result,
    })
end

for i, region in ipairs(MountainTiles.cloud_regions) do
    AddMountainFalloff("MS_FALLOFF_" .. i, "ms_falloff_" .. i,
        TileGroups.MS_LAND_WITH_FALLOFF, region.group, true)
end

AddMountainFalloff("ICE_BRIDGE_FALLOFF", "ice_bridge_falloff",
    TileGroups.MS_ICE_BRIDGE, TileGroups.MS_ICE_BRIDGE, false)
