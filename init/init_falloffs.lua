local TileManager = require("tilemanager")

-- Needs to be loaded after tiles

GLOBAL.mod_protect_TileManager = false

FALLOFF_IDS.MOUNTAIN_FALLOFF = GetTableSize(FALLOFF_IDS)
FALLOFF_IDS.ICE_BRIDGE_FALLOFF = FALLOFF_IDS.MOUNTAIN_FALLOFF + 1

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

TileManager.AddFalloffTexture(
	FALLOFF_IDS.ICE_BRIDGE_FALLOFF,
	{
		name = "ice_bridge_falloff",
		noise_texture = "square.tex",
		neighbor_needs_falloff = TileGroups.MS_CLOUDS,
		neighbor_needs_falloff_result = true,
		should_have_falloff = TileGroups.MS_ICE_BRIDGE,
		should_have_falloff_result = true,
	}
)
GLOBAL.mod_protect_TileManager = true
