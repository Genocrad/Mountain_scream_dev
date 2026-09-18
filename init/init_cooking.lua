------------------------------------------------------------------------------------------------------------------------
-- A: furnace smelting

-- Monster
AddIngredientValues({"ms_copper_ore"}, { inedible = 1})
AddIngredientValues({"ms_alu_ore"}, { inedible = 1})
AddIngredientValues({"goldnugget"}, { inedible = 1})

AddCookerRecipe("ms_furnace", {
	name = "ms_copper_ingot_formless",
	weight = 1,
	priority = 2,
	cooktime = TUNING.MS_SMELT_TIME["ms_copper_ingot_formless"],
	test = function(cooker, names, tags)
		return names.ms_copper_ore and names.ms_copper_ore > 3
	end,
	no_cookbook = true,
})

AddCookerRecipe("ms_furnace", {
	name = "ms_alu_ingot_formless",
	weight = 1,
	priority = 2,
	cooktime = TUNING.MS_SMELT_TIME["ms_alu_ingot_formless"],
	test = function(cooker, names, tags)
		return names.ms_alu_ore and names.ms_alu_ore > 3
	end,
	no_cookbook = true,
})

AddCookerRecipe("ms_furnace", {
	name = "ms_gold_ingot_formless",
	weight = 1,
	priority = 2,
	cooktime = TUNING.MS_SMELT_TIME["ms_gold_ingot_formless"],
	test = function(cooker, names, tags)
		return names.goldnugget and names.goldnugget > 3
	end,
	no_cookbook = true,
})

AddCookerRecipe("ms_furnace", {
	name = "ms_bronze_ingot_formless",
	weight = 1,
	priority = 2,
	cooktime = TUNING.MS_SMELT_TIME["ms_bronze_ingot_formless"],
	test = function(cooker, names, tags)
		return names.ms_copper_ore and names.ms_copper_ore > 1 and names.ms_alu_ore and names.ms_alu_ore > 1
	end,
	no_cookbook = true,
})

-- Luigi: We need "fail" recipe, otherwise we will get a crash after sticking twigs into the furnace.
AddCookerRecipe("ms_furnace", {
	name = "ms_slag",
	weight = 1,
	priority = -20,
	cooktime = .25,
	no_cookbook = true,
  test = function(cooker, names, tags) return true end,
})

------------------------------------------------------------------------------------------------------------------------
-- XK: cookpot foods

-- 雪山冰激凌：可入锅，1 乳制品 + 1 冰
AddIngredientValues({"mountain_icecream"}, { dairy = 1, frozen = 1 })
-- 怪物鸟腿：可入锅，0.5 肉度 + 1 怪物度（烤后同值）
AddIngredientValues({"mountain_monster_drumstick"}, { meat = .5, monster = 1 }, true)
-- 苹果：1 水果度（烤后同值）；苹果干：1 水果度；大苹果：2 水果度
AddIngredientValues({"ms_apple"}, { fruit = 1 }, true)
AddIngredientValues({"ms_apple_dried"}, { fruit = 1 })
AddIngredientValues({"ms_big_apple"}, { fruit = 2 })

local foods = require("mountain_preparedfoods")
local recipe_cards = require("cooking").recipe_cards
for k, recipe in pairs(foods) do
	AddCookerRecipe("cookpot", recipe)
	AddCookerRecipe("portablecookpot", recipe)
	AddCookerRecipe("archive_cookpot", recipe)

	if recipe.card_def then
		table.insert(recipe_cards, { recipe_name = recipe.name, cooker_name = "cookpot" })
	end
end

-- 沃利调味：生成 *_spice_* 配方并注册到便携香料站。
-- 预制体由 scripts/prefabs/mountain_preparedfoods.lua 在 PrefabFiles 加载时创建。
GenerateSpicedFoods(foods)
for _, recipe in pairs(require("spicedfoods")) do
	if recipe.basename ~= nil and foods[recipe.basename] ~= nil then
		AddCookerRecipe("portablespicer", recipe)
	end
end
