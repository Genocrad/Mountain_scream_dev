------------------------------------------------------------------------------------------------------------------------
-- Wilson / GENERIC character examines (Chinese)

local ___________________________DESCRIBE = STRINGS.CHARACTERS.GENERIC.DESCRIBE
local ___________________________ANNOUNCE = STRINGS.CHARACTERS.GENERIC

-- Forging: ingots share temperature statuses (GENERIC / WARM / HOT / MELT)
local MS_INGOT_DESC = {
	GENERIC = "一块结实的金属锭。",
	WARM = "还锻打不了。",
	HOT = "可以锻打了。",
	MELT = "#软得像温热的黄油！",
}
___________________________DESCRIBE.MS_COPPER_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_ALU_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_BRONZE_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_GOLD_INGOT = MS_INGOT_DESC

-- Details only toggle between cool and hot
local MS_DETAIL_DESC = {
	GENERIC = "锻打成型的金属零件。完美！",
	HOT = "#刚下砧还烫着！得小心拿！",
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

___________________________DESCRIBE.MS_COPPER_ORE = "能看见氧化的痕迹。"
___________________________DESCRIBE.MS_ALU_ORE = "对金属来说太软了。"
___________________________DESCRIBE.MS_COAL = "熔炉的好燃料。"
___________________________DESCRIBE.MS_GEODE_ORE = "#这块石头里说不定有东西？"
___________________________DESCRIBE.MS_SLAG = "#唉，没成。"

___________________________DESCRIBE.MS_ANVIL = "这儿得用锤子才行。"
___________________________DESCRIBE.MS_ANVIL_HELPER = "这儿得用锤子才行。"
___________________________DESCRIBE.MS_FURNACE = "一台超大号炉子。"
___________________________DESCRIBE.MS_FURNACE_BELLOW = "把火再煽旺点！"
___________________________DESCRIBE.MS_FURNACE_CAMPFIRE = {
	OUT = "该把火生起来了。",
	EMBERS = "#热度勉强够正经冶炼",
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
	CHOPPED = "它还挺能扛的。", --Instead of "Take that, nature!" ?
}
___________________________DESCRIBE.MS_APPLE_TREE_SNOW = ___________________________DESCRIBE.MS_APPLE_TREE
___________________________DESCRIBE.MS_APPLE = "一个新鲜的山地苹果。"
___________________________DESCRIBE.MS_APPLE_COOKED = "又暖又甜。"
___________________________DESCRIBE.MS_APPLE_DRIED = "脆脆的薄片。"
___________________________DESCRIBE.MS_GOLDEN_APPLE = "挖矿又手工做出来的。"
___________________________DESCRIBE.MS_BIG_APPLE = "好大一个苹果！"
___________________________DESCRIBE.MS_APPLE_CORE = "可以种下去。"
___________________________DESCRIBE.MS_APPLE_PIE = "这才叫美式风味！"
___________________________DESCRIBE.MS_APPLE_CARAMEL = "黏糊糊的。"
___________________________DESCRIBE.MS_POISONED_APPLE = "毒汁顺着苹果往下淌。"

___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN = {
	DEFAULT = "一块奇怪的石头。",
	ON = "通往远方的传送门。",
	OFF = "无法工作。总觉得是缺少洞穴的缘故。",
}
___________________________DESCRIBE.MS_WORLDMIGRATOR_UP = ___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN

___________________________DESCRIBE.MS_CLIMBING = "看起来能爬。上去！"
___________________________DESCRIBE.MS_CLIMBING_DOWN = "下去的路。"
___________________________DESCRIBE.MS_ARENATELEPORTER = "散发着不祥的气息。"
___________________________DESCRIBE.MS_ARENATELEPORTER_EXIT = "一条方便的退路。"
___________________________DESCRIBE.MS_SHORTCUT = "需要合适的能量源。"
___________________________DESCRIBE.MS_SHORTCUT_ON = "捷径？"
___________________________DESCRIBE.MS_SHORTCUT_EXIT = "需要合适的能量源。"
___________________________DESCRIBE.MS_SHORTCUT_EXIT_ON = "捷径？"
___________________________DESCRIBE.MS_CAVE_ENTRANCE_VERTICAL = "崖壁上的洞穴入口。"
___________________________DESCRIBE.MS_CAVE_ENTRANCE = "通往山腹更深处的通道。"
___________________________DESCRIBE.MS_CAVE_EXIT = "通往日光的通道。"
___________________________DESCRIBE.MS_CAVE_ENTRANCE_LIGHT = "光！那一定是出口。"

___________________________DESCRIBE.MS_WALL_BUSH = "生长在高海拔处。"
___________________________DESCRIBE.MS_WALL_STONE = "岩石里显露出矿石。怎么挖出来呢？"
___________________________DESCRIBE.MS_BROKEN_PILLAR = "某种古老机关的残骸？"

___________________________DESCRIBE.MOUNTAIN_FROZEN_MEATBALLS = "咬都咬不动。"
___________________________DESCRIBE.MOUNTAIN_KIKI = "阴沉的猴子。"
___________________________DESCRIBE.MOUNTAIN_KIKI_HOUSE = "一个冰冷的洞穴。"
___________________________DESCRIBE.MOUNTAIN_CRATER_POOL = "山间的一汪暖浴。"
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE1 = "一块雪正飞过来。"
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE2 = "雪和冰。"
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE3 = "别沾到头发！"
___________________________DESCRIBE.MOUNTAIN_FALCON = "目光锐利的鹰。"
___________________________DESCRIBE.MOUNTAIN_FALCON_BASE = "鹰的巢丘。最好别打扰。"
___________________________DESCRIBE.MOUNTAIN_WINDHORN = "能召唤风本身的号角。"
___________________________DESCRIBE.MOUNTAIN_COCKROACH = "呃。一只石蟑螂。"
___________________________DESCRIBE.MOUNTAIN_COCKROACH_NEST = "蟑螂聚集的地方。真美妙。"
___________________________DESCRIBE.MOUNTAIN_STALACTITE = "石钟乳。撑着……不，挂着。"
___________________________DESCRIBE.MOUNTAIN_STALAGMITE = "石笋。从地上往上长。"
___________________________DESCRIBE.MOUNTAIN_GOAT = "固执的羊驼羊"
___________________________DESCRIBE.MOUNTAIN_ICEGOAT = "寒冷显然让他更暴躁了。"
___________________________DESCRIBE.MOUNTAIN_GOLEM = "真不该把他吵醒。"
___________________________DESCRIBE.MOUNTAIN_GOLEM_PILLAR = "蕴藏着巨大的能量。"
___________________________DESCRIBE.MOUNTAIN_GOLEM_PLATFORM = "给某种庞然大物准备的地基。"
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK = "那座塔挡住了路。"
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK_CHARGED = "他的力量就在塔里。"
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_TALL = "尖刺！"
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_CHARGED_TALL = "随时都会炸开！"
___________________________DESCRIBE.MOUNTAIN_BUSH = "耐寒的山蕨。"
___________________________DESCRIBE.DUG_MOUNTAIN_BUSH = "挖出的山蕨。可以再种回去。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_BUSH = "一丛稀疏的山灌木。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_TREE = "一棵小山树。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_GRASS = "坚韧的山草。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_BRANCHES = "一株小树苗。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_FLOWER = "闻起来比我见过的其他花都好。"
___________________________DESCRIBE.MOUNTAIN_PLANTS_POMEGRANATE = "野生石榴。"

___________________________DESCRIBE.MOUNTAIN_YOTH_LANCE = "够锋利。"
___________________________DESCRIBE.MOUNTAIN_WATHGRITHR_SHIELD = "结实的青铜盾。"
___________________________DESCRIBE.MOUNTAIN_ARMOR_COPPER = "一套肌肉感十足的青铜甲。"
___________________________DESCRIBE.MOUNTAIN_HELMET_COPPER = "挺亮眼的头盔。"
___________________________DESCRIBE.MOUNTAIN_COPPER_AXE = "每砍一下都会自己磨利！"
___________________________DESCRIBE.MOUNTAIN_COPPER_BAT = "越绿打得越狠。"
___________________________DESCRIBE.MOUNTAIN_GOAPACA_HORN = "能把人顶飞。"
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_AXE = "又轻又利。"
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_PICKAXE = "现在没有石头能躲过我了。"
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_DAGGER = "突刺时间！"
___________________________DESCRIBE.MOUNTAIN_COPPER_PICKAXE = "氧化得很快。"
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDAXE = "在阳光下闪闪发光。"
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDPICKAXE = "镀金得更狠。"
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDSHOVEL = "干脏活用这么精致的东西，有点过分了。"

___________________________DESCRIBE.MOUNTAIN_ICECREAM = "得赶紧吃，不然会化得满手都是！"
___________________________DESCRIBE.MOUNTAIN_TORNADO_SORBET = "这奶昔能把我吹上天！"
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK = "肉上还粘着一堆羽毛。"
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK_COOKED = "扔出去还会飞吗？"
___________________________DESCRIBE.MOUNTAIN_SNOWBALL = "一团压实的山地雪球。"
___________________________DESCRIBE.MOUNTAIN_SUSPICIOUS_ORE = "得砸开才能知道里面有什么。"
___________________________DESCRIBE.MOUNTAIN_GREEN_STONE = "石头上长着草。"
___________________________DESCRIBE.MOUNTAIN_COLD_ROCK = "结构密实的石头。"
___________________________DESCRIBE.MOUNTAIN_SNOWPEAK_STONE = "这些石头保持着平衡。"
___________________________DESCRIBE.MOUNTAIN_SNOWPILE = "雪堆。"
___________________________DESCRIBE.MOUNTAIN_GRAVEL_PILE = "一堆石头。"
___________________________DESCRIBE.MOUNTAIN_TRANSFORMATION_CUBE = "#充满转化的能量。"
___________________________DESCRIBE.MOUNTAIN_WOODEN_BOX = "希望里面有能吃的。"
___________________________DESCRIBE.HAT_TINFOIL = "保护大脑。"
___________________________DESCRIBE.MOUNTAIN_TOP = "终于！顶峰！"

___________________________DESCRIBE.TURF_MS_SNOW = "一层雪毯。"
___________________________DESCRIBE.TURF_MS_BRICK = "一块砖地皮-。" --Why do these end with an em-dash?
___________________________DESCRIBE.TURF_MS_CAVE = "一块洞穴地皮-。"
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW = "低山的地皮-。"
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW_2 = "低山的地皮-。"
___________________________DESCRIBE.TURF_MS_MOUNTAIN_HIGH = "高山的地皮-。"
___________________________DESCRIBE.TURF_MS_PERMAFROST = "冻土地皮。永久寒冷-。"

------------------------------------------------------------
-- Announcements

___________________________ANNOUNCE.MS_GOLDEN_APPLE_BUFF_START = {
	"感觉自己成了天下最美的人！",
}
___________________________ANNOUNCE.MS_GOLDEN_APPLE_BUFF_END = {
	"脑子好像还飘在九霄云外……",
}
___________________________ANNOUNCE.MS_MOUNTAIN_ICE_CREAM_START = {
	"呃，脑仁结冰了！",
}
___________________________ANNOUNCE.MS_MOUNTAIN_ICE_CREAM_END = {
	"我还起鸡皮疙瘩……",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_START = {
	"好刺激！",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_ABILITY_READY = {
	"又可以掀起一场旋风了！",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_END = {
	"折腾完感觉有点晕……",
}
