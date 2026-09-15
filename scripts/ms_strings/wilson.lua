------------------------------------------------------------------------------------------------------------------------
-- Wilson / GENERIC character examines (English default)

local ___________________________DESCRIBE = STRINGS.CHARACTERS.GENERIC.DESCRIBE
local ___________________________ANNOUNCE = STRINGS.CHARACTERS.GENERIC

-- Forging: ingots share temperature statuses (GENERIC / WARM / HOT / MELT)
local MS_INGOT_DESC = {
	GENERIC = "A solid metal ingot.",
	WARM = "I still can't forge it.",
	HOT = "It’s ready to be forged.",
	MELT = "It's as soft as warm butter!",
}
___________________________DESCRIBE.MS_COPPER_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_ALU_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_BRONZE_INGOT = MS_INGOT_DESC
___________________________DESCRIBE.MS_GOLD_INGOT = MS_INGOT_DESC

-- Details only toggle between cool and hot
local MS_DETAIL_DESC = {
	GENERIC = "A forged metal part. Perfect!",
	HOT = "It's hot from the anvil! I should handle this carefully!",
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

___________________________DESCRIBE.MS_COPPER_ORE = "Traces of oxidation are visible."
___________________________DESCRIBE.MS_ALU_ORE = "Too soft for metal."
___________________________DESCRIBE.MS_COAL = "Excellent furnace fuel."
___________________________DESCRIBE.MS_GEODE_ORE = "Maybe there's something in this rock?"
___________________________DESCRIBE.MS_SLAG = "Well, that didn't work."

___________________________DESCRIBE.MS_ANVIL = "A hammer is  needed for the job here."
___________________________DESCRIBE.MS_ANVIL_HELPER = "A hammer is  needed for the job here."
___________________________DESCRIBE.MS_FURNACE = "An oversized stove."
___________________________DESCRIBE.MS_FURNACE_BELLOW = "Let's turn up the heat!"
___________________________DESCRIBE.MS_FURNACE_CAMPFIRE = {
	OUT = "I should get this fire going.",
	EMBERS = "Barely warm enough for a proper smelting",
	LOW = "A modest little fire.",
	NORMAL = "Burning nicely.",
	HIGH = "Now that's a proper smelting fire!",
}

___________________________DESCRIBE.MS_ALU_ROCK = "An aluminium-rich boulder."
___________________________DESCRIBE.MS_COAL_ROCK = "A coal-bearing boulder."
___________________________DESCRIBE.MS_COPPER_ROCK = "A copper-rich boulder."
___________________________DESCRIBE.MS_GEODE_ROCK = "A boulder hiding geodes."
local MS_GIANT_BOULDER_DESC = {
	GENERIC = "A boulder of unusual size. Mining it could take a while.",
	EMPTY = "It's empty here.",
}
___________________________DESCRIBE.MS_GIANT_BOULDER_GRASS = MS_GIANT_BOULDER_DESC
___________________________DESCRIBE.MS_GIANT_BOULDER_ROCK = MS_GIANT_BOULDER_DESC
___________________________DESCRIBE.MS_GIANT_BOULDER_SNOW = MS_GIANT_BOULDER_DESC

___________________________DESCRIBE.MS_APPLE_TREE = {
	GENERIC = "A modest apple tree.",
	BURNT = "Burnt to a crisp.",
	CHOPPED = "It put up a decent fight.", --Instead of "Take that, nature!" ?
}
___________________________DESCRIBE.MS_APPLE_TREE_SNOW = ___________________________DESCRIBE.MS_APPLE_TREE
___________________________DESCRIBE.MS_APPLE = "A fresh mountain apple."
___________________________DESCRIBE.MS_APPLE_COOKED = "Warm and sweet."
___________________________DESCRIBE.MS_APPLE_DRIED = "Crispy slices."
___________________________DESCRIBE.MS_GOLDEN_APPLE = "I mine and crafted for it."
___________________________DESCRIBE.MS_BIG_APPLE = "Now that's an apple!"
___________________________DESCRIBE.MS_APPLE_CORE = "I could plant this."
___________________________DESCRIBE.MS_APPLE_PIE = "Now THAT is American!"
___________________________DESCRIBE.MS_APPLE_CARAMEL = "Sticky."
___________________________DESCRIBE.MS_POISONED_APPLE = "Poison trickles down the apple."

___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN = {
	DEFAULT = "A peculiar rock.",
	ON = "A teleport to a far-away.",
	OFF = "Does not work. Can't help but think lack of caves is to blame.",
}
___________________________DESCRIBE.MS_WORLDMIGRATOR_UP = ___________________________DESCRIBE.MS_WORLDMIGRATOR_DOWN

___________________________DESCRIBE.MS_CLIMBING = "Looks climbable. Up we go!"
___________________________DESCRIBE.MS_CLIMBING_DOWN = "A way down."
___________________________DESCRIBE.MS_ARENATELEPORTER = "An ominous aura emanates from it."
___________________________DESCRIBE.MS_ARENATELEPORTER_EXIT = "A convenient escape."
___________________________DESCRIBE.MS_SHORTCUT = {
	OFF = "A suitable energy source is needed.",
	ON = "A shortcut?",
}
___________________________DESCRIBE.MS_SHORTCUT_EXIT = ___________________________DESCRIBE.MS_SHORTCUT
___________________________DESCRIBE.MS_CAVE_ENTRANCE_VERTICAL = "A cave opening in the cliff's face."
___________________________DESCRIBE.MS_CAVE_ENTRANCE = "A passage deeper into the mountain."
___________________________DESCRIBE.MS_CAVE_EXIT = "A passage back toward daylight."
___________________________DESCRIBE.MS_CAVE_EXIT_LIGHT = "Light! That must be the way out."

___________________________DESCRIBE.MS_WALL_BUSH = "It grows at high altitudes."
___________________________DESCRIBE.MS_WALL_STONE = "Some ore has manifested in the rock. How do I get it out?"
___________________________DESCRIBE.MS_BROKEN_PILLAR = "Remains of an ancient mechanism?"

___________________________DESCRIBE.MOUNTAIN_FROZEN_MEATBALLS = "I can't bite through it."
___________________________DESCRIBE.MOUNTAIN_KIKI = "Gloomy monkey."
___________________________DESCRIBE.MOUNTAIN_KIKI_HOUSE = "A cold cave."
___________________________DESCRIBE.MOUNTAIN_CRATER_POOL = "A warm bath amidst the mountains."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE1 = "A chunk of snow is flying."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE2 = "Snow and ice."
___________________________DESCRIBE.MOUNTAIN_KIKI_PROJECTILE3 = "Not the hair!"
___________________________DESCRIBE.MOUNTAIN_FALCON = "A sharp-eyed hawk."
___________________________DESCRIBE.MOUNTAIN_FALCON_BASE = "A hawk's mound. Best not to disturb it."
___________________________DESCRIBE.MOUNTAIN_WINDHORN = "A horn that summons the wind itself."
___________________________DESCRIBE.MOUNTAIN_COCKROACH = "Ugh. A stone cockroach."
___________________________DESCRIBE.MOUNTAIN_COCKROACH_NEST = "That's where the cockroaches gather. Delightful."
___________________________DESCRIBE.MOUNTAIN_STALACTITE = "A stalactite. Holds up... well, hangs up."
___________________________DESCRIBE.MOUNTAIN_STALAGMITE = "A stalagmite. Growing from the ground up."
___________________________DESCRIBE.MOUNTAIN_GOAT = "Stubborn goatpaca"
___________________________DESCRIBE.MOUNTAIN_ICEGOAT = "The cold clearly makes him angry."
___________________________DESCRIBE.MOUNTAIN_GOLEM = "It wasn't worth waking him up."
___________________________DESCRIBE.MOUNTAIN_GOLEM_PILLAR = "It holds a great charge of energy."
___________________________DESCRIBE.MOUNTAIN_GOLEM_PLATFORM = "A foundation for something enormous."
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK = "That tower is blocking the way."
___________________________DESCRIBE.MOUNTAIN_SANDBLOCK_CHARGED = "His power lies in the tower."
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_TALL = "Sharp spike!"
___________________________DESCRIBE.MOUNTAIN_SANDSPIKE_CHARGED_TALL = "Ready to explode at any moment!"
___________________________DESCRIBE.MOUNTAIN_BUSH = "A hardy mountain fern."
___________________________DESCRIBE.DUG_MOUNTAIN_BUSH = "A dug-up mountain fern. I can replant it."
___________________________DESCRIBE.MOUNTAIN_PLANTS_BUSH = "A scraggly mountain bush."
___________________________DESCRIBE.MOUNTAIN_PLANTS_TREE = "A small mountain tree."
___________________________DESCRIBE.MOUNTAIN_PLANTS_GRASS = "Tough mountain grass."
___________________________DESCRIBE.MOUNTAIN_PLANTS_BRANCHES = "A little sapling."
___________________________DESCRIBE.MOUNTAIN_PLANTS_FLOWER = "Smells better than the other flowers I've seen."
___________________________DESCRIBE.MOUNTAIN_PLANTS_POMEGRANATE = "Wild pomegranate."

___________________________DESCRIBE.MOUNTAIN_YOTH_LANCE = "Sharp stuff."
___________________________DESCRIBE.MOUNTAIN_WATHGRITHR_SHIELD = "A sturdy bronze shield."
___________________________DESCRIBE.MOUNTAIN_ARMOR_COPPER = "A bronze suit with some serious muscle."
___________________________DESCRIBE.MOUNTAIN_HELMET_COPPER = "It's a rather shiny helmet."
___________________________DESCRIBE.MOUNTAIN_COPPER_AXE = "It hones itself with every chop!"
___________________________DESCRIBE.MOUNTAIN_COPPER_BAT = "The greener it is, the harder it hits."
___________________________DESCRIBE.MOUNTAIN_GOAPACA_HORN = "You could send a person flying with this."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_AXE = "Light and sharp."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_PICKAXE = "Now, not a single stone can hide from me."
___________________________DESCRIBE.MOUNTAIN_ALUMINUM_DAGGER = "Dart time!"
___________________________DESCRIBE.MOUNTAIN_COPPER_PICKAXE = "It oxidizes quickly."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDAXE = "It glistens in the sun."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDPICKAXE = "Much more gilded."
___________________________DESCRIBE.MOUNTAIN_SUPER_GILDEDSHOVEL = "I think that's too refined for such dirty work."

___________________________DESCRIBE.MOUNTAIN_ICECREAM = "I should eat it before it melts all over my fingers!"
___________________________DESCRIBE.MOUNTAIN_TORNADO_SORBET = "Now that's a shake that'll blow me away!"
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK = "A bunch of feathers are still stuck on the meat."
___________________________DESCRIBE.MOUNTAIN_MONSTER_DRUMSTICK_COOKED = "Think it'll still fly if I throw it?"
___________________________DESCRIBE.MOUNTAIN_SNOWBALL = "A packed mountain snowball."
___________________________DESCRIBE.MOUNTAIN_SUSPICIOUS_ORE = "I need to break it open to find out what's inside."
___________________________DESCRIBE.MOUNTAIN_GREEN_STONE = "There's grass on that stone."
___________________________DESCRIBE.MOUNTAIN_COLD_ROCK = "A dense stone structure."
___________________________DESCRIBE.MOUNTAIN_SNOWPEAK_STONE = "The stones maintain their balance."
___________________________DESCRIBE.MOUNTAIN_SNOWPILE = "Snowdrift."
___________________________DESCRIBE.MOUNTAIN_GRAVEL_PILE = "A pile of stones."
___________________________DESCRIBE.MOUNTAIN_TRANSFORMATION_CUBE = "Full of energy for transformation."
___________________________DESCRIBE.MOUNTAIN_WOODEN_BOX = "I hope there's something edible in there."
___________________________DESCRIBE.HAT_TINFOIL = "Protects the brain."
___________________________DESCRIBE.MOUNTAIN_TOP = "Finally! The Peak!"

___________________________DESCRIBE.TURF_MS_SNOW = "A carpet of snow."
___________________________DESCRIBE.TURF_MS_BRICK = "A brick floor tile."
___________________________DESCRIBE.TURF_MS_CAVE = "A cave floor tile."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW = "Turf from the mountain lowlands."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_LOW_2 = "Turf from the mountain lowlands."
___________________________DESCRIBE.TURF_MS_MOUNTAIN_HIGH = "Turf from the mountain highlands."
___________________________DESCRIBE.TURF_MS_PERMAFROST = "Turf of permafrost. Permanently chilly."

------------------------------------------------------------
-- Announcements

___________________________ANNOUNCE.MS_GOLDEN_APPLE_BUFF_START = {
	"I feel like the fairest one of them all!",
}
___________________________ANNOUNCE.MS_GOLDEN_APPLE_BUFF_END = {
	"Still feels like my head's in the nether...",
}
___________________________ANNOUNCE.MS_MOUNTAIN_ICE_CREAM_START = {
	"Ugh, brainfreeze!",
}
___________________________ANNOUNCE.MS_MOUNTAIN_ICE_CREAM_END = {
	"I still have goosebumps...",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_START = {
	"What a rush!",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_ABILITY_READY = {
	"I'm ready to reap another whirlwind!",
}
___________________________ANNOUNCE.MS_TORNADO_MILKSHAKE_END = {
	"I feel a little dizzy after all that...",
}