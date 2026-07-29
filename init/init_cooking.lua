------------------------------------------------------------------------------------------------------------------------
-- A: furnace smelting

-- TO DO: Maybe own type?
AddIngredientValues({"ms_copper_ore"}, { inedible = 1 })

AddCookerRecipe("ms_furnace", {
	name = "ms_copper_ingot",
	weight = 1,
	priority = 2,
	cooktime = 10,
	test = function(cooker, names, tags)
		return names.ms_copper_ore
	end,
	no_cookbook = true,
})

------------------------------------------------------------------------------------------------------------------------
-- XK: cookpot foods

-- 雪山冰激凌：可入锅，1 乳制品 + 1 冰
AddIngredientValues({"mountain_icecream"}, { dairy = 1, frozen = 1 })
-- 怪物鸟腿：可入锅，0.5 肉度 + 1 怪物度（烤后同值）
AddIngredientValues({"mountain_monster_drumstick"}, { meat = .5, monster = 1 }, true)

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
