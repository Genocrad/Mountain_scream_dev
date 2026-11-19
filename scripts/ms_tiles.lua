-- This is The File to put all new tile-related stuff into.

local TileManager = require("tilemanager")

local TileRanges =
{
    LAND = "LAND",
    NOISE = "NOISE",
    OCEAN = "OCEAN",
    IMPASSABLE = "IMPASSABLE",
    MS_CLOUDS = "MS_CLOUDS",
}

mod_protect_TileManager = false

TileManager.RegisterTileRange(TileRanges.MS_CLOUDS, 40000, 40257)
--!!!!!!!!!!!!!!!!!!!
--Luigi: It is really unlikely, but possible that this tile range is taken already by another mod. Move the value up until the problem is solved. 40000 is just a random number i picked, it has no significance to code
--!!!!!!!!!!!!!!!!!!!

-- Special void type, that does not have a collision.
TileGroups.MS_CLOUDS = TileGroupManager:AddTileGroup()
TileGroups.MS_TECHNICAL = TileGroupManager:AddTileGroup()
TileGroups.MS_ICE_BRIDGE = TileGroupManager:AddTileGroup()
local cloud_regions = {}
local cloud_tiles = {}

-- Cloud IDs carry the region so any default-falloff land tile can use its cliffs.
for _, name in ipairs({ "LOW", "HIGH", "SNOW" }) do
    local region = { group = TileGroupManager:AddTileGroup() }
    TileGroups["MS_CLOUDS_" .. name] = region.group
    cloud_regions[#cloud_regions + 1] = region
    for _, colour in ipairs({ "DARK", "WHITE" }) do
        local tile_name = "CLOUDS_" .. colour .. "_" .. name
        TileManager.AddTile(
            tile_name,
            TileRanges.MS_CLOUDS,
            { ground_name = "Clouds " .. colour },
            nil,
            {
                name = "map_edge",
                noise_texture = colour == "DARK" and "ms_clouds_dark_noise" or "ms_clouds_noise",
            }
        )
        local tile = WORLD_TILES[tile_name]
        region[string.lower(colour)] = tile
        cloud_tiles[tile] = true
        TileGroupManager:AddValidTile(TileGroups.MS_CLOUDS, tile)
        TileGroupManager:AddValidTile(region.group, tile)
    end
end

TileManager.AddTile(
    "MS_MOUNTAIN_LOW_TECHNICAL",
    TileRanges.LAND,
    {ground_name = "Void technical"},
    {
        name="ms_edge",
        noise_texture="ms_turf_edge",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
        cannotbedug = true,
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_LOW_2_TECHNICAL",
    TileRanges.LAND,
    {ground_name = "Void technical"},
    {
        name="ms_edge",
        noise_texture="ms_turf_edge",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
        cannotbedug = true,
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_HIGH_TECHNICAL",
    TileRanges.LAND,
    {ground_name = "Void technical"},
    {
        name="ms_edge",
        noise_texture="ms_turf_edge",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
        cannotbedug = true,
    }
)

TileManager.AddTile(
    "MS_PERMAFROST_TECHNICAL",
    TileRanges.LAND,
    {ground_name = "Void technical"},
    {
        name="ms_edge",
        noise_texture="ms_turf_edge",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
        cannotbedug = true,
    }
)

TileManager.AddTile(
    "VOID_TECHNICAL",
    TileRanges.IMPASSABLE,
    {ground_name = "Void technical"},
    {
        name="void_technical_edge",
        noise_texture="ms_turf_void_technical",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
        cannotbedug = true,
    }
)

TileManager.AddTile(
    "MS_BRICK",
    TileRanges.LAND,
    {ground_name = "MS Brick"},
    {
        name = "blocky",
        noise_texture = "ms_turf_brick",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
    },
    {
        name="map_edge",
        noise_texture="ms_brick_noise",
    },
    {
        name = "ms_brick",
        bank_build = "turf_moon",
        pickupsound = "rock",
        ms_tile = true,
    }
)

TileManager.AddTile( -- Does this tile be used?
    "MS_HIGHLAND",
    TileRanges.LAND,
    {ground_name = "MS Highland"},
    {
        name = "deciduous",
        noise_texture = "highland_start_turf",
        runsound="dontstarve/movement/run_grass",
        walksound="dontstarve/movement/walk_grass",
        snowsound="dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_mud",
    },
    {
        name="map_edge",
        noise_texture="mini_forest_noise",
    },
    {
        name = "pebblebeach",
        bank_build = "turf_moon",
        pickupsound = "rock",
    }
)

-- This is for chill caves.
TileManager.AddTile(
    "MS_CAVE_FLOOR",
    TileRanges.LAND,
    {ground_name = "MS cave"},
    {
        name = "blocky",
        noise_texture = "ms_turf_void_technical",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        cannotbedug = true,
    }

)
-- This is for crafted turf. 
TileManager.AddTile(
    "MS_CAVE",
    TileRanges.LAND,
    {ground_name = "MS cave"},
    {
        name = "blocky",
        noise_texture = "ms_turf_cave",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
    },
    {
        name="map_edge",
        noise_texture="ms_cave_noise",
    },
    {
        name = "ms_cave",
        bank_build = "turf_moon",
        pickupsound = "rock",
        ms_tile = true,
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_LOW",
    TileRanges.LAND,
    {ground_name = "MS Mountain low"},
    {
        name = "deciduous",
        noise_texture = "ms_turf_mountain",
        runsound="dontstarve/movement/run_grass",
        walksound="dontstarve/movement/walk_grass",
        snowsound="dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_mud",
    },
    {
        name="map_edge",
        noise_texture="ms_mountain_low_noise",
    },
    {
        name = "ms_mountain_low",
        bank_build = "turf_moon",
        pickupsound = "vegetation_grassy",
        ms_tile = true,
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_LOW_2",
    TileRanges.LAND,
    {ground_name = "MS Mountain low"},
    {
        name = "deciduous",
        noise_texture = "ms_turf_mountain2",
        runsound="dontstarve/movement/run_grass",
        walksound="dontstarve/movement/walk_grass",
        snowsound="dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_mud",
    },
    {
        name="map_edge",
        noise_texture="ms_mountain_low_2_noise",
    },
    {
        name = "ms_mountain_low_2",
        bank_build = "turf_moon",
        pickupsound = "vegetation_grassy",
        ms_tile = true,
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_HIGH",
    TileRanges.LAND,
    {ground_name = "MS Mountain high"},
    {
        name = "ms_edge",
        noise_texture = "ms_turf_mountain_high",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
    },
    {
        name="map_edge",
        noise_texture="ms_mountain_high_noise",
    },
    {
        name = "ms_mountain_high",
        bank_build = "turf_moon",
        pickupsound = "rock",
        ms_tile = true,
    }
)



TileManager.AddTile(
    "MS_PERMAFROST",
    TileRanges.LAND,
    {ground_name = "MS Permafrost"},
    {
        name = "rocky",
        noise_texture = "turf_permafrost",
        runsound="dontstarve/movement/run_ice",
        walksound="dontstarve/movement/run_ice",
        walksound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_ice",
    },
    {
        name="map_edge",
        noise_texture="ms_permafrost_noise",
    },
    {
        name = "ms_permafrost",
        bank_build = "turf_moon",
        pickupsound = "rock",
        ms_tile = true,
    }
)

TileManager.AddTile(
    "MS_SNOW",
    TileRanges.LAND,
    {ground_name = "MS Snow"},
    {
        name = "snowfall",
        noise_texture = "ms_snow_turf",
        runsound="dontstarve/movement/run_snow",
        walksound="dontstarve/movement/run_snow",
        snowsound="dontstarve/movement/run_snow",
        mudsound = "dontstarve/movement/run_snow",
        istemptile = true,
    },
    {
        name="map_edge",
        noise_texture="ms_snow_noise",
    },
    {
        name = "ms_snow",
        bank_build = "turf_moon",
        pickupsound = "rock",
    }
)

-- Same as ROPE_BRIDGE, but we do not want it collapsing.
TileManager.AddTile(
    "MS_BRIDGE",
    TileRanges.LAND,
    {ground_name = "MS Bridge"},
    {
        name="blocky",
        noise_texture="ice_bridge_turf",
        runsound="dontstarve/movement/run_iceslab",
        walksound="dontstarve/movement/walk_iceslab",
        snowsound="dontstarve/movement/walk_iceslab",
        mudsound="dontstarve/movement/walk_iceslab",
        nogroundoverlays = true,
        cannotbedug = true,
        istemptile = true,
    },
    {
        name="map_edge",
        noise_texture="ice_bridge_noise",
    }
)

-- move technical tiles down
TileManager.ChangeTileRenderOrder(WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL, WORLD_TILES.QUAGMIRE_GATEWAY)
TileManager.ChangeTileRenderOrder(WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL, WORLD_TILES.QUAGMIRE_GATEWAY)
TileManager.ChangeTileRenderOrder(WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL, WORLD_TILES.QUAGMIRE_GATEWAY)
TileManager.ChangeTileRenderOrder(WORLD_TILES.MS_PERMAFROST_TECHNICAL, WORLD_TILES.QUAGMIRE_GATEWAY)

TileGroupManager:AddValidTile(TileGroups.MS_ICE_BRIDGE, WORLD_TILES.MS_BRIDGE)

TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.VOID_TECHNICAL)
TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL)
TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL)
TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL)
TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.MS_PERMAFROST_TECHNICAL)
mod_protect_TileManager = true

-- Luigi: Idk where to put this otherwise 
-- Values are for contentspawner component

TURF_NUMBER_TO_NAME = {
  [WORLD_TILES.ROCKY] = "rocky",
  [WORLD_TILES.MS_MOUNTAIN_LOW] = "ms_mountain_low",
  [WORLD_TILES.MS_MOUNTAIN_LOW_2] = "ms_mountain_low_2",
  [WORLD_TILES.MS_MOUNTAIN_HIGH] = "ms_mountain_high",
  [WORLD_TILES.MS_PERMAFROST] = "ms_permafrost",
}

local function GetCloudTile(level, dark)
    -- Destination geographic levels: low 1-3, high 4-6, snow 7-10.
    local region = cloud_regions[level >= 7 and 3 or level >= 4 and 2 or 1]
    return dark and region.dark or region.white
end

return {
    cloud_regions = cloud_regions,
    GetCloudTile = GetCloudTile,
    IsCloudTile = function(tile) return cloud_tiles[tile] == true end,
}
