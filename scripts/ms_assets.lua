local resolvefilepath = GLOBAL.resolvefilepath
Assets = {
  Asset("IMAGE", "images/mountainday_cc.tex" ),
  Asset("IMAGE", "images/mountaindusk_cc.tex" ),
  Asset("IMAGE", "images/mountainnight_cc.tex" ),
  Asset("IMAGE", "images/mountainlow_day_cc.tex" ),
  Asset("IMAGE", "images/mountainlow_night_cc.tex" ),
  Asset("IMAGE", "images/inventoryimages/inventoryimages_ingots.tex" ),
  Asset("ATLAS", "images/inventoryimages/inventoryimages_ingots.xml" ),
  Asset("ATLAS", "images/inventoryimages/inventoryimages_ms_turf.xml" ),
  Asset("IMAGE", "images/inventoryimages/inventoryimages_ms_turf.tex" ),
  Asset("IMAGE", "images/wave_clouds.tex" ),
  Asset("IMAGE", "images/wave_null.tex" ),

  Asset("SOUNDPACKAGE", "sound/music_mod.fev"),
  Asset("SOUND", "sound/music_mod.fsb"),
  Asset("SOUNDPACKAGE", "sound/sound_mod_tutorial.fev"),
  Asset("SOUND", "sound/sound_mod_tutorial.fsb"),
  Asset("ANIM", "anim/player_roll_dodge.zip"),
  Asset("ANIM", "anim/clouds_overlay.zip"),
  Asset("SHADER", "shaders/shadername.ksh"),
  Asset("SHADER", "shaders/cave_vertical_shader.ksh"),
  Asset("SHADER", "shaders/mountain_vertical_shader.ksh"),
  Asset("SHADER", "shaders/clickable_vertical_shader.ksh"),
  
  Asset("ATLAS", "images/minimap_ms_cave_room.xml"),
  Asset("IMAGE", "images/minimap_ms_cave_room.tex"), 
  Asset("ATLAS", "images/minimap_various_teleporters.xml"),
  Asset("IMAGE", "images/minimap_various_teleporters.tex"),
  
  
   Asset("ANIM", "anim/ms_hello_turf.zip"), -- Luigi: Why loading normally does not work? Huh?
  }    

local ingots_list = {
  "ms_copper_ingot"
  }

for _, ingots in ipairs(ingots_list) do
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. ".tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_warm" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_hot" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_melt" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_forward" .. ".tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_forward_warm" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_forward_hot" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_forward_melt" .. ".tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_left" .. ".tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_left_warm" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_left_hot" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_left_melt" .. ".tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_right" .. ".tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_right_warm" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_right_hot" .. ".tex") 
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), ingots .. "_right_melt" .. ".tex")
end

  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ingots.xml"), "ms_copper_ore.tex")
  
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ms_turf.xml"), "turf_ms_mountain_low.tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ms_turf.xml"), "turf_ms_cave.tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ms_turf.xml"), "turf_ms_permafrost.tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ms_turf.xml"), "turf_ms_snow.tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ms_turf.xml"), "turf_ms_mountain_low_2.tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ms_turf.xml"), "turf_ms_mountain_high.tex")
  RegisterInventoryItemAtlas(resolvefilepath("images/inventoryimages/inventoryimages_ms_turf.xml"), "turf_ms_brick.tex")  
  
--MINIMAP ICONS

AddMinimapAtlas("images/minimap_ms_cave_room.xml")
AddMinimapAtlas("images/minimap_various_teleporters.xml")

