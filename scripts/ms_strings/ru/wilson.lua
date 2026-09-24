------------------------------------------------------------------------------------------------------------------------
-- Wilson / GENERIC character examines (Russian)

local ___________________________DESCRIBE = STRINGS.CHARACTERS.GENERIC.DESCRIBE
local ___________________________ANNOUNCE = STRINGS.CHARACTERS.GENERIC

-- Forging: ingots share temperature statuses (GENERIC / WARM / HOT / MELT)
local MS_INGOT_DESC = {
	GENERIC = "Прочный металлический слиток.",
	WARM = "Недостаточно разогрет для ковки.",
	HOT = "Уже можно ковать.",
	MELT = "Мягкий, как масло!",
}
___________________________DESCRIBE.MS_COPPER_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_ALU_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_BRONZE_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_GOLD_INGOT = MS_INGOT_DESC

-- Details only toggle between cool and hot
local MS_DETAIL_DESC = {
	GENERIC = "Выкованная металлическая деталь. Идеально!",
	HOT = "Ещё горячая, с наковальни. Осторожно!",
}
___________________________DESCRIBE.MS_COPPER_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_ALU_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_BRONZE_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_GOLD_DETAIL = MS_DETAIL_DESC

-- Formless stays hot until forged or cooled into slag
___________________________DESCRIBE.MS_COPPER_INGOT_FORMLESS = "Бесформенный ком горячей меди. Наковальня ждёт"
___________________________DESCRIBE.MS_ALU_INGOT_FORMLESS = "Бесформенный ком горячего алюминия. Наковальня ждёт."
___________________________DESCRIBE.MS_BRONZE_INGOT_FORMLESS = "Бесформенный ком горячей бронзы. Наковальня ждёт."
___________________________DESCRIBE.MS_GOLD_INGOT_FORMLESS = "Бесформенный ком горячего золота. Наковальня ждёт."

___________________________DESCRIBE.MS_COPPER_ORE = "Видны следы окисления."
___________________________DESCRIBE.MS_ALU_ORE = "Слишком мягкий для металла."
___________________________DESCRIBE.MS_COAL = "Отличное топливо для печи."
___________________________DESCRIBE.MS_GEODE_ORE = "Внутри может быть что-то интересное."
___________________________DESCRIBE.MS_SLAG = "Неудачная ковка."

___________________________DESCRIBE.MS_ANVIL = "Тут явно нужен молот для работы."
___________________________DESCRIBE.MS_ANVIL_HELPER = "Тут явно нужен молот для работы."
___________________________DESCRIBE.MS_FURNACE = "Огромная печь."
___________________________DESCRIBE.MS_FURNACE_BELLOW = "Добавим жару."
___________________________DESCRIBE.MS_FURNACE_CAMPFIRE = {
	OUT = "Пора разжечь этот огонь.",
	EMBERS = "Едва ли достаточно жарко, чтобы что-то плавить.",
	LOW = "Скромный огонёк.",
	NORMAL = "Горит отлично.",
	HIGH = "Вот это настоящий плавильный огонь!",
}

___________________________DESCRIBE.MS_ALU_ROCK = "Валун, богатый алюминием."
___________________________DESCRIBE.MS_COAL_ROCK = "Валун с углём."
___________________________DESCRIBE.MS_COPPER_ROCK = "Валун, богатый медью."
___________________________DESCRIBE.MS_GEODE_ROCK = "Валун, в котором спрятаны жеоды."
local MS_GIANT_BOULDER_DESC = {
	GENERIC = "Валун необычных размеров. Добыча займёт время.",
	EMPTY = "Здесь пусто.",
}
___________________________DESCRIBE.MS_GIANT_BOULDER_GRASS = MS_GIANT_BOULDER_DESC
___________________________DESCRIBE.MS_GIANT_BOULDER_ROCK = MS_GIANT_BOULDER_DESC
___________________________DESCRIBE.MS_GIANT_BOULDER_SNOW = MS_GIANT_BOULDER_DESC

___________________________DESCRIBE.MS_APPLE_TREE = {
	GENERIC = "Скромная яблоня.",
	BURNT = "Сгорела дотла.",
	CHOPPED = "Держалась достойно.",
}
___________________________DESCRIBE.MS_APPLE_TREE_SNOW = ___________________________DESCRIBE.MS_APPLE_TREE
___________________________DESCRIBE.MS_APPLE = "Свежее горное яблоко."
___________________________DESCRIBE.MS_APPLE_COOKED = "Тёплое и сладкое."
___________________________DESCRIBE.MS_APPLE_DRIED = "Хрустящие ломтики."
___________________________DESCRIBE.MS_GOLDEN_APPLE = "Весит тонну."
___________________________DESCRIBE.MS_BIG_APPLE = "Вот это яблоко!"
___________________________DESCRIBE.MS_APPLE_CORE = "Можно посадить."
___________________________DESCRIBE.MS_APPLE_PIE = "Прекрасный запах выпечки."
___________________________DESCRIBE.MS_APPLE_CARAMEL = "Липкое."
___________________________DESCRIBE.MS_POISONED_APPLE = "Яд стекает по яблоку."

___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN = {
	DEFAULT = "Странный камень.",
	ON = "Телепорт в далёкое место.",
	OFF = "Не работает. Подозреваю, дело в отсутствии пещер.",
}
___________________________DESCRIBE.MS_WORLDMIGRATOR_UP = ___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN

___________________________DESCRIBE.MS_CLIMBING = "Похоже, можно взобраться вверх."
___________________________DESCRIBE.MS_CLIMBING_DOWN = "Путь вниз."
___________________________DESCRIBE.MS_ARENATELEPORTER = "От него исходит зловещая аура."
___________________________DESCRIBE.MS_ARENATELEPORTER_EXIT = "Время уходить отсюда."
___________________________DESCRIBE.MS_SHORTCUT = {
	OFF = "Нужен подходящий источник энергии.",
	ON = "Короткий путь?",
}
___________________________DESCRIBE.MS_SHORTCUT_EXIT = ___________________________DESCRIBE.MS_SHORTCUT
___________________________DESCRIBE.MS_CAVE_ENTRANCE_VERTICAL = "Пещерный проём в отвесной скале."
___________________________DESCRIBE.MS_CAVE_ENTRANCE = "Проход глубже в гору."
___________________________DESCRIBE.MS_CAVE_EXIT = "Проход обратно к свету."
___________________________DESCRIBE.MS_CAVE_EXIT_LIGHT = "Свет! Должно быть, выход."

___________________________DESCRIBE.MS_WALL_BUSH = "Растет на большой высоте."
___________________________DESCRIBE.MS_WALL_STONE = "Руда показалась из скалы, как её достать?."
___________________________DESCRIBE.MS_BROKEN_PILLAR = "Остатки древнего механизма?"

___________________________DESCRIBE.MOUNTAIN_FROZEN_MEATBALLS = "Не разгрызть."
___________________________DESCRIBE.MOUNTAIN_KIKI = "Суровая макака."
___________________________DESCRIBE.MOUNTAIN_KIKI_HOUSE = "Холодная пещера."
___________________________DESCRIBE.MOUNTAIN_CRATER_POOL = "Теплая ванна среди гор."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE1 = "Кусок снега летит."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE2 = "Снег с льдом."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE3 = "Фу! Только не в меня!"
___________________________DESCRIBE.MOUNTAIN_FALCON = "Зоркий ястреб."
___________________________DESCRIBE.MOUNTAIN_FALCON_BASE = "Ястребиное гнездо. Лучше не тревожить."
___________________________DESCRIBE.MOUNTAIN_WINDHORN = "Призывает вихри."
___________________________DESCRIBE.MOUNTAIN_COCKROACH = "Фу. Каменный таракан."
___________________________DESCRIBE.MOUNTAIN_COCKROACH_NEST = "Место сбора тараканов. Восхитительно."
___________________________DESCRIBE.MOUNTAIN_STALACTITE = "Держится... ну, висит."
___________________________DESCRIBE.MOUNTAIN_STALAGMITE = "Растёт снизу вверх."
___________________________DESCRIBE.MOUNTAIN_GOAT = "Упрямая."
___________________________DESCRIBE.MOUNTAIN_ICEGOAT = "Её  явно злит холод."
___________________________DESCRIBE.MOUNTAIN_GOLEM = "Не стояло его будить."
___________________________DESCRIBE.MOUNTAIN_GOLEM_PILLAR = "Таит в себе большой заряд энергии."
___________________________DESCRIBE.MOUNTAIN_GOLEM_PLATFORM = "Основание для чего-то громадного."
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK = "Башня мешает проходу."
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK_CHARGED = "В башне находится его сила."
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_TALL = "Острый!"
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_CHARGED_TALL = "Готов к взрыву в любой момент!"
___________________________DESCRIBE.MOUNTAIN_BUSH = "Стойкий горный папоротник."
___________________________DESCRIBE.DUG_MOUNTAIN_BUSH = "Можно посадить снова."
___________________________DESCRIBE.MOUNTAIN_PLANTS_BUSH = "Куст без ягод?."
___________________________DESCRIBE.MOUNTAIN_PLANTS_TREE = "Маленькое горное деревце."
___________________________DESCRIBE.MOUNTAIN_PLANTS_GRASS = "Жёсткая горная трава."
___________________________DESCRIBE.MOUNTAIN_PLANTS_BRANCHES = "Ветки из земли."
___________________________DESCRIBE.MOUNTAIN_PLANTS_FLOWER = "Чудесный аромат."
___________________________DESCRIBE.MOUNTAIN_PLANTS_POMEGRANATE = "Дикий гранат."

___________________________DESCRIBE.MOUNTAIN_YOTH_LANCE = "Острая штука."
___________________________DESCRIBE.MOUNTAIN_WATHGRITHR_SHIELD = "Прочный бронзовый щит."
___________________________DESCRIBE.MOUNTAIN_ARMOR_COPPER = "Доспех с серьёзной мускулатурой."
___________________________DESCRIBE.MOUNTAIN_HELMET_COPPER = "Блестящий шлем."
___________________________DESCRIBE.MOUNTAIN_COPPER_AXE = "С каждым ударом становится острее."
___________________________DESCRIBE.MOUNTAIN_COPPER_BAT = "Чем зеленее, тем сильнее бьёт."
___________________________DESCRIBE.MOUNTAIN_GOAPACA_HORN = "Этим можно кому-то по голове треснуть."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_AXE = "Лёгкий и острый."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_PICKAXE = "Ни один камень от меня не спрячется."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_DAGGER = "Время для дартса"
___________________________DESCRIBE.MOUNTAIN_COPPER_PICKAXE = "Быстро окисляется."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDAXE = "Сияет на солнце."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDPICKAXE = "Намного прочнее."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDSHOVEL = "Думаю это слишком изысканно, для такой грязной работы."

___________________________DESCRIBE.MOUNTAIN_ICECREAM = "Нужно быстрее есть, пока не растаяло."
___________________________DESCRIBE.MOUNTAIN_TORNADO_SORBET = "Закрученные вихрем сливки."
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK = "Куча перьев на мясе."
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK_COOKED = "Лучше не стало."
___________________________DESCRIBE.MOUNTAIN_SNOWBALL = "Плотный горный снежок."
___________________________DESCRIBE.MOUNTAIN_SUSPICIOUS_ORE = "Нужно разбить, чтобы узнать что внутри"
___________________________DESCRIBE.MOUNTAIN_GREEN_STONE = "Куча травы на камне."
___________________________DESCRIBE.MOUNTAIN_COLD_ROCK = "Плотная каменная структура."
___________________________DESCRIBE.MOUNTAIN_SNOWPEAK_STONE = "Камни держат баланс."
___________________________DESCRIBE.MOUNTAIN_SNOWPILE = "Сугроб."
___________________________DESCRIBE.MOUNTAIN_GRAVEL_PILE = "Куча камней."
___________________________DESCRIBE.MOUNTAIN_TRANSFORMATION_CUBE = "Полон энергии для преобразования"
___________________________DESCRIBE.MOUNTAIN_WOODEN_BOX = "Надеюсь, там что-то сьедобное."
___________________________DESCRIBE.HAT_TINFOIL = "Защищает мозги."
___________________________DESCRIBE.MOUNTAIN_TOP = "Наконец! вершина!."

___________________________DESCRIBE.TURF_MS_SNOW = "Снежный ковёр."
___________________________DESCRIBE.TURF_MS_BRICK = "Кирпичная плитка."
___________________________DESCRIBE.TURF_MS_CAVE = "Пещерная плитка."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW = "Дёрн с предгорий."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW_2 = "Дёрн с предгорий."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_HIGH = "Дёрн с высокогорий."
___________________________DESCRIBE.TURF_MS_PERMAFROST = "Дёрн вечной мерзлоты. Навсегда прохладный."

------------------------------------------------------------
-- Announcements

___________________________ANNOUNCE.MS_GOLDEN_APPLE_BUFF_START = {
	"Чувствую себя прекраснее всех на свете!!",
}
___________________________ANNOUNCE.MS_GOLDEN_APPLE_BUFF_END = {
	"Голова всё ещё словно в Нижнем мире...",
}
___________________________ANNOUNCE.MS_MOUNTAIN_ICE_CREAM_START = {
	"Ох, аж мозги замерзли!",
}
___________________________ANNOUNCE.MS_MOUNTAIN_ICE_CREAM_END = {
	"До сих пор мурашки по коже...",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_START = {
	"Какой прилив энергии!",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_ABILITY_READY = {
	"Готов снова устроить вихрь!",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_END = {
	"Немного кружится голова после всего этого...",
}
___________________________ANNOUNCE.MS_MOUNTAIN_GOLEM_DEFEND_ABSORB = {
	"Эти заряженные башни поглощают за него урон!",
	"Эти заряженные башни его лечат!",
	"Так дело не пойдёт — нужно уничтожить эти башни!",
}
