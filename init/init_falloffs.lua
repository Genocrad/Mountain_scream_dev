local TileManager = require("tilemanager")

-- Needs to be loaded after tiles

GLOBAL.mod_protect_TileManager = false

FALLOFF_IDS.MOUNTAIN_FALLOFF = GetTableSize(FALLOFF_IDS)
FALLOFF_IDS.ICE_BRIDGE_FALLOFF = FALLOFF_IDS.MOUNTAIN_FALLOFF + 1
FALLOFF_IDS.MS_FALLOFF_1 = FALLOFF_IDS.ICE_BRIDGE_FALLOFF + 1
FALLOFF_IDS.MS_FALLOFF_2 = FALLOFF_IDS.MS_FALLOFF_1 + 1
FALLOFF_IDS.MS_FALLOFF_3 = FALLOFF_IDS.MS_FALLOFF_2 + 1

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

TileManager.AddFalloffTexture(
	FALLOFF_IDS.MS_FALLOFF_1,
	{
		name = "ms_falloff_1",
		noise_texture = "square.tex",
		neighbor_needs_falloff = TileGroups.MS_CLOUDS,
		neighbor_needs_falloff_result = true,
		should_have_falloff = TileGroups.MS_FALLOFF_1,
		should_have_falloff_result = true,
	}
)

TileManager.AddFalloffTexture(
	FALLOFF_IDS.MS_FALLOFF_2,
	{
		name = "ms_falloff_2",
		noise_texture = "square.tex",
		neighbor_needs_falloff = TileGroups.MS_CLOUDS,
		neighbor_needs_falloff_result = true,
		should_have_falloff = TileGroups.MS_FALLOFF_2,
		should_have_falloff_result = true,
	}
)

TileManager.AddFalloffTexture(
	FALLOFF_IDS.MS_FALLOFF_3,
	{
		name = "ms_falloff_3",
		noise_texture = "square.tex",
		neighbor_needs_falloff = TileGroups.MS_CLOUDS,
		neighbor_needs_falloff_result = true,
		should_have_falloff = TileGroups.MS_FALLOFF_3,
		should_have_falloff_result = true,
	}
)

GLOBAL.mod_protect_TileManager = true
