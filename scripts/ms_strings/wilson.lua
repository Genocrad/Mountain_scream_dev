------------------------------------------------------------------------------------------------------------------------
-- Wilson / GENERIC character examines (English default)

local ___________________________DESCRIBE = STRINGS.CHARACTERS.GENERIC.DESCRIBE

-- Forging: ingots share temperature statuses (GENERIC / WARM / HOT / MELT)
local MS_INGOT_DESC = {
	GENERIC = "A solid metal ingot. Ready for science... or forging.",
	WARM = "I still can forge it.",
	HOT = "It bends so well! Surely, result of my superior technic.",
	MELT = "It's soft as butter!",
}
___________________________DESCRIBE.MS_COPPER_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_ALU_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_BRONZE_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_GOLD_INGOT = MS_INGOT_DESC

-- Details only toggle between cool and hot
local MS_DETAIL_DESC = {
	GENERIC = "A forged metal part. Perfect for crafting.",
	HOT = "Still hot from the anvil. Handle carefully!",
}
___________________________DESCRIBE.MS_COPPER_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_ALU_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_BRONZE_DETAIL = MS_DETAIL_DESC
___________________________DESCRIBE.MS_GOLD_DETAIL = MS_DETAIL_DESC

-- Formless stays hot until forged or cooled into slag
___________________________DESCRIBE.MS_COPPER_INGOT_FORMLESS = "A shapeless lump of hot copper. The anvil awaits."
___________________________DESCRIBE.MS_ALU_INGOT_FORMLESS = "A shapeless lump of hot aluminium. The anvil awaits."
___________________________DESCRIBE.MS_BRONZE_INGOT_FORMLESS = "A shapeless lump of hot bronze. The anvil awaits."
___________________________DESCRIBE.MS_GOLD_INGOT_FORMLESS = "A shapeless lump of hot gold. The anvil awaits."

___________________________DESCRIBE.MS_COPPER_ORE = "Copper ore. Needs a good melting."
___________________________DESCRIBE.MS_ALU_ORE = "Aluminium ore. Lighter than it looks."
___________________________DESCRIBE.MS_COAL = "Dense black coal. Excellent furnace fuel."
___________________________DESCRIBE.MS_GEODE_ORE = "A geode. Something interesting might be inside."
___________________________DESCRIBE.MS_SLAG = "Failed forging. Science isn't always pretty."

___________________________DESCRIBE.MS_ANVIL = "My scientist nature demands presision tools."
___________________________DESCRIBE.MS_ANVIL_HELPER = "My scientist nature demands presision tools."
___________________________DESCRIBE.MS_FURNACE = "Do not stick your head in it."
___________________________DESCRIBE.MS_FURNACE_BELLOW = "My fan desing would still be better."
___________________________DESCRIBE.MS_FURNACE_CAMPFIRE = {
	OUT = "I should get this fire going.",
	EMBERS = "Barely warm enough to melt anything.",
	LOW = "A modest little fire.",
	NORMAL = "Burning nicely.",
	HIGH = "Now that's a proper smelting fire!",
}

___________________________DESCRIBE.MS_ALU_ROCK = "An aluminium-rich boulder."
___________________________DESCRIBE.MS_COAL_ROCK = "A coal-bearing boulder."
___________________________DESCRIBE.MS_COPPER_ROCK = "A copper-rich boulder."
___________________________DESCRIBE.MS_GEODE_ROCK = "A boulder hiding geodes."
___________________________DESCRIBE.MS_GIANT_BOULDER_GRASS = "A boulder of unusual size. Mining it could take a while."
___________________________DESCRIBE.MS_GIANT_BOULDER_ROCK = "A boulder of unusual size. Mining it could take a while."
___________________________DESCRIBE.MS_GIANT_BOULDER_SNOW = "A boulder of unusual size. Mining it could take a while."

___________________________DESCRIBE.MS_APPLE_TREE = {
	GENERIC = "A modest apple tree.",
	BURNT = "Burnt to a crisp.",
	CHOPPED = "It put up a decent fight.",
}
___________________________DESCRIBE.MS_APPLE_TREE_SNOW = ___________________________DESCRIBE.MS_APPLE_TREE
___________________________DESCRIBE.MS_APPLE = "A fresh mountain apple."
___________________________DESCRIBE.MS_APPLE_COOKED = "Warm and sweet."
___________________________DESCRIBE.MS_APPLE_DRIED = "Chewy, and it'll keep."
___________________________DESCRIBE.MS_GOLDEN_APPLE = "Shiny, and probably overkill."
___________________________DESCRIBE.MS_BIG_APPLE = "Now that's an apple!"
___________________________DESCRIBE.MS_APPLE_CORE = "I could plant this."
___________________________DESCRIBE.MS_APPLE_PIE = "A proper mountain dessert."
___________________________DESCRIBE.MS_APPLE_CARAMEL = "Sticky, sweet, and dangerous to touch."
___________________________DESCRIBE.MS_POISONED_APPLE = "I shouldn't eat that."

___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN = {
	DEFAULT = "A peculiar rock.",
	ON = "A teleport to a far-away and totally safe place.",
	OFF = "Does not work. Can't help but think lack of caves is to blame.",
}
___________________________DESCRIBE.MS_WORLDMIGRATOR_UP = ___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN

___________________________DESCRIBE.MS_CLIMBING = "Looks climbable. Up we go!"
___________________________DESCRIBE.MS_CLIMBING_DOWN = "A way back down. Preferably not headfirst."
___________________________DESCRIBE.MS_ARENATELEPORTER = "An uncanny totem. Something fights on the other side."
___________________________DESCRIBE.MS_ARENATELEPORTER_EXIT = "An uncanny totem. The way out, hopefully."
___________________________DESCRIBE.MS_SHORTCUT = "A hollowed totem. Could link somewhere."
___________________________DESCRIBE.MS_SHORTCUT_ON = "It's awake. Destination unknown, adventure certain."
___________________________DESCRIBE.MS_SHORTCUT_EXIT = "A hollowed totem. The other end of a shortcut."
___________________________DESCRIBE.MS_SHORTCUT_EXIT_ON = "It's awake. Better hope the landing is soft."
___________________________DESCRIBE.MS_CAVE_ENTRANCE_VERTICAL = "A cave opening in the cliff face."
___________________________DESCRIBE.MS_CAVE_ENTRANCE = "A passage deeper into the mountain."
___________________________DESCRIBE.MS_CAVE_EXIT = "A passage back toward daylight."
___________________________DESCRIBE.MS_CAVE_ENTRANCE_LIGHT = "Light! That must be the way out."

___________________________DESCRIBE.MS_WALL_BUSH = "Stubborn shrubbery clinging to the cliff."
___________________________DESCRIBE.MS_WALL_STONE = "Ore peeking out of the rock face."
___________________________DESCRIBE.MS_BROKEN_PILLAR = "This column has seen better days."

___________________________DESCRIBE.MOUNTAIN_FROZEN_MEATBALLS = "Meatballs, frozen solid. Nature's fridge."
___________________________DESCRIBE.MOUNTAIN_KIKI = "A wild mountain monkey. It looks mischievous."
___________________________DESCRIBE.MOUNTAIN_KIKI_HOUSE = "Home sweet... nest?"
___________________________DESCRIBE.MOUNTAIN_CRATER_POOL = "A steaming crater pool. Warm and inviting."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE1 = "An icy snowball with a spike of attitude."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE2 = "A snowball that freezes on contact."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE3 = "A snowball that messes with the mind."
___________________________DESCRIBE.MOUNTAIN_FALCON = "A sharp-eyed falcon."
___________________________DESCRIBE.MOUNTAIN_FALCON_BASE = "A falcon's mound. Best not to disturb it."
___________________________DESCRIBE.MOUNTAIN_WINDHORN = "A horn that summons the wind itself."
___________________________DESCRIBE.MOUNTAIN_COCKROACH = "Ugh. A mountain cockroach."
___________________________DESCRIBE.MOUNTAIN_COCKROACH_NEST = "Where the cockroaches gather. Delightful."
___________________________DESCRIBE.MOUNTAIN_STALACTITE = "A stalactite. Holds up... well, hangs up."
___________________________DESCRIBE.MOUNTAIN_STALAGMITE = "A stalagmite. Growing from the ground up."
___________________________DESCRIBE.MOUNTAIN_GOAT = "A mountain goat. Sure-footed and stubborn."
___________________________DESCRIBE.MOUNTAIN_ICEGOAT = "A goat, but colder."
___________________________DESCRIBE.MOUNTAIN_GOLEM = "A living mountain! Or close enough."
___________________________DESCRIBE.MOUNTAIN_GOLEM_PILLAR = "A pillar of stone. It feels unfinished."
___________________________DESCRIBE.MOUNTAIN_GOLEM_PLATFORM = "A foundation for something enormous."
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK = "A block of compacted sand."
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK_CHARGED = "Sand, crackling with energy."
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_TALL = "A spike of sand. Pointy!"
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_CHARGED_TALL = "A charged sandspike. Extra pointy!"
___________________________DESCRIBE.MOUNTAIN_BUSH = "A hardy mountain fern."
___________________________DESCRIBE.DUG_MOUNTAIN_BUSH = "A dug-up mountain fern. I can replant it."
___________________________DESCRIBE.MOUNTAIN_PLANTS_BUSH = "A scraggly mountain bush."
___________________________DESCRIBE.MOUNTAIN_PLANTS_TREE = "A small mountain tree."
___________________________DESCRIBE.MOUNTAIN_PLANTS_GRASS = "Tough mountain grass."
___________________________DESCRIBE.MOUNTAIN_PLANTS_BRANCHES = "A little sapling."
___________________________DESCRIBE.MOUNTAIN_PLANTS_FLOWER = "A mountain flower."
___________________________DESCRIBE.MOUNTAIN_PLANTS_POMEGRANATE = "A pomegranate plant. Fancy!"

___________________________DESCRIBE.MOUNTAIN_YOTH_LANCE = "A bronze spear. Pointy science."
___________________________DESCRIBE.MOUNTAIN_WATHGRITHR_SHIELD = "A sturdy bronze shield."
___________________________DESCRIBE.MOUNTAIN_ARMOR_COPPER = "Bronze armor with serious muscle."
___________________________DESCRIBE.MOUNTAIN_HELMET_COPPER = "A bronze helmet. Protects the brains!"
___________________________DESCRIBE.MOUNTAIN_COPPER_AXE = "A copper axe. Chops with style."
___________________________DESCRIBE.MOUNTAIN_COPPER_BAT = "An aluminium bat. Lightweight punishment."
___________________________DESCRIBE.MOUNTAIN_GOAPACA_HORN = "A goat horn. Could be useful."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_AXE = "An aluminium axe. Light and sharp."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_PICKAXE = "An aluminium pickaxe. Mines with less effort."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_DAGGER = "An aluminium sword. Sleek!"
___________________________DESCRIBE.MOUNTAIN_COPPER_PICKAXE = "A copper pickaxe. Gets the job done."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDAXE = "A gilded axe taken to extremes."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDPICKAXE = "A gilded pickaxe taken to extremes."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDSHOVEL = "A gilded shovel taken to extremes."

___________________________DESCRIBE.MOUNTAIN_ICECREAM = "Mountain ice cream! Brain freeze incoming."
___________________________DESCRIBE.MOUNTAIN_TORNADO_SORBET = "A milkshake with a whirlwind kick."
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK = "A drumstick from something... monstrous."
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK_COOKED = "Fried monster meat. Surprisingly tempting."
___________________________DESCRIBE.MOUNTAIN_SNOWBALL = "A packed mountain snowball."
___________________________DESCRIBE.MOUNTAIN_SUSPICIOUS_ORE = "Suspicious ore. What's it hiding?"
___________________________DESCRIBE.MOUNTAIN_GREEN_STONE = "A green mountain stone."
___________________________DESCRIBE.MOUNTAIN_COLD_ROCK = "A stone that feels unnaturally cold."
___________________________DESCRIBE.MOUNTAIN_SNOWPEAK_STONE = "Stone from the snowy peaks."
___________________________DESCRIBE.MOUNTAIN_SNOWPILE = "A pile of mountain snow."
___________________________DESCRIBE.MOUNTAIN_GRAVEL_PILE = "A pile of gravel. Diggable potential."
___________________________DESCRIBE.MOUNTAIN_TRANSFORMATION_CUBE = "A cube that transforms materials. Pure science!"
___________________________DESCRIBE.MOUNTAIN_WOODEN_BOX = "A wooden box. What's inside?"
___________________________DESCRIBE.HAT_TINFOIL = "A tinfoil hat. For keeping... things... out."
___________________________DESCRIBE.MOUNTAIN_TOP = "A mountain top ripe for planting a flag."

___________________________DESCRIBE.TURF_MS_SNOW = "A chunk of snowy ground."
___________________________DESCRIBE.TURF_MS_BRICK = "A brick floor tile."
___________________________DESCRIBE.TURF_MS_CAVE = "A cave floor tile."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW = "Turf from the mountain lowlands."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW_2 = "Turf from the mountain lowlands."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_HIGH = "Turf from the mountain highlands."
___________________________DESCRIBE.TURF_MS_PERMAFROST = "Turf of permafrost. Permanently chilly."
