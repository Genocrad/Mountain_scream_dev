------------------------------------------------------------------------------------------------------------------------
-- Wilson / GENERIC character examines (Chinese)

local ___________________________DESCRIBE = STRINGS.CHARACTERS.GENERIC.DESCRIBE

-- Forging: ingots share temperature statuses (GENERIC / WARM / HOT / MELT)
local MS_INGOT_DESC = {
	GENERIC = "一块结实的金属锭。准备好搞科学……或者锻造。",
	WARM = "还能继续锻打。",
	HOT = "软得恰到好处！不愧是我的手艺。",
	MELT = "软得像黄油！",
}
___________________________DESCRIBE.MS_COPPER_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_ALU_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_BRONZE_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_GOLD_INGOT = MS_INGOT_DESC

-- Details only toggle between cool and hot
local MS_DETAIL_DESC = {
	GENERIC = "锻打成型的金属零件。正好用来制作。",
	HOT = "刚下砧还烫着。小心拿！",
}
___________________________DESCRIBE.MS_COPPER_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_ALU_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_BRONZE_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_GOLD_DETAIL = MS_DETAIL_DESC

-- Formless stays hot until forged or cooled into slag
___________________________DESCRIBE.MS_COPPER_INGOT_FORMLESS = "一团滚烫的无定形铜。铁砧在等着它。"
___________________________DESCRIBE.MS_ALU_INGOT_FORMLESS = "一团滚烫的无定形铝。铁砧在等着它。"
___________________________DESCRIBE.MS_BRONZE_INGOT_FORMLESS = "一团滚烫的无定形青铜。铁砧在等着它。"
___________________________DESCRIBE.MS_GOLD_INGOT_FORMLESS = "一团滚烫的无定形金。铁砧在等着它。"

___________________________DESCRIBE.MS_COPPER_ORE = "铜矿。得好好熔一熔。"
___________________________DESCRIBE.MS_ALU_ORE = "铝矿。比看上去轻。"
___________________________DESCRIBE.MS_COAL = "密实的黑煤。熔炉的好燃料。"
___________________________DESCRIBE.MS_GEODE_ORE = "一颗晶洞。里面说不定有好东西。"
___________________________DESCRIBE.MS_SLAG = "锻造失败品。科学并不总是好看的。"

___________________________DESCRIBE.MS_ANVIL = "科学家的本能要求精准的工具。"
___________________________DESCRIBE.MS_ANVIL_HELPER = "科学家的本能要求精准的工具。"
___________________________DESCRIBE.MS_FURNACE = "别把头伸进去。"
___________________________DESCRIBE.MS_FURNACE_BELLOW = "我的风扇设计肯定更棒。"
___________________________DESCRIBE.MS_FURNACE_CAMPFIRE = {
	OUT = "该把火生起来了。",
	EMBERS = "热度勉强能融化东西。",
	LOW = "一小堆火。",
	NORMAL = "烧得正好。",
	HIGH = "这才像样的冶炼之火！",
}

___________________________DESCRIBE.MS_ALU_ROCK = "一块富含铝的岩石。"
___________________________DESCRIBE.MS_COAL_ROCK = "一块含煤的岩石。"
___________________________DESCRIBE.MS_COPPER_ROCK = "一块富含铜的岩石。"
___________________________DESCRIBE.MS_GEODE_ROCK = "一块藏着晶洞的岩石。"
___________________________DESCRIBE.MS_GIANT_BOULDER_GRASS = "一块大得出奇的巨石。挖起来可得费些功夫。"
___________________________DESCRIBE.MS_GIANT_BOULDER_ROCK = "一块大得出奇的巨石。挖起来可得费些功夫。"
___________________________DESCRIBE.MS_GIANT_BOULDER_SNOW = "一块大得出奇的巨石。挖起来可得费些功夫。"

___________________________DESCRIBE.MS_APPLE_TREE = {
	GENERIC = "一棵普通的苹果树。",
	BURNT = "烧焦了。",
	CHOPPED = "只剩树桩了。",
}
___________________________DESCRIBE.MS_APPLE_TREE_SNOW = ___________________________DESCRIBE.MS_APPLE_TREE
___________________________DESCRIBE.MS_APPLE = "一个新鲜的山地苹果。"
___________________________DESCRIBE.MS_APPLE_COOKED = "又暖又甜。"
___________________________DESCRIBE.MS_APPLE_DRIED = "有点韧，但能放很久。"
___________________________DESCRIBE.MS_GOLDEN_APPLE = "金光闪闪，大概有点奢侈。"
___________________________DESCRIBE.MS_BIG_APPLE = "好大一个苹果！"
___________________________DESCRIBE.MS_APPLE_CORE = "可以种下去。"
___________________________DESCRIBE.MS_APPLE_PIE = "像样的山地甜点。"
___________________________DESCRIBE.MS_APPLE_CARAMEL = "又黏又甜，沾手就危险。"
___________________________DESCRIBE.MS_POISONED_APPLE = "最好别吃。"

___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN = {
	DEFAULT = "一块奇怪的石头。",
	ON = "一个通往遥远而安全之地的传送门。",
	OFF = "无法工作。可能是缺少洞穴的缘故。",
}
___________________________DESCRIBE.MS_WORLDMIGRATOR_UP = ___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN

___________________________DESCRIBE.MS_CLIMBING = "看起来能爬。上去！"
___________________________DESCRIBE.MS_CLIMBING_DOWN = "下去的路。最好别头朝下。"
___________________________DESCRIBE.MS_ARENATELEPORTER = "诡异的图腾。另一边好像在打架。"
___________________________DESCRIBE.MS_ARENATELEPORTER_EXIT = "诡异的图腾。希望是出去的路。"
___________________________DESCRIBE.MS_SHORTCUT = "掏空的图腾。也许能连到某处。"
___________________________DESCRIBE.MS_SHORTCUT_ON = "它醒了。目的地未知，冒险确定。"
___________________________DESCRIBE.MS_SHORTCUT_EXIT = "掏空的图腾。捷径的另一头。"
___________________________DESCRIBE.MS_SHORTCUT_EXIT_ON = "它醒了。但愿落地够软。"
___________________________DESCRIBE.MS_CAVE_ENTRANCE_VERTICAL = "崖壁上的洞穴入口。"
___________________________DESCRIBE.MS_CAVE_ENTRANCE = "通往山腹更深处的通道。"
___________________________DESCRIBE.MS_CAVE_EXIT = "通往日光的通道。"
___________________________DESCRIBE.MS_CAVE_ENTRANCE_LIGHT = "光！那一定是出口。"

___________________________DESCRIBE.MS_WALL_BUSH = "扒在悬崖上的倔强灌木。"
___________________________DESCRIBE.MS_WALL_STONE = "岩石里露出的矿脉。"
___________________________DESCRIBE.MS_BROKEN_PILLAR = "这根柱子风光不再了。"

___________________________DESCRIBE.MOUNTAIN_FROZEN_MEATBALLS = "冻得结实的肉丸。大自然的冰箱。"
___________________________DESCRIBE.MOUNTAIN_KIKI = "一只野山猿。看起来不太安分。"
___________________________DESCRIBE.MOUNTAIN_KIKI_HOUSE = "温馨的……巢？"
___________________________DESCRIBE.MOUNTAIN_CRATER_POOL = "冒着蒸汽的温泉。又暖又诱人。"
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE1 = "带着冰刺脾气的雪球。"
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE2 = "碰到就会冻住的雪球。"
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE3 = "会扰乱心智的雪球。"
___________________________DESCRIBE.MOUNTAIN_FALCON = "目光锐利的猎隼。"
___________________________DESCRIBE.MOUNTAIN_FALCON_BASE = "猎隼的巢丘。最好别打扰。"
___________________________DESCRIBE.MOUNTAIN_WINDHORN = "能召唤风本身的号角。"
___________________________DESCRIBE.MOUNTAIN_COCKROACH = "呃。一只山地蟑螂。"
___________________________DESCRIBE.MOUNTAIN_COCKROACH_NEST = "蟑螂聚集的地方。真美妙。"
___________________________DESCRIBE.MOUNTAIN_STALACTITE = "石钟乳。撑着……不，挂着。"
___________________________DESCRIBE.MOUNTAIN_STALAGMITE = "石笋。从地上往上长。"
___________________________DESCRIBE.MOUNTAIN_GOAT = "一只山羊。脚稳又固执。"
___________________________DESCRIBE.MOUNTAIN_ICEGOAT = "山羊，但更冷。"
___________________________DESCRIBE.MOUNTAIN_GOLEM = "一座活山！差不多吧。"
___________________________DESCRIBE.MOUNTAIN_GOLEM_PILLAR = "一根石柱。感觉还没完工。"
___________________________DESCRIBE.MOUNTAIN_GOLEM_PLATFORM = "给某种庞然大物准备的地基。"
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK = "一块压实的沙。"
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK_CHARGED = "沙，噼啪作响地充着能。"
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_TALL = "一根沙刺。真尖！"
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_CHARGED_TALL = "充能沙刺。更尖！"
___________________________DESCRIBE.MOUNTAIN_BUSH = "耐寒的山蕨。"
___________________________DESCRIBE.DUG_MOUNTAIN_BUSH = "挖出的山蕨。可以再种回去。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_BUSH = "一丛稀疏的山灌木。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_TREE = "一棵小树。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_GRASS = "坚韧的山草。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_BRANCHES = "一株小树苗。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_FLOWER = "一朵山花。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_POMEGRANATE = "石榴植株。挺讲究！"

___________________________DESCRIBE.MOUNTAIN_YOTH_LANCE = "青铜矛。尖锐的科学。"
___________________________DESCRIBE.MOUNTAIN_WATHGRITHR_SHIELD = "结实的青铜盾。"
___________________________DESCRIBE.MOUNTAIN_ARMOR_COPPER = "肌肉感十足的青铜甲。"
___________________________DESCRIBE.MOUNTAIN_HELMET_COPPER = "青铜盔。保护脑子！"
___________________________DESCRIBE.MOUNTAIN_COPPER_AXE = "铜斧。砍得有型。"
___________________________DESCRIBE.MOUNTAIN_COPPER_BAT = "铝棒。轻便的惩罚。"
___________________________DESCRIBE.MOUNTAIN_GOAPACA_HORN = "山羊角。也许有用。"
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_AXE = "铝斧。又轻又利。"
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_PICKAXE = "铝镐。挖矿更省力。"
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_DAGGER = "铝剑。真飒！"
___________________________DESCRIBE.MOUNTAIN_COPPER_PICKAXE = "铜镐。够用就行。"
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDAXE = "镀金到极致的斧。"
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDPICKAXE = "镀金到极致的镐。"
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDSHOVEL = "镀金到极致的铲。"

___________________________DESCRIBE.MOUNTAIN_ICECREAM = "雪山冰激凌！脑仁要结冰了。"
___________________________DESCRIBE.MOUNTAIN_TORNADO_SORBET = "带着旋风劲的奶昔。"
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK = "来自某种……怪物的腿。"
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK_COOKED = "炸怪物肉。意外地诱人。"
___________________________DESCRIBE.MOUNTAIN_SNOWBALL = "一团压实的山地雪球。"
___________________________DESCRIBE.MOUNTAIN_SUSPICIOUS_ORE = "可疑的矿石。藏着什么？"
___________________________DESCRIBE.MOUNTAIN_GREEN_STONE = "一块绿山石。"
___________________________DESCRIBE.MOUNTAIN_COLD_ROCK = "一块冷得出奇的石头。"
___________________________DESCRIBE.MOUNTAIN_SNOWPEAK_STONE = "来自雪峰的石头。"
___________________________DESCRIBE.MOUNTAIN_SNOWPILE = "一堆山岭积雪。"
___________________________DESCRIBE.MOUNTAIN_GRAVEL_PILE = "一堆碎石。有得挖。"
___________________________DESCRIBE.MOUNTAIN_TRANSFORMATION_CUBE = "能转化材料的魔方。纯粹的科学！"
___________________________DESCRIBE.MOUNTAIN_WOODEN_BOX = "一个木盒。里面是什么？"
___________________________DESCRIBE.HAT_TINFOIL = "锡纸帽。用来挡住……某些东西。"
___________________________DESCRIBE.MOUNTAIN_TOP = "一座适合插旗的山顶。"

___________________________DESCRIBE.TURF_MS_SNOW = "一块雪地皮。"
___________________________DESCRIBE.TURF_MS_BRICK = "一块砖地皮。"
___________________________DESCRIBE.TURF_MS_CAVE = "一块洞穴地皮。"
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW = "低山的地皮。"
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW_2 = "低山的地皮。"
___________________________DESCRIBE.TURF_MS_MOUNTAIN_HIGH = "高山的地皮。"
___________________________DESCRIBE.TURF_MS_PERMAFROST = "冻土地皮。永久寒冷。"
