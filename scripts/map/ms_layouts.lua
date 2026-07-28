

local StaticLayout = require("map/static_layout")
local Layouts = require("map/layouts").Layouts

Layouts["ms_worldmigrator_spawn"] = StaticLayout.Get("map/static_layouts/ms_worldmigrator_spawn")
Layouts["ms_worldmigrator_spawn"].ground_types = {WORLD_TILES.MS_MOUNTAIN_LOW_2}
Layouts["ms_worldmigrator_spawn"].ground =
			{
				{0, 0, 0, 0, 1},
				{0, 1, 0, 1, 0},
				{0, 0, 1, 1, 1},
				{0, 0, 0, 1, 0},
				{0, 1, 0, 0, 1},
			}