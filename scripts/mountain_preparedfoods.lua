-- 关于食谱，anim中默认的Bank、Build、Symbol都要跟物品名称相同
-- 尤其是symbol，名称不同会导致食物无法在锅中显示

local foods =
{
	-- 龙卷风星酪：2 雪山冰激凌 + 2 蜂蜜
	mountain_tornado_sorbet = {
		test = function(cooker, names, tags)
			return (names.mountain_icecream or 0) >= 2 and (names.honey or 0) >= 2
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
		card_def = {ingredients = {{"mountain_icecream", 2}, {"honey", 2}} },
		cookbook_tex = "mountain_tornado_sorbet.tex",
		cookbook_atlas = "images/inventoryimages/mountain_items.xml",
		prefabs = { "buff_mountain_tornado_sorbet" },
		oneatenfn = function(inst, eater)
			if eater ~= nil and eater.components.debuffable ~= nil and eater:HasTag("player") then
				eater:AddDebuff("buff_mountain_tornado_sorbet", "buff_mountain_tornado_sorbet")
			end
		end,
	},
}

for k, v in pairs(foods) do
    v.name = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0

	v.cookbook_category = "cookpot"
end

return foods
