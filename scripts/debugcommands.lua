-- 控制台调试：c_give 会把物品直接给当前玩家
-- 用法：d_spawn_tools() / d_spawn_plants() / d_spawn_nests()

-- Local client console: c_mslook("dusk", "snow") previews ambient lighting and colour grading.
-- Phases: day, dusk, night, fullmoon. Regions: low, high, snow, or levels 1-10 (6 uses the legacy mountain look).
-- Omitting the region uses the player's current level. The preview stays active until c_mslook() resets it.
-- Affects local visuals only; world time and server-side light checks remain unchanged.
do
	local REGIONS = { low = 1, high = 4, snow = 7 }
	local PHASES = { day = "day", dusk = "dusk", night = "night", fullmoon = "full_moon" }

	local function Fail(message)
		print("[c_mslook] " .. message)
		return false
	end

	function c_mslook(phase, region)
		local MountainLighting = require("mountainlighting")
		local MountainColourCubes = require("mountaincolourcubes")

		if TheNet == nil or TheNet:IsDedicated() then
			return Fail("请在游戏内客户端的本地控制台执行。")
		end
		if ThePlayer == nil or not ThePlayer:IsValid() or TheWorld == nil then
			return Fail("当前没有可用的本地玩家，请进入游戏后重试。")
		end
		local ambient = TheWorld.components.ambientlighting
		local colourcube = TheWorld.components.colourcube
		if ambient == nil or ambient.MS_SetLookPreview == nil
			or colourcube == nil or colourcube.MS_SetLookPreview == nil then
			return Fail("当前世界的客户端光照预览接口尚未就绪。")
		end

		if phase == nil and region == nil then
			ambient:MS_SetLookPreview(nil)
			colourcube:MS_SetLookPreview(nil)
			print("[c_mslook] 已恢复当前区域与时间的自然光照和滤镜。")
			return true
		end
		if PHASES[phase] == nil then
			return Fail('时段为 "day"、"dusk"、"night" 或 "fullmoon"；c_mslook() 恢复。')
		end

		local level
		if region == nil then
			local tracker = ThePlayer.components.dungeonplayertracker
			level = tracker ~= nil and tracker:GetLevel() or nil
		elseif type(region) == "string" then
			level = REGIONS[region] or tonumber(region)
		elseif type(region) == "number" then
			level = region
		end
		if level == nil or MountainColourCubes[level] == nil then
			return Fail('区域为 "low"、"high"、"snow" 或 1 到 10 的整数；省略时使用当前山地区域。')
		end

		ambient:MS_SetLookPreview(MountainLighting.GetPhaseColours(level)[phase].colour)
		colourcube:MS_SetLookPreview(MountainColourCubes[level][PHASES[phase]])
		print(string.format("[c_mslook] 本地预览：%s，区域 %d。输入 c_mslook() 恢复。", phase, level))
		return true
	end
end

function d_spawn_tools()
	c_give("mountain_yoth_lance")
	c_give("mountain_armor_copper")
	c_give("mountain_helmet_copper")
	c_give("mountain_wathgrithr_shield")
	c_give("mountain_copper_axe")
	c_give("mountain_copper_pickaxe")
	c_give("mountain_super_gildedaxe")
	c_give("mountain_super_gildedpickaxe")
	c_give("mountain_super_gildedshovel")
	c_give("mountain_aluminum_axe")
	c_give("mountain_aluminum_pickaxe")
	c_give("mountain_aluminum_dagger")
	c_give("mountain_copper_bat")
	c_give("mountain_windhorn")
	c_give("mountain_goapaca_horn")
end

function d_spawn_butterfly()
	c_spawn("mountain_butterfly")
end

function d_spawn_screamer()
	c_spawn("mountain_screamer")
end

function d_spawn_screamer_battle()
	local inst = c_spawn("mountain_screamer")
	if inst ~= nil then
		inst._engaged = true
		inst._wants_despawn = false
	end
end

-- 夜间注视态：在当前玩家附近刷一只（走 spawner）
function d_spawn_screamer_stalk()
	local spawner = TheWorld.components.mountainscreamerspawner
	if spawner == nil then
		print("mountainscreamerspawner missing")
		return
	end
	local player = ConsoleCommandPlayer and ConsoleCommandPlayer() or AllPlayers[1]
	return spawner:DebugSpawnNear(player)
end

function d_spawn_plants()
	local plants = {
		"mountain_plants_bush_1",
		"mountain_plants_bush_2",
		"mountain_plants_bush_3",
		"mountain_plants_tree",
		"mountain_plants_grass",
		"mountain_plants_branches",
		"mountain_plants_flower",
	}
	local pos = ConsoleWorldPosition()
	local x, y, z = pos.x, pos.y, pos.z
	local radius = 3
	local count = #plants
	for i, prefab in ipairs(plants) do
		local angle = (i - 1) * TWOPI / count
		local item = SpawnPrefab(prefab)
		if item ~= nil then
			item.Transform:SetPosition(
				x + math.cos(angle) * radius,
				y,
				z + math.sin(angle) * radius
			)
		end
	end
end

function d_spawn_nests()
	local nests = {
		"mountain_cockroach_nest_1",
		"mountain_cockroach_nest_2",
		"mountain_cockroach_nest_3",
	}
	local pos = ConsoleWorldPosition()
	local x, y, z = pos.x, pos.y, pos.z
	for i, prefab in ipairs(nests) do
		local item = SpawnPrefab(prefab)
		if item ~= nil then
			item.Transform:SetPosition(x + (i - 2) * 3, y, z)
		end
	end
end

function d_spawn_stalactites()
	local rocks = {
		"mountain_stalactite_1",
		"mountain_stalactite_2",
		"mountain_stalactite_3",
	}
	local pos = ConsoleWorldPosition()
	local x, y, z = pos.x, pos.y, pos.z
	for i, prefab in ipairs(rocks) do
		local item = SpawnPrefab(prefab)
		if item ~= nil then
			item.Transform:SetPosition(x + (i - 2) * 3, y, z)
		end
	end
end

function d_spawn_stalagmites()
	local rocks = {
		"mountain_stalagmite_1",
		"mountain_stalagmite_2",
		"mountain_stalagmite_3",
	}
	local pos = ConsoleWorldPosition()
	local x, y, z = pos.x, pos.y, pos.z
	for i, prefab in ipairs(rocks) do
		local item = SpawnPrefab(prefab)
		if item ~= nil then
			item.Transform:SetPosition(x + (i - 2) * 3, y, z)
		end
	end
end

function d_spawn_snowpile()
	local pos = ConsoleWorldPosition()
	local inst = SpawnPrefab("mountain_snowpile")
	if inst ~= nil then
		inst.Transform:SetPosition(pos:Get())
	end
end

function d_spawn_gravel()
	local pos = ConsoleWorldPosition()
	local inst = SpawnPrefab("mountain_gravel_pile")
	if inst ~= nil then
		inst.Transform:SetPosition(pos:Get())
	end
end

function d_spawn_bones()
	local pos = ConsoleWorldPosition()
	local names = { "ms_bone_pile", "ms_bone_throne", "ms_bone_chandelier" }
	for i, name in ipairs(names) do
		local inst = SpawnPrefab(name)
		if inst ~= nil then
			inst.Transform:SetPosition(pos.x + (i - 2) * 3, 0, pos.z)
		end
	end
end

function d_spawn_mountain_top()
	local pos = ConsoleWorldPosition()
	local inst = SpawnPrefab("mountain_top")
	if inst ~= nil then
		inst.Transform:SetPosition(pos:Get())
	end
end

function d_give_cube()
	c_give("mountain_transformation_cube")
end

function d_give_goathorn()
	c_give("mountain_goapaca_horn")
end

function d_spawn_stones()
	local stones = {
		"mountain_green_stone_1",
		"mountain_green_stone_2",
		"mountain_green_stone_3",
		"mountain_cold_rock_1",
		"mountain_cold_rock_2",
		"mountain_cold_rock_3",
		"mountain_snowpeak_stone_1",
		"mountain_snowpeak_stone_2",
		"mountain_snowpeak_stone_3",
		"mountain_snowpile",
	}
	local pos = ConsoleWorldPosition()
	local x, y, z = pos.x, pos.y, pos.z
	local radius = 3
	local count = #stones
	for i, prefab in ipairs(stones) do
		local angle = (i - 1) * TWOPI / count
		local item = SpawnPrefab(prefab)
		if item ~= nil then
			item.Transform:SetPosition(
				x + math.cos(angle) * radius,
				y,
				z + math.sin(angle) * radius
			)
		end
	end
end
