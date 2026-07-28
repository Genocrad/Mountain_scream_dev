local AddCookerRecipe = AddCookerRecipe
local AddIngredientValues = AddIngredientValues
GLOBAL.setfenv(1, GLOBAL)

-- TO DO: Maybe own type? 
AddIngredientValues({"ms_copper_ore"}, {inedible = 1})

AddCookerRecipe("ms_furnace", {
    name = "ms_copper_ingot",
    weight = 1,
    priority = 2,
    cooktime = 10,
    test = function(cooker, names, tags)
       return names.ms_copper_ore
    end,
    no_cookbook = true
})


