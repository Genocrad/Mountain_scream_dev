-- 控制台调试：c_give 会把物品直接给当前玩家
-- 用法：d_spawn_tools() / d_spawn_plants() / d_spawn_nests()

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
