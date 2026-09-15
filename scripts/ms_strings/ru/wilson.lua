------------------------------------------------------------------------------------------------------------------------
-- Wilson / GENERIC character examines (Russian)

local ___________________________DESCRIBE = STRINGS.CHARACTERS.GENERIC.DESCRIBE

-- Forging: ingots share temperature statuses (GENERIC / WARM / HOT / MELT)
local MS_INGOT_DESC = {
	GENERIC = "Прочный металлический слиток. Готов к науке... или ковке.",
	WARM = "Ещё можно ковать.",
	HOT = "Так хорошо гнётся! Не иначе, результат моей превосходной техники.",
	MELT = "Мягкий, как масло!",
}
___________________________DESCRIBE.MS_COPPER_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_ALU_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_BRONZE_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_GOLD_INGOT = MS_INGOT_DESC

-- Details only toggle between cool and hot
local MS_DETAIL_DESC = {
	GENERIC = "Выкованная металлическая деталь. Идеально для крафта.",
	HOT = "Ещё горячая с наковальни. Осторожнее!",
}
___________________________DESCRIBE.MS_COPPER_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_ALU_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_BRONZE_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_GOLD_DETAIL = MS_DETAIL_DESC

-- Formless stays hot until forged or cooled into slag
___________________________DESCRIBE.MS_COPPER_INGOT_FORMLESS = "Бесформенный ком горячей меди. Наковальня ждёт."
___________________________DESCRIBE.MS_ALU_INGOT_FORMLESS = "Бесформенный ком горячего алюминия. Наковальня ждёт."
___________________________DESCRIBE.MS_BRONZE_INGOT_FORMLESS = "Бесформенный ком горячей бронзы. Наковальня ждёт."
___________________________DESCRIBE.MS_GOLD_INGOT_FORMLESS = "Бесформенный ком горячего золота. Наковальня ждёт."

___________________________DESCRIBE.MS_COPPER_ORE = "Медная руда. Нужно хорошенько расплавить."
___________________________DESCRIBE.MS_ALU_ORE = "Алюминиевая руда. Легче, чем кажется."
___________________________DESCRIBE.MS_COAL = "Плотный чёрный уголь. Отличное топливо для печи."
___________________________DESCRIBE.MS_GEODE_ORE = "Жеода. Внутри может быть что-то интересное."
___________________________DESCRIBE.MS_SLAG = "Неудачная ковка. Наука не всегда красива."

___________________________DESCRIBE.MS_ANVIL = "Моя учёная натура требует точных инструментов."
___________________________DESCRIBE.MS_ANVIL_HELPER = "Моя учёная натура требует точных инструментов."
___________________________DESCRIBE.MS_FURNACE = "Не суйте туда голову."
___________________________DESCRIBE.MS_FURNACE_BELLOW = "Мой вентилятор всё равно был бы лучше."
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
___________________________DESCRIBE.MS_APPLE_DRIED = "Жевательное, зато хранится долго."
___________________________DESCRIBE.MS_GOLDEN_APPLE = "Блестит. Наверное, это уже слишком."
___________________________DESCRIBE.MS_BIG_APPLE = "Вот это яблоко!"
___________________________DESCRIBE.MS_APPLE_CORE = "Можно посадить."
___________________________DESCRIBE.MS_APPLE_PIE = "Настоящий горный десерт."
___________________________DESCRIBE.MS_APPLE_CARAMEL = "Липкое, сладкое и опасное на ощупь."
___________________________DESCRIBE.MS_POISONED_APPLE = "Это лучше не есть."

___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN = {
	DEFAULT = "Странный камень.",
	ON = "Телепорт в далёкое и абсолютно безопасное место.",
	OFF = "Не работает. Подозреваю, дело в отсутствии пещер.",
}
___________________________DESCRIBE.MS_WORLDMIGRATOR_UP = ___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN

___________________________DESCRIBE.MS_CLIMBING = "Похоже, можно взобраться. Вверх!"
___________________________DESCRIBE.MS_CLIMBING_DOWN = "Путь вниз. Желательно не головой вперёд."
___________________________DESCRIBE.MS_ARENATELEPORTER = "Жуткий тотем. По ту сторону кто-то сражается."
___________________________DESCRIBE.MS_ARENATELEPORTER_EXIT = "Жуткий тотем. Надеюсь, это выход."
___________________________DESCRIBE.MS_SHORTCUT = "Пустой тотем. Может связать куда-нибудь."
___________________________DESCRIBE.MS_SHORTCUT_ON = "Он ожил. Куда — неизвестно, приключения — гарантированы."
___________________________DESCRIBE.MS_SHORTCUT_EXIT = "Пустой тотем. Другой конец короткого пути."
___________________________DESCRIBE.MS_SHORTCUT_EXIT_ON = "Он ожил. Надеюсь, приземление будет мягким."
___________________________DESCRIBE.MS_CAVE_ENTRANCE_VERTICAL = "Пещерный проём в отвесной скале."
___________________________DESCRIBE.MS_CAVE_ENTRANCE = "Проход глубже в гору."
___________________________DESCRIBE.MS_CAVE_EXIT = "Проход обратно к свету."
___________________________DESCRIBE.MS_CAVE_ENTRANCE_LIGHT = "Свет! Должно быть, выход."

___________________________DESCRIBE.MS_WALL_BUSH = "Упрямый кустарник, цепляющийся за утёс."
___________________________DESCRIBE.MS_WALL_STONE = "Руда выглядывает из скалы."
___________________________DESCRIBE.MS_BROKEN_PILLAR = "У этой колонны были лучшие дни."

___________________________DESCRIBE.MOUNTAIN_FROZEN_MEATBALLS = "Тефтели, намертво замёрзшие. Холодильник природы."
___________________________DESCRIBE.MOUNTAIN_KIKI = "Дикая горная обезьяна. Выглядит озорной."
___________________________DESCRIBE.MOUNTAIN_KIKI_HOUSE = "Милый дом... гнездо?"
___________________________DESCRIBE.MOUNTAIN_CRATER_POOL = "Дымящийся кратерный источник. Тёплый и манящий."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE1 = "Ледяной снежок с колючим характером."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE2 = "Снежок, который замораживает при касании."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE3 = "Снежок, что мутит рассудок."
___________________________DESCRIBE.MOUNTAIN_FALCON = "Зоркий сокол."
___________________________DESCRIBE.MOUNTAIN_FALCON_BASE = "Соколиное гнездо. Лучше не тревожить."
___________________________DESCRIBE.MOUNTAIN_WINDHORN = "Рог, призывающий сам ветер."
___________________________DESCRIBE.MOUNTAIN_COCKROACH = "Фу. Горный таракан."
___________________________DESCRIBE.MOUNTAIN_COCKROACH_NEST = "Место сбора тараканов. Восхитительно."
___________________________DESCRIBE.MOUNTAIN_STALACTITE = "Сталактит. Держится... ну, висит."
___________________________DESCRIBE.MOUNTAIN_STALAGMITE = "Сталагмит. Растёт снизу вверх."
___________________________DESCRIBE.MOUNTAIN_GOAT = "Горный козёл. Уверенный и упрямый."
___________________________DESCRIBE.MOUNTAIN_ICEGOAT = "Козёл, но холоднее."
___________________________DESCRIBE.MOUNTAIN_GOLEM = "Живая гора! Или почти."
___________________________DESCRIBE.MOUNTAIN_GOLEM_PILLAR = "Каменный столп. Кажется незавершённым."
___________________________DESCRIBE.MOUNTAIN_GOLEM_PLATFORM = "Основание для чего-то громадного."
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK = "Блок уплотнённого песка."
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK_CHARGED = "Песок, потрескивающий энергией."
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_TALL = "Песчаный шип. Острый!"
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_CHARGED_TALL = "Заряженный песчаный шип. Ещё острее!"
___________________________DESCRIBE.MOUNTAIN_BUSH = "Стойкий горный папоротник."
___________________________DESCRIBE.DUG_MOUNTAIN_BUSH = "Выкопанный горный папоротник. Можно посадить снова."
___________________________DESCRIBE.MOUNTAIN_PLANTS_BUSH = "Корявый горный куст."
___________________________DESCRIBE.MOUNTAIN_PLANTS_TREE = "Маленькое горное деревце."
___________________________DESCRIBE.MOUNTAIN_PLANTS_GRASS = "Жёсткая горная трава."
___________________________DESCRIBE.MOUNTAIN_PLANTS_BRANCHES = "Маленький саженец."
___________________________DESCRIBE.MOUNTAIN_PLANTS_FLOWER = "Горный цветок."
___________________________DESCRIBE.MOUNTAIN_PLANTS_POMEGRANATE = "Гранатовое растение. Изысканно!"

___________________________DESCRIBE.MOUNTAIN_YOTH_LANCE = "Бронзовое копьё. Острая наука."
___________________________DESCRIBE.MOUNTAIN_WATHGRITHR_SHIELD = "Прочный бронзовый щит."
___________________________DESCRIBE.MOUNTAIN_ARMOR_COPPER = "Бронзовый доспех с серьёзной мускулатурой."
___________________________DESCRIBE.MOUNTAIN_HELMET_COPPER = "Бронзовый шлем. Защищает мозги!"
___________________________DESCRIBE.MOUNTAIN_COPPER_AXE = "Медный топор. Рубит со стилем."
___________________________DESCRIBE.MOUNTAIN_COPPER_BAT = "Алюминиевая дубина. Лёгкое наказание."
___________________________DESCRIBE.MOUNTAIN_GOAPACA_HORN = "Козий рог. Может пригодиться."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_AXE = "Алюминиевый топор. Лёгкий и острый."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_PICKAXE = "Алюминиевая кирка. Копать легче."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_DAGGER = "Алюминиевый меч. Изящно!"
___________________________DESCRIBE.MOUNTAIN_COPPER_PICKAXE = "Медная кирка. Со своим делом справляется."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDAXE = "Золочёный топор на максимуме."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDPICKAXE = "Золочёная кирка на максимуме."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDSHOVEL = "Золочёная лопата на максимуме."

___________________________DESCRIBE.MOUNTAIN_ICECREAM = "Горное мороженое! Готовьтесь к мозговой заморозке."
___________________________DESCRIBE.MOUNTAIN_TORNADO_SORBET = "Милкшейк с вихрем в придачу."
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK = "Ножка от чего-то... чудовищного."
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK_COOKED = "Жареное монстрячье мясо. На удивление аппетитно."
___________________________DESCRIBE.MOUNTAIN_SNOWBALL = "Плотный горный снежок."
___________________________DESCRIBE.MOUNTAIN_SUSPICIOUS_ORE = "Подозрительная руда. Что она скрывает?"
___________________________DESCRIBE.MOUNTAIN_GREEN_STONE = "Зелёный горный камень."
___________________________DESCRIBE.MOUNTAIN_COLD_ROCK = "Камень, который неестественно холоден."
___________________________DESCRIBE.MOUNTAIN_SNOWPEAK_STONE = "Камень со снежных пиков."
___________________________DESCRIBE.MOUNTAIN_SNOWPILE = "Куча горного снега."
___________________________DESCRIBE.MOUNTAIN_GRAVEL_PILE = "Куча щебня. Есть что копать."
___________________________DESCRIBE.MOUNTAIN_TRANSFORMATION_CUBE = "Куб, преобразующий материалы. Чистая наука!"
___________________________DESCRIBE.MOUNTAIN_WOODEN_BOX = "Деревянный ящик. Что внутри?"
___________________________DESCRIBE.HAT_TINFOIL = "Шапочка из фольги. Чтобы держать... кое-что... снаружи."
___________________________DESCRIBE.MOUNTAIN_TOP = "Горная вершина, идеальная для флага."

___________________________DESCRIBE.TURF_MS_SNOW = "Кусок снежной земли."
___________________________DESCRIBE.TURF_MS_BRICK = "Кирпичная плитка."
___________________________DESCRIBE.TURF_MS_CAVE = "Пещерная плитка."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW = "Дёрн с предгорий."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW_2 = "Дёрн с предгорий."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_HIGH = "Дёрн с высокогорья."
___________________________DESCRIBE.TURF_MS_PERMAFROST = "Дёрн вечной мерзлоты. Навсегда прохладный."
