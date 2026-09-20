--GLOBAL.SEED = 1618090222--1616755459
-- Capture mod-env APIs before setfenv; after GLOBAL.setfenv, bare AddRoom/AddTask
-- resolve to vanilla globals and assert on re-enable ("already exists").
local AddRoom = AddRoom
local AddTask = AddTask
local AddTaskPreInit = AddTaskPreInit
local AddTaskSetPreInit = AddTaskSetPreInit
local AddRoomPreInit = AddRoomPreInit
local UpvalueHacker = require("tools/upvaluehacker")
local forest_map = require("map/forest_map")

require("tiledefs")
require("ms_tiles")
require("map/ms_layouts")

GLOBAL.setfenv(1, GLOBAL)
  
-- Size setting

local _Generate = forest_map.Generate

forest_map.Generate = function(prefab, map_width, map_height, tasks, level, level_type, ...)
  
  if prefab == "cave" then
    level.overrides.world_size = "tiny" 
  end
  
  print("TINY")

  return _Generate(prefab, map_width, map_height, tasks, level, level_type, ...)
end

if WorldSim then
  local _WorldSim = getmetatable(WorldSim).__index
  for k, v in pairs(getmetatable(WorldSim).__index) do print(k, v) end
  idk_what_i_do = _WorldSim.ConvertToTileMap
  _WorldSim.ConvertToTileMap = function(self, number, ...)
    if number == 1 then
      WorldSim:SetWorldSize(700, 700)
      local _ConvertToTileMap = idk_what_i_do(self, 700, ...)
      return _ConvertToTileMap
    end
    local _ConvertToTileMap = idk_what_i_do(self, number, ...)
    return _ConvertToTileMap
  end
end


local SIZE_VARIATION = 2

local length = #LOCKS_ARRAY

LOCKS["MOUNTAIN_LEVEL_1"] = length + 1
LOCKS["MOUNTAIN_LEVEL_1_E"] = length + 2
LOCKS["MOUNTAIN_LEVEL_2"] = length + 3
LOCKS["MOUNTAIN_LEVEL_2_E"] = length + 4
LOCKS["MOUNTAIN_LEVEL_3"] = length + 5
LOCKS["MOUNTAIN_LEVEL_3_E"] = length + 6
LOCKS["MOUNTAIN_LEVEL_4"] = length + 7
LOCKS["MOUNTAIN_LEVEL_4_E"] = length + 8

local length = #KEYS_ARRAY

KEYS["MOUNTAIN_LEVEL_1"] = length + 1
KEYS["MOUNTAIN_LEVEL_1_E"] = length + 2
KEYS["MOUNTAIN_LEVEL_2"] = length + 3
KEYS["MOUNTAIN_LEVEL_2_E"] = length + 4
KEYS["MOUNTAIN_LEVEL_3"] = length + 5
KEYS["MOUNTAIN_LEVEL_3_E"] = length + 6
KEYS["MOUNTAIN_LEVEL_4"] = length + 7
KEYS["MOUNTAIN_LEVEL_4_E"] = length + 8

LOCKS_KEYS[LOCKS.MOUNTAIN_LEVEL_1] = 	
  {
		KEYS.MOUNTAIN_LEVEL_1
	}
LOCKS_KEYS[LOCKS.MOUNTAIN_LEVEL_1_E] = 	
  {
		KEYS.MOUNTAIN_LEVEL_1_E
	}
  LOCKS_KEYS[LOCKS.MOUNTAIN_LEVEL_2] = 	
  {
		KEYS.MOUNTAIN_LEVEL_2
	}
  LOCKS_KEYS[LOCKS.MOUNTAIN_LEVEL_2_E] = 	
  {
		KEYS.MOUNTAIN_LEVEL_2_E
	}
  LOCKS_KEYS[LOCKS.MOUNTAIN_LEVEL_3] = 	
  {
		KEYS.MOUNTAIN_LEVEL_3
	}
    LOCKS_KEYS[LOCKS.MOUNTAIN_LEVEL_3_E] = 	
  {
		KEYS.MOUNTAIN_LEVEL_3_E
	}
print("KEYS", LOCKS.MOUNTAIN_LEVEL_1)

AddRoom("Mountain_Dungeon_Basic",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    
    value = WORLD_TILES.MS_HIGHLAND,
	contents = {
		distributepercent = 0.12,
		distributeprefabs =
		{
    },
    countprefabs =
		{
			terraformer_mountain_dungeon_level_1 = 1,
		},
	},
})

AddRoom("BG_Mountain_Dungeon",  {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    
    value = WORLD_TILES.MS_HIGHLAND,
	contents = {
		distributepercent = 0.12,
		distributeprefabs =
		{
    },
  
	},
})

AddTask("MountainEntranceTask", {
        locks={LOCKS.MOUNTAIN_LEVEL_1},
        keys_given={KEYS.MOUNTAIN_LEVEL_1_E},
        room_choices={
            
            ["PitRoom"] = 1,
        },
        colour={r=1,g=0,b=1,a=1},
        entrance_room="BridgeEntrance",
         background_room="PitRoom",
        room_bg= WORLD_TILES.IMPASSABLE,
    })
  
AddTask("MountainDungeonLevel_1", {
    locks={LOCKS.MOUNTAIN_LEVEL_1},
    keys_given= {}, --{KEYS.MOUNTAIN_LEVEL_1_E} ,
    	
	
	room_tags = {"RoadPoison", "nohunt", "nohasslers", },
    room_choices =
    {
      
        ["Mountain_Dungeon_Basic"] = 12,
        
    },
    make_loop = true,
    cove_room_chance = 0,
    cove_room_max_edges = 0,
    room_bg = WORLD_TILES.MS_HIGHLAND,
    background_room = "BG_Mountain_Dungeon",
    entrance_room="BridgeEntrance",
    colour={r=0.6,g=0.6,b=0.0,a=1},
})


AddRoom("Rocky_ms_influence", {
					colour={r=.55,g=.75,b=.75,a=.50},
					value = WORLD_TILES.DIRT,
					tags = {"ExitPiece", "Chester_Eyebone", "Astral_1"},
					contents =  {
            countstaticlayouts = {["ms_worldmigrator_spawn"] = 1},
									countprefabs=
									{
										meteorspawner = function() return math.random(1,2) end,
										rock_moon = function() return math.random(1,2) - 1 end,
										burntground_faded = function() return math.random(3,5) end,
										tallbirdnest = 1,
									},
					                distributepercent = .1,
					                distributeprefabs=
					                {
					                    rock1 = 2,
					                    rock2 = 2,
										rock_ice = 1,
					                    tallbirdnest=.1,
					                    spiderden=.01,
					                    blue_mushroom = .002,
					                    grassgekko = 0.3,
					                },
					            }
					})


AddTaskPreInit("Dig that rock", function(task)
  task.room_choices["Rocky_ms_influence"] = 1
end)

AddTaskPreInit("CentipedeCaveTask", function(task)
  task.keys_given = {KEYS.MOUNTAIN_LEVEL_1}
end)

AddTaskSetPreInit("cave_default", function(tasksetname) 
  table.insert(tasksetname.tasks, "MountainDungeonLevel_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")
  table.insert(tasksetname.required_prefabs, "terraformer_mountain_dungeon_level_1")



end)

AddTaskSetPreInit("default", function(tasksetname) 
  table.insert(tasksetname.required_prefabs, "ms_worldmigrator_down")
end)