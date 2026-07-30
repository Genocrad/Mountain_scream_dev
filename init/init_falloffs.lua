local TileManager = require("tilemanager")

-- Needs to be loaded after tiles

GLOBAL.mod_protect_TileManager = false

FALLOFF_IDS.MOUNTAIN_FALLOFF = GetTableSize(FALLOFF_IDS)

print("FALLOFF_IDS", FALLOFF_IDS.MOUNTAIN_FALLOFF)

TileManager.AddFalloffTexture(
	FALLOFF_IDS.MOUNTAIN_FALLOFF,
	{
		name = "mountain_falloff",
		noise_texture = "square.tex",
		neighbor_needs_falloff = TileGroups.MS_CLOUDS,
		neighbor_needs_falloff_result = true,
		should_have_falloff = TileGroups.MS_NON_CLOUDS,
		should_have_falloff_result = true,
	}
)

GLOBAL.mod_protect_TileManager = true
