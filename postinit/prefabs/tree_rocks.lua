
local AddSimPostInit = AddSimPostInit
local UpvalueHacker = require("tools/upvaluehacker")
local TREE_ROCK_DATA = require("prefabs/tree_rock_data")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

TREE_ROCK_DATA.VINE_LOOT_DATA["ms_coal"] = {build = "ms_tree_rock_normal", symbols = {"swap_ms_coal"}}
TREE_ROCK_DATA.VINE_LOOT_DATA["ms_alu_ore"] = {build = "ms_tree_rock_normal", symbols = {"swap_ms_alu_ore"}}
TREE_ROCK_DATA.VINE_LOOT_DATA["ms_copper_ore"] = {build = "ms_tree_rock_normal", symbols = {"swap_ms_copper_ore"}}
TREE_ROCK_DATA.VINE_LOOT_DATA["mountain_snowball"] = {build = "ms_tree_rock_normal", symbols = {"swap_mountain_snowball"}}
TREE_ROCK_DATA.VINE_LOOT_DATA["mountain_wooden_box"] = {build = "ms_tree_rock_normal", symbols = {"swap_mountain_wooden_box"}}

TREE_ROCK_DATA.WEIGHTED_VINE_LOOT["MS_LOW"] = {
        ["nitre"]               = 10,
        ["mountain_wooden_box"]      = 3,
        ["rocks"]                = 12,
        ["goldnugget"]                = 3,
        ["flint"]                = 10
    }
TREE_ROCK_DATA.WEIGHTED_VINE_LOOT["MS_MID"] = {
        ["ms_alu_ore"]                = 6,
        ["ms_copper_ore"]                = 6,
        ["rocks"]                = 12,
        ["goldnugget"]                = 3,
        ["flint"]                = 10
    }
TREE_ROCK_DATA.WEIGHTED_VINE_LOOT["MS_HIGH"] = {
        ["rocks"]                = 10,
        ["ms_alu_ore"]                = 10,
        ["ms_copper_ore"]                = 10,
        ["goldnugget"]                = 10,
        ["mountain_snowball"]                = 20
    }
TREE_ROCK_DATA.WEIGHTED_VINE_LOOT["MS_CAVE"] = {
        ["ms_alu_ore"]                = 10,
        ["ms_copper_ore"]                = 10,
        ["ms_coal"]                = 10
    }
    
local WEIGHTED_VINE_LOOT = TREE_ROCK_DATA.WEIGHTED_VINE_LOOT 

local function CountWeightedTotal(choices)
    local total = 0
    for _, weight in pairs(choices) do
        total = total + weight
    end
    return total
end



AddSimPostInit(function(inst)
  if Prefabs["tree_rock"] then
    local old_GetLootWeightedTable = UpvalueHacker.GetUpvalue(Prefabs["tree_rock"].fn, "SetupVineLoot", "GetVineLoots", "GetLootWeightedTable")
    print("old_GetLootKey", old_GetLootWeightedTable)
    
    local function GetLootWeightedTable(inst)
      local x, y, z = inst.Transform:GetWorldPosition()
      if TheWorld.net.components.dungeonmapoverwatch then
        local level = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z)
        if level then
          if level == 2 or level == 3 or level == 4 then
            local weighted_table = WEIGHTED_VINE_LOOT["MS_LOW"]
            local weighted_total = CountWeightedTotal(weighted_table)
            return weighted_table
          end
          if level == 5 or level == 6 then
            local weighted_table = WEIGHTED_VINE_LOOT["MS_MID"]
            local weighted_total = CountWeightedTotal(weighted_table)
            return weighted_table
          end
          if level == 7 or level == 8 or level == 9 then
            local weighted_table = WEIGHTED_VINE_LOOT["MS_HIGH"]
            local weighted_total = CountWeightedTotal(weighted_table)
            return weighted_table
          end
            if level == 10 or level == 11 or level == 12 then
            local weighted_table = WEIGHTED_VINE_LOOT["MS_CAVE"]
            local weighted_total = CountWeightedTotal(weighted_table)
            return weighted_table
          end
          print("No levels?")
        end
      end
      print("No dungeonmapoverwatch?")
      return old_GetLootWeightedTable(inst)
    end
    
    UpvalueHacker.SetUpvalue(Prefabs["tree_rock"].fn, GetLootWeightedTable, "SetupVineLoot", "GetVineLoots", "GetLootWeightedTable")
    
  end


end)