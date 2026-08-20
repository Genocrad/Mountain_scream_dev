GLOBAL.MS_ITEMS_ATLAS = MODROOT.."images/inventoryimages/mountain_items.xml"

Assets = {
	--------------------------------------------------------
	-- Color cubes / environment
	Asset("IMAGE", "images/mountainday_cc.tex"),
	Asset("IMAGE", "images/mountaindusk_cc.tex"),
	Asset("IMAGE", "images/mountainnight_cc.tex"),
	Asset("IMAGE", "images/mountainlow_day_cc.tex"),
	Asset("IMAGE", "images/mountainlow_night_cc.tex"),
	Asset("IMAGE", "images/wave_clouds.tex"),
	Asset("IMAGE", "images/wave_null.tex"),

	--------------------------------------------------------
	-- Inventory atlases (A)
	Asset("IMAGE", "images/inventoryimages/inventoryimages_ingots.tex"),
	Asset("ATLAS", "images/inventoryimages/inventoryimages_ingots.xml"),
	Asset("IMAGE", "images/inventoryimages/inventoryimages_ms_turf.tex"),
	Asset("ATLAS", "images/inventoryimages/inventoryimages_ms_turf.xml"),

	--------------------------------------------------------
	-- Inventory atlases (XK)
	Asset("IMAGE", "images/inventoryimages/mountain_items.tex"),
	Asset("ATLAS", "images/inventoryimages/mountain_items.xml"),
	Asset("IMAGE", "images/inventoryimages/ms_crafticons.tex"),
	Asset("ATLAS", "images/inventoryimages/ms_crafticons.xml"),
	Asset("ATLAS_BUILD", "images/inventoryimages/mountain_items.xml", 256),

	--------------------------------------------------------
	-- Minimap
	Asset("ATLAS", "images/minimap_ms_cave_room.xml"),
	Asset("IMAGE", "images/minimap_ms_cave_room.tex"),
	Asset("IMAGE", "images/mountain_minimap.tex"),
	Asset("ATLAS", "images/mountain_minimap.xml"),
  Asset("ATLAS", "images/ms_giant_plug.xml"),
  Asset("IMAGE", "images/ms_giant_plug.tex"),  

	--------------------------------------------------------
	-- Sound
	Asset("SOUNDPACKAGE", "sound/music_mod.fev"),
	Asset("SOUND", "sound/music_mod.fsb"),
	Asset("SOUNDPACKAGE", "sound/sound_mod_tutorial.fev"),
	Asset("SOUND", "sound/sound_mod_tutorial.fsb"),

	--------------------------------------------------------
	-- Anim / shaders
	Asset("ANIM", "anim/clouds_overlay.zip"),
 	Asset("ANIM", "anim/minimap_cloud_overlay.zip"),
	Asset("ANIM", "anim/ms_hello_turf.zip"), -- Luigi: Why loading normally does not work? Huh?
	Asset("ANIM", "anim/player_wx78_actions.zip"), -- tornado sorbet transform
	Asset("SHADER", "shaders/cave_vertical_shader.ksh"),
	Asset("SHADER", "shaders/mountain_vertical_shader.ksh"),
	Asset("SHADER", "shaders/clickable_vertical_shader.ksh"),
	Asset("SHADER", "shaders/rotation_vertical_shader.ksh"),
}

--------------------------------------------------------
-- Ingot inventory icons (temperature / facing variants)
local INGOTS = {
  "ms_copper_ingot",
  "ms_copper_detail",
  "ms_alu_ingot",
  "ms_alu_detail",
  "ms_gold_ingot",
  "ms_gold_detail",
  "ms_bronze_ingot",
  "ms_bronze_detail",
}

local INGOT_SUFFIXES = {
	"",
	"_warm",
	"_hot",
	"_melt",
	"_forward",
	"_forward_warm",
	"_forward_hot",
	"_forward_melt",
	"_left",
	"_left_warm",
	"_left_hot",
	"_left_melt",
	"_right",
	"_right_warm",
	"_right_hot",
	"_right_melt",
    "_formless",
}


local INGOTS_ATLAS = "images/inventoryimages/inventoryimages_ingots.xml"
for _, ingot in ipairs(INGOTS) do
	for _, suffix in ipairs(INGOT_SUFFIXES) do
		RegisterInventoryItemAtlas(INGOTS_ATLAS, ingot..suffix..".tex")
	end
end
RegisterInventoryItemAtlas(INGOTS_ATLAS, "ms_copper_ore.tex")
RegisterInventoryItemAtlas(INGOTS_ATLAS, "ms_alu_ore.tex")
RegisterInventoryItemAtlas(INGOTS_ATLAS, "ms_slag.tex")
RegisterInventoryItemAtlas(INGOTS_ATLAS, "ms_coal.tex")
--------------------------------------------------------
-- Turf inventory icons
local TURF_ATLAS = "images/inventoryimages/inventoryimages_ms_turf.xml"
local TURFS = {
	"turf_ms_mountain_low",
	"turf_ms_cave",
	"turf_ms_permafrost",
	"turf_ms_snow",
	"turf_ms_mountain_low_2",
	"turf_ms_mountain_high",
	"turf_ms_brick",
}
for _, turf in ipairs(TURFS) do
	RegisterInventoryItemAtlas(TURF_ATLAS, turf..".tex")
end

--------------------------------------------------------
-- XK item inventory icons
local MOUNTAIN_ITEMS_ATLAS = "images/inventoryimages/mountain_items.xml"
local MOUNTAIN_ITEMS = {
	"mountain_windhorn",
	"mountain_super_gildedaxe",
	"mountain_super_gildedpickaxe",
	"mountain_super_gildedshovel",
	"mountain_yoth_lance",
	"mountain_wathgrithr_shield",
	"mountain_armor_copper",
	"mountain_helmet_copper",
	"hat_tinfoil",
	"mountain_copper_axe",
	"mountain_copper_pickaxe",
	"mountain_copper_bat_1",
	"mountain_copper_bat_2",
	"mountain_copper_bat_3",
	"mountain_aluminum_axe",
	"mountain_aluminum_pickaxe",
	"mountain_aluminum_dagger",
	"mountain_icecream",
	"mountain_tornado_sorbet",
	"mountain_monster_drumstick",
	"mountain_monster_drumstick_cooked",
	"mountain_snowball",
	"mountain_transformation_cube",
	"mountain_frozen_meatballs",
	"mountain_wooden_box",
	"mountain_goapaca_horn",
	"ms_anvil",
  	"ms_furnace",
}
for _, v in ipairs(MOUNTAIN_ITEMS) do
	RegisterInventoryItemAtlas(MOUNTAIN_ITEMS_ATLAS, v..".tex")
end

--------------------------------------------------------
-- Minimap atlases
AddMinimapAtlas("images/minimap_ms_cave_room.xml")
AddMinimapAtlas("images/ms_giant_plug.xml")
AddMinimapAtlas("images/mountain_minimap.xml")
