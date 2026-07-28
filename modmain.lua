
require("ms_tuning")

PrefabFiles = {
  "terraformers_mountain_dungeon",
  "ms_ice_goat",
  "gas_mountain_sediment",
  "gas_mountain_wall",
  "ms_mountain_wall",
  "ms_cave_wall",
  "cave_floor_7x5",
  "tar_pit",
  "tar_projectile",
  "ms_anvil",
  "ms_ingot",
  "ms_furnace",
  "ms_furnace_campfire",
  "ms_furnace_campfirefire",
  "ms_furnace_bellow",
  "ms_ore",
  "ms_fx",
  "ms_climbing",
  "ms_climbing_down",
  "light_fake_overworld",
  "ms_worldmigrator",
  "ms_turfs",
  "ms_snow_turf",
  "ms_cave_entrance",
  "ms_arenateleporter",
}

GLOBAL.MS_FOCALPOINT_FLOORS = {}

modimport("postinit/standartcomponents")

modimport("postinit/prefabs/player_common")
modimport("postinit/prefabs/caves")

modimport("postinit/stategraphs/wilson")
modimport("postinit/stategraphs/wilson_client")

modimport("postinit/components/camera")
modimport("postinit/components/drownable")
modimport("postinit/components/stewer")
modimport("postinit/components/temperature")
modimport("postinit/components/playervision")
modimport("postinit/components/teleporter")

modimport("postinit/widgets/mapwidget")

modimport("scripts/ms_falloffs")
modimport("scripts/ms_actions")
modimport("scripts/ms_containers")
modimport("scripts/ms_cooking")
modimport("scripts/ms_assets")
modimport("scripts/ms_forging")

modimport("strings/common")
modimport("strings/generic")
