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
TileGroups.MS_NON_CLOUDS = TileGroupManager:AddTileGroup()
TileGroups.MS_TECHNICAL = TileGroupManager:AddTileGroup()
TileGroups.MS_ICE_BRIDGE = TileGroupManager:AddTileGroup()

TileManager.AddTile(
    "CLOUDS_DARK",
    TileRanges.MS_CLOUDS,
    {ground_name = "Clouds Dark"},
    nil,
    {
        name = "map_edge",
        noise_texture = "ms_clouds_dark_noise",
    }
)



TileManager.AddTile(
    "CLOUDS_WHITE",
    TileRanges.MS_CLOUDS,
    {ground_name = "Clouds White"},
    nil,
    {
        name = "map_edge",
        noise_texture = "ms_clouds_noise",
    }
)

TileManager.AddTile(
    "VOID_TECHNICAL",
    TileRanges.IMPASSABLE,
    {ground_name = "Void technical"},
    {
        name="cave",
        noise_texture="ms_turf_void_technical",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
        is_shoreline = true,
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_LOW_TECHNICAL",
    TileRanges.LAND,
    {ground_name = "Void technical"},
    {
        name="deciduous",
        noise_texture="ms_turf_mountain",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_LOW_2_TECHNICAL",
    TileRanges.LAND,
    {ground_name = "Void technical"},
    {
        name="deciduous",
        noise_texture="ms_turf_mountain2",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_HIGH_TECHNICAL",
    TileRanges.LAND,
    {ground_name = "Void technical"},
    {
        name="rocky",
        noise_texture="ms_turf_mountain_high",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
    }
)

TileManager.AddTile(
    "MS_PERMAFROST_TECHNICAL",
    TileRanges.LAND,
    {ground_name = "Void technical"},
    {
        name="rocky",
        noise_texture="turf_permafrost",
        runsound="dontstarve/movement/run_dirt",
        walksound="dontstarve/movement/walk_dirt",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
    }
)

TileManager.AddTile(
    "MS_BRICK",
    TileRanges.LAND,
    {ground_name = "MS Brick"},
    {
        name = "blocky",
        noise_texture = "ms_turf_brick",
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
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

TileManager.AddTile(
    "MS_HIGHLAND",
    TileRanges.LAND,
    {ground_name = "MS Highland"},
    {
        name = "deciduous",
        noise_texture = "highland_start_turf",
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
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
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
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
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
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
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
    },
    {
        name="map_edge",
        noise_texture="ms_mountain_low_noise",
    },
    {
        name = "ms_mountain_low",
        bank_build = "turf_moon",
        pickupsound = "rock",
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
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
    },
    {
        name="map_edge",
        noise_texture="ms_mountain_low_2_noise",
    },
    {
        name = "ms_mountain_low_2",
        bank_build = "turf_moon",
        pickupsound = "rock",
        ms_tile = true,
    }
)

TileManager.AddTile(
    "MS_MOUNTAIN_HIGH",
    TileRanges.LAND,
    {ground_name = "MS Mountain high"},
    {
        name = "rocky",
        noise_texture = "ms_turf_mountain_high",
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
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
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
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
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
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
        runsound="dontstarve/movement/run_cavesbridge",
        walksound="dontstarve/movement/walk_cavesbridge",
        snowsound="dontstarve/movement/run_ice",
        mudsound="dontstarve/movement/run_mud",
        nogroundoverlays = true,
        cannotbedug = true,
        istemptile = true,
    },
    {
        name="map_edge",
        noise_texture="ice_bridge_noise",
    }
)


TileGroupManager:AddValidTile(TileGroups.MS_CLOUDS, WORLD_TILES.CLOUDS_WHITE)
TileGroupManager:AddValidTile(TileGroups.MS_CLOUDS, WORLD_TILES.CLOUDS_DARK)

TileGroupManager:AddValidTile(TileGroups.MS_NON_CLOUDS, WORLD_TILES.MS_HIGHLAND)
TileGroupManager:AddValidTile(TileGroups.MS_NON_CLOUDS, WORLD_TILES.MS_MOUNTAIN_LOW)
TileGroupManager:AddValidTile(TileGroups.MS_NON_CLOUDS, WORLD_TILES.MS_MOUNTAIN_LOW_2)
TileGroupManager:AddValidTile(TileGroups.MS_NON_CLOUDS, WORLD_TILES.MS_MOUNTAIN_HIGH)
TileGroupManager:AddValidTile(TileGroups.MS_NON_CLOUDS, WORLD_TILES.MS_SNOW)
TileGroupManager:AddValidTile(TileGroups.MS_NON_CLOUDS, WORLD_TILES.MS_PERMAFROST)

TileGroupManager:AddValidTile(TileGroups.MS_ICE_BRIDGE, WORLD_TILES.MS_BRIDGE)

TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.VOID_TECHNICAL)
TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL)
TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL)
TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL)
TileGroupManager:AddValidTile(TileGroups.MS_TECHNICAL, WORLD_TILES.MS_PERMAFROST_TECHNICAL)
mod_protect_TileManager = true