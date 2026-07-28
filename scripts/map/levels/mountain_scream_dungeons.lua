
LEVELTYPE.MOUNTAIN_SCREAM_DUNGEON = "MOUNTAIN_SCREAM_DUNGEON"
-- older depreciated AddLevel up here --
print(LEVELTYPE.MOUNTAIN_SCREAM_DUNGEON)
AddWorldGenLevel(LEVELTYPE.MOUNTAIN_SCREAM_DUNGEON, {
    id = "MOUNTAIN_SCREAM_DUNGEONS",
    name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS.LAVAARENA,
    desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC.LAVAARENA,
    location = "mountain_scream_dungeons", -- this is actually the prefab name
    version = 4,
    overrides={
    },
    background_node_range = {0,1},
})
AddSettingsPreset(LEVELTYPE.MOUNTAIN_SCREAM_DUNGEON, {
    id = "MOUNTAIN_SCREAM_DUNGEONS",
    name = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELS.LAVAARENA,
    desc = STRINGS.UI.CUSTOMIZATIONSCREEN.PRESETLEVELDESC.LAVAARENA,
    location = "mountain_scream_dungeons", -- this is actually the prefab name
    version = 1,
    overrides={},
})