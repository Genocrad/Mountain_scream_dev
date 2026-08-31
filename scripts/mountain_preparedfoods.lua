-- 关于食谱，anim中默认的Bank、Build、Symbol都要跟物品名称相同
-- 尤其是symbol，名称不同会导致食物无法在锅中显示

local function AppleCount(names)
	return (names.ms_apple or 0) + (names.ms_big_apple or 0)
end

local foods =
{
	-- 龙卷风星酪：1 乳制品 + 1 雪山冰激凌 + 1 冰 + 1 蜂蜜
	-- mountain_icecream 自带 dairy=1，故另需乳制品时要求 dairy >= 2
	mountain_tornado_sorbet = {
		test = function(cooker, names, tags)
			return (names.mountain_icecream or 0) >= 1
				and (names.ice or 0) >= 1
				and (names.honey or 0) >= 1
				and tags.dairy ~= nil and tags.dairy >= 2
		end,
		priority = 20, -- 高于原版冰激凌(10)，避免被抢先匹配
		overridebuild = "mountain_foods",
		foodtype = FOODTYPE.GOODIES,
		health = TUNING.MOUNTAIN_TORNADO_SORBET.HEALTH,
		hunger = TUNING.MOUNTAIN_TORNADO_SORBET.HUNGER,
		sanity = TUNING.MOUNTAIN_TORNADO_SORBET.SANITY,
		perishtime = TUNING.MOUNTAIN_TORNADO_SORBET.PERISH_TIME,
		temperature = TUNING.MOUNTAIN_TORNADO_SORBET.TEMP_DELTA,
		temperatureduration = TUNING.MOUNTAIN_TORNADO_SORBET.TEMP_DURATION,
		cooktime = 2,
		floater = {"small", 0.15, 0.8},
		tags = {"icebox_valid"},
		card_def = {ingredients = {{"goatmilk", 1}, {"mountain_icecream", 1}, {"ice", 1}, {"honey", 1}} },
		cookbook_tex = "mountain_tornado_sorbet.tex",
		cookbook_atlas = "images/inventoryimages/mountain_items.xml",
		prefabs = { "buff_mountain_tornado_sorbet" },
		oneatenfn = function(inst, eater)
			if eater ~= nil and eater.components.debuffable ~= nil and eater:HasTag("player") then
				eater:AddDebuff("buff_mountain_tornado_sorbet", "buff_mountain_tornado_sorbet")
			end
		end,
	},

	-- 苹果派：3 苹果 + 1 任意
	ms_apple_pie = {
		test = function(cooker, names, tags)
			return AppleCount(names) >= 3
		end,
		priority = 20,
		overridebuild = "mountain_foods",
		foodtype = FOODTYPE.VEGGIE,
		health = TUNING.MS_APPLE_PIE.HEALTH,
		hunger = TUNING.MS_APPLE_PIE.HUNGER,
		sanity = TUNING.MS_APPLE_PIE.SANITY,
		perishtime = TUNING.MS_APPLE_PIE.PERISH_TIME,
		cooktime = 1,
		floater = {"med", 0.1, 0.7},
		card_def = {ingredients = {{"ms_apple", 3}, {"twigs", 1}} },
		cookbook_tex = "ms_apple_pie.tex",
		cookbook_atlas = "images/inventoryimages/mountain_items.xml",
	},

	-- 焦糖苹果：1 苹果 + 1 树枝 + 1 蜂蜜度 + 1 任意
	ms_apple_caramel = {
		test = function(cooker, names, tags)
			return AppleCount(names) >= 1
				and (names.twigs or 0) >= 1
				and tags.sweetener ~= nil and tags.sweetener >= 1
		end,
		priority = 30,
		overridebuild = "mountain_foods",
		foodtype = FOODTYPE.GOODIES,
		health = TUNING.MS_APPLE_CARAMEL.HEALTH,
		hunger = TUNING.MS_APPLE_CARAMEL.HUNGER,
		sanity = TUNING.MS_APPLE_CARAMEL.SANITY,
		perishtime = TUNING.MS_APPLE_CARAMEL.PERISH_TIME,
		cooktime = 1,
		floater = {"small", 0.1, 0.8},
		tags = {"honeyed"},
		inv_image = "ms_caramel_apple",
		card_def = {ingredients = {{"ms_apple", 1}, {"twigs", 1}, {"honey", 1}, {"berries", 1}} },
		cookbook_tex = "ms_caramel_apple.tex",
		cookbook_atlas = "images/inventoryimages/mountain_items.xml",
	},

	-- 毒苹果：1 苹果 + 2 怪物度 + 1 任意
	ms_poisoned_apple = {
		test = function(cooker, names, tags)
			return AppleCount(names) >= 1
				and tags.monster ~= nil and tags.monster >= 2
		end,
		priority = 25,
		overridebuild = "mountain_foods",
		foodtype = FOODTYPE.VEGGIE,
		health = TUNING.MS_POISONED_APPLE.HEALTH,
		hunger = TUNING.MS_POISONED_APPLE.HUNGER,
		sanity = TUNING.MS_POISONED_APPLE.SANITY,
		perishtime = TUNING.MS_POISONED_APPLE.PERISH_TIME,
		cooktime = 1,
		floater = {"small", 0.1, 0.8},
		card_def = {ingredients = {{"ms_apple", 1}, {"monstermeat", 2}, {"twigs", 1}} },
		cookbook_tex = "ms_poisoned_apple.tex",
		cookbook_atlas = "images/inventoryimages/mountain_items.xml",
	},
}

for k, v in pairs(foods) do
    v.name = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0

	v.cookbook_category = "cookpot"
end

return foods
