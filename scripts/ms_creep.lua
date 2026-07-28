local TileManager = require("tilemanager")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

-- Needs to be loaded after tiles

mod_protect_TileManager = false

GROUND_CREEP_IDS.SNOW = GetTableSize(FALLOFF_IDS)

TileManager.AddGroundCreep(
    GROUND_CREEP_IDS.SNOW,
    {
        name = "web",
        noise_texture = "ms_snow_turf",
    }
)

mod_protect_TileManager = true
