local BUILDER_TAG = "mountain_science"
local CUBE_PREFAB = "mountain_transformation_cube"

-- 耐久消耗（占最大耐久比例）；33%/66% 按 1/3、2/3 计
local CUBE_RECIPES =
{
	{
		name = "ms_alterguardianhatshard",
		product = "alterguardianhatshard",
		ingredient = "moonglass_charged",
		cost = 0.3,
	},
	{
		name = "ms_shroom_skin",
		product = "shroom_skin",
		ingredient = "moon_cap",
		cost = 0.125,
	},
	{
		name = "ms_dragon_scales",
		product = "dragon_scales",
		ingredient = "redgem",
		cost = 0.125,
	},
	{
		name = "ms_greengem",
		product = "greengem",
		ingredient = "moonglass",
		cost = 0.05,
	},
	{
		name = "ms_deerclops_eyeball",
		product = "deerclops_eyeball",
		ingredient = "milkywhites",
		cost = 0.125,
	},
	{
		name = "ms_klaussackkey",
		product = "klaussackkey",
		ingredients = { "deer_antler1", "deer_antler2", "deer_antler3" },
		cost = 0.3,
		description = "klaussackkey",
	},
	{
		name = "ms_lightninggoathorn",
		product = "lightninggoathorn",
		ingredient = "boneshard",
		cost = 0.05,
	},
	{
		name = "ms_messagebottle",
		product = "messagebottle",
		ingredient = "messagebottleempty",
		cost = 0.05,
	},
	{
		name = "ms_dreadstone",
		product = "dreadstone",
		ingredient = "shadowheart",
		cost = 0.3,
		numtogive = 40,
	},
	{
		name = "ms_hivehat",
		product = "hivehat",
		ingredient = "bee",
		cost = 0.3,
	},
	{
		name = "ms_royal_jelly",
		product = "royal_jelly",
		ingredient = "honey",
		cost = 0.125,
	},
	{
		name = "ms_skeletonhat",
		product = "skeletonhat",
		ingredient = "cotl_trinket",
		cost = 0.6,
	},
	{
		name = "ms_mandrake",
		product = "mandrake",
		ingredient = "carrot",
		cost = 0.125,
	},
}

local RECIPE_COST = {}
for _, def in ipairs(CUBE_RECIPES) do
	RECIPE_COST[def.name] = def.cost
end

------------------------------------------------------------------------------------------------------------------------

AddRecipeFilter({
	name = "MOUNTAIN_SCIENCE",
	atlas = "images/inventoryimages/ms_crafticons.xml",
	image = "ms_crafticon.tex",
})

local CUBE_ATLAS = "images/inventoryimages/mountain_items.xml"

local function GetItemPercentUsed(item)
	if item == nil then
		return 0
	end
	if item.components.finiteuses ~= nil then
		return item.components.finiteuses:GetPercent()
	end
	local invitem = item.replica ~= nil and item.replica.inventoryitem or nil
	if invitem ~= nil and invitem.classified ~= nil then
		local v = invitem.classified.percentused:value()
		if v ~= nil and v ~= 255 then
			return v / 100
		end
	end
	return 0
end

local function TryAddCube(cubes, seen, item)
	if item == nil or seen[item] or item.prefab ~= CUBE_PREFAB then
		return
	end
	local pct = GetItemPercentUsed(item)
	if pct > 0 then
		seen[item] = true
		table.insert(cubes, item)
	end
end

local function AddCubesFromItemTable(cubes, seen, items)
	if items == nil then
		return
	end
	for _, item in pairs(items) do
		TryAddCube(cubes, seen, item)
	end
end

-- 收集身上所有可用转化方块（主机 components / 客户端 replica）
local function CollectTransformationCubes(inst)
	local cubes = {}
	local seen = {}

	if inst.components.inventory ~= nil then
		for _, item in ipairs(inst.components.inventory:FindItems(function(item)
			return item.prefab == CUBE_PREFAB and GetItemPercentUsed(item) > 0
		end)) do
			TryAddCube(cubes, seen, item)
		end
		for container_inst in pairs(inst.components.inventory.opencontainers) do
			local container = container_inst.components.container or container_inst.components.inventory
			if container ~= nil and container.FindItems ~= nil then
				for _, item in ipairs(container:FindItems(function(item)
					return item.prefab == CUBE_PREFAB and GetItemPercentUsed(item) > 0
				end)) do
					TryAddCube(cubes, seen, item)
				end
			end
		end
	else
		local inv = inst.replica.inventory
		if inv ~= nil then
			AddCubesFromItemTable(cubes, seen, inv:GetItems())
			TryAddCube(cubes, seen, inv:GetActiveItem())
			local overflow = inv:GetOverflowContainer()
			if overflow ~= nil and overflow.GetItems ~= nil then
				AddCubesFromItemTable(cubes, seen, overflow:GetItems())
			end
			local open = inv:GetOpenContainers()
			if open ~= nil then
				for container_inst in pairs(open) do
					local container = container_inst.replica ~= nil and container_inst.replica.container or nil
					if container ~= nil and container.GetItems ~= nil then
						AddCubesFromItemTable(cubes, seen, container:GetItems())
					end
				end
			end
		end
	end

	table.sort(cubes, function(a, b)
		return GetItemPercentUsed(a) < GetItemPercentUsed(b)
	end)

	return cubes
end

-- cost 以「一个满耐久方块」为 1；多个方块的剩余百分比可累加
local function GetTotalCubePercent(inst)
	local total = 0
	for _, cube in ipairs(CollectTransformationCubes(inst)) do
		total = total + GetItemPercentUsed(cube)
	end
	return total
end

local function HasCubeDurability(inst, cost)
	return GetTotalCubePercent(inst) + 1e-4 >= cost
end

local function ConsumeCubeDurability(inst, cost)
	local remaining = cost
	local cubes = CollectTransformationCubes(inst)
	if #cubes == 0 then
		return false
	end

	for _, cube in ipairs(cubes) do
		if remaining <= 1e-6 then
			break
		end
		if not cube:IsValid() or cube.components.finiteuses == nil then
			-- skip
		else
			local finiteuses = cube.components.finiteuses
			local pct = finiteuses:GetPercent()
			if pct <= 0 then
				-- skip
			elseif pct + 1e-6 >= remaining then
				finiteuses:Use(finiteuses.total * remaining)
				remaining = 0
				break
			else
				remaining = remaining - pct
				finiteuses:Use(finiteuses.current)
			end
		end
	end

	return remaining <= 1e-4
end

local function CanBuildWithCube(recipe, builder)
	local cost = RECIPE_COST[recipe.name]
	if cost == nil then
		return true
	end
	if not builder:HasTag(BUILDER_TAG) or not HasCubeDurability(builder, cost) then
		return false, "MOUNTAIN_CUBE"
	end
	return true
end

for _, def in ipairs(CUBE_RECIPES) do
	local config = {
		product = def.product,
		description = def.description or def.product,
		image = def.product..".tex",
		builder_tag = BUILDER_TAG,
		no_deconstruction = true,
		numtogive = def.numtogive,
		canbuild = CanBuildWithCube,
		mountain_cube_cost = def.cost,
	}

	local ingredients = {}
	if def.ingredients ~= nil then
		for _, prefab in ipairs(def.ingredients) do
			table.insert(ingredients, Ingredient(prefab, 1))
		end
	else
		table.insert(ingredients, Ingredient(def.ingredient, 1))
	end
	-- amount 0：仅展示 / 要求持有，不整颗消耗；耐久由制作回调按百分比扣除
	table.insert(ingredients, Ingredient(CUBE_PREFAB, 0, CUBE_ATLAS))

	AddRecipe2(
		def.name,
		ingredients,
		TECH.NONE,
		config,
		{ "MOUNTAIN_SCIENCE" }
	)
	RemoveRecipeFromFilter(def.name, "MODS")
end

------------------------------------------------------------------------------------------------------------------------
-- 物品栏持有方块 → 解锁过滤器 / 配方

local function RefreshMountainScienceTag(inst)
	if inst.components.inventory == nil then
		return
	end
	local has = inst.components.inventory:Has(CUBE_PREFAB, 1, true)
	if has then
		inst:AddTag(BUILDER_TAG)
	else
		inst:RemoveTag(BUILDER_TAG)
	end
	inst:PushEvent("refreshcrafting")
end

local function OnBuildMountainScience(inst, data)
	if data == nil or data.recipe == nil then
		return
	end
	if inst.components.builder ~= nil and inst.components.builder.freebuildmode then
		return
	end
	local cost = RECIPE_COST[data.recipe.name] or data.recipe.mountain_cube_cost
	if cost == nil then
		return
	end
	ConsumeCubeDurability(inst, cost)
end

AddPlayerPostInit(function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst:DoTaskInTime(0, RefreshMountainScienceTag)

	inst:ListenForEvent("itemget", function()
		RefreshMountainScienceTag(inst)
	end)
	inst:ListenForEvent("itemlose", function()
		RefreshMountainScienceTag(inst)
	end)
	inst:ListenForEvent("builditem", OnBuildMountainScience)
	inst:ListenForEvent("buildstructure", OnBuildMountainScience)
end)

------------------------------------------------------------------------------------------------------------------------
-- HasIngredients：耐久不足时视为材料不够（制作按钮置灰；主机 + 客户端）

local function PatchHasIngredients(self)
	local old_HasIngredients = self.HasIngredients
	function self:HasIngredients(recipe)
		if not old_HasIngredients(self, recipe) then
			return false
		end
		if type(recipe) == "string" then
			recipe = GetValidRecipe(recipe)
		end
		if recipe == nil then
			return false
		end
		local cost = RECIPE_COST[recipe.name] or recipe.mountain_cube_cost
		if cost == nil then
			return true
		end
		return HasCubeDurability(self.inst, cost)
	end
end

AddComponentPostInit("builder", PatchHasIngredients)
AddClassPostConstruct("components/builder_replica", PatchHasIngredients)

------------------------------------------------------------------------------------------------------------------------
-- 制作栏材料栏：显示方块当前合计耐久 / 所需耐久，不足时标红
--
-- 关键因：PopulateRecipeDetailPanel 里是
--   root_right:AddChild(CraftingMenuIngredients(owner, 4, recipe))
-- 构造函数会立刻 SetRecipe，此时 ingredients 还没有 parent。
-- 在未入树时创建的 Text 常常不渲染；拿起/放下物品会走「已入树」的
-- SetRecipe 刷新，所以百分比才出现。切换配方会重新构造，问题再现。
-- 修复：入树后再刷一次；未入树则 DoTaskInTime(0) 延迟刷。

local Text = require("widgets/text")

local function UpdateCubeIngredientDisplay(ingredients_widget, recipe)
	if ingredients_widget == nil or recipe == nil then
		return
	end
	local cost = RECIPE_COST[recipe.name]
	if cost == nil or ingredients_widget.ingredient_widgets == nil then
		return
	end

	local have = GetTotalCubePercent(ingredients_widget.owner)
	local has_enough = have + 1e-4 >= cost
	local have_pct = math.floor(have * 100 + 0.5)
	local cost_pct = math.floor(cost * 100 + 0.5)

	local num = ingredients_widget.num_items or 1
	local scale = math.min(1, (ingredients_widget.max_ingredients_wide or 4) / math.max(1, num))
	local quant_text_scale = math.max(1, 1 / (scale * 1.125))
	if ingredients_widget.extra_quantity_scale ~= nil then
		quant_text_scale = quant_text_scale * ingredients_widget.extra_quantity_scale
	end

	for _, ing in ipairs(ingredients_widget.ingredient_widgets) do
		if ing.recipe_type == CUBE_PREFAB and ing.inst:IsValid() then
			ing.has_enough = has_enough
			ing:Enable()
			ing:SetClickable(false)

			local atlas = resolvefilepath("images/hud.xml")
			local tex = has_enough and "inv_slot.tex" or "resource_needed.tex"
			ing:SetTextures(atlas, tex, tex, tex, tex, tex)

			if ing.quant ~= nil then
				ing.quant:Kill()
				ing.quant = nil
			end
			ing.quant = ing:AddChild(Text(SMALLNUMBERFONT, JapaneseOnPS4() and 30 or 24))
			ing.quant:SetPosition(7, -32, 0)
			ing.quant:SetScale(quant_text_scale, quant_text_scale)
			ing.quant:SetString(string.format("%d%%/%d%%", have_pct, cost_pct))
			ing.quant:Show()
			ing.quant:MoveToFront()
			if has_enough then
				ing.quant:SetColour(1, 1, 1, 1)
			else
				ing.quant:SetColour(255 / 255, 155 / 255, 155 / 255, 1)
			end

			local tip = STRINGS.NAMES.MOUNTAIN_TRANSFORMATION_CUBE or CUBE_PREFAB
			if not has_enough then
				tip = tip.."\n"..(STRINGS.UI.CRAFTING.MOUNTAIN_CUBE or "")
			end
			ing:SetTooltip(tip)
		end
	end
end

AddClassPostConstruct("widgets/redux/craftingmenu_ingredients", function(self)
	local old_SetRecipe = self.SetRecipe
	function self:SetRecipe(recipe, ...)
		old_SetRecipe(self, recipe, ...)
		if recipe == nil or RECIPE_COST[recipe.name] == nil then
			return
		end

		local function apply()
			if self.inst:IsValid() and self.recipe == recipe then
				UpdateCubeIngredientDisplay(self, recipe)
			end
		end

		-- 已挂到 UI 树：立刻刷；构造阶段尚未 AddChild：延迟到下一帧
		if self.parent ~= nil then
			apply()
		else
			self.inst:DoTaskInTime(0, apply)
		end
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- 详情面板填完后（ingredients 已 AddChild）再强制刷一次百分比

AddClassPostConstruct("widgets/redux/craftingmenu_details", function(self)
	local old_Populate = self.PopulateRecipeDetailPanel
	function self:PopulateRecipeDetailPanel(data, skin_name, ...)
		local ret = old_Populate(self, data, skin_name, ...)
		if self.ingredients ~= nil
			and data ~= nil
			and data.recipe ~= nil
			and RECIPE_COST[data.recipe.name] ~= nil then
			UpdateCubeIngredientDisplay(self.ingredients, data.recipe)
		end
		return ret
	end

	local old_UpdateBuildButton = self.UpdateBuildButton
	function self:UpdateBuildButton(...)
		old_UpdateBuildButton(self, ...)
		if self.data == nil or self.data.recipe == nil then
			return
		end
		local cost = RECIPE_COST[self.data.recipe.name]
		if cost == nil then
			return
		end
		if HasCubeDurability(self.owner, cost) then
			return
		end

		local meta = self.data.meta
		if meta == nil or meta.build_state == "hint" or meta.build_state == "hide" then
			return
		end

		local teaser = self.build_button_root.teaser
		local button = self.build_button_root.button
		local msg = STRINGS.UI.CRAFTING.MOUNTAIN_CUBE

		if TheInput:ControllerAttached() then
			teaser:SetSize(20)
			teaser:UpdateOriginalSize()
			teaser:SetMultilineTruncatedString(msg, 2, (self.panel_width / 2) * 0.8, nil, false, true)
			teaser:Show()
			button:Hide()
		else
			button:Hide()
			teaser:SetSize(20)
			teaser:UpdateOriginalSize()
			teaser:SetMultilineTruncatedString(msg, 2, (self.panel_width / 2) * 0.8, nil, false, true)
			teaser:Show()
		end
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- 制作栏：无方块时隐藏 MOUNTAIN_SCIENCE 过滤器按钮

AddClassPostConstruct("widgets/redux/craftingmenu_widget", function(self)
	local function UpdateMountainScienceFilter(menu)
		local btn = menu.filter_buttons ~= nil and menu.filter_buttons.MOUNTAIN_SCIENCE or nil
		if btn == nil then
			return
		end
		local owner = menu.owner
		local show = owner ~= nil and owner:HasTag(BUILDER_TAG)
		if show then
			btn:Show()
		else
			btn:Hide()
			if menu.current_filter_name == "MOUNTAIN_SCIENCE" then
				menu:SelectFilter(CRAFTING_FILTERS.FAVORITES.name, true)
			end
		end
	end

	local old_UpdateFilterButtons = self.UpdateFilterButtons
	function self:UpdateFilterButtons(...)
		local result = old_UpdateFilterButtons(self, ...)
		UpdateMountainScienceFilter(self)
		return result
	end

	local old_OnCraftingMenuOpen = self.OnCraftingMenuOpen
	function self:OnCraftingMenuOpen(...)
		UpdateMountainScienceFilter(self)
		return old_OnCraftingMenuOpen(self, ...)
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- 保留原有：山地雪球 → 冰块

AddRecipe2("mountain_snowball_ice",
	{ Ingredient("mountain_snowball", 2, "images/inventoryimages/mountain_items.xml") },
	TECH.SCIENCE_ONE,
	{
		product = "ice",
		description = "ice",
		image = "ice.tex",
	},
	{ "REFINE", "COOKING" }
)

-- Tool recipies
AddRecipe2("mountain_copper_pickaxe", { Ingredient("twigs", 2), Ingredient("ms_copper_detail", 1) }, TECH.SCIENCE_TWO, nil, {"TOOLS"})
AddRecipe2("mountain_aluminum_pickaxe", { Ingredient("twigs", 2), Ingredient("ms_alu_detail", 1) }, TECH.SCIENCE_TWO, nil, {"TOOLS"})
AddRecipe2("mountain_super_gildedpickaxe", { Ingredient("goldenpickaxe", 1), Ingredient("ms_gold_detail", 1) }, TECH.SCIENCE_TWO, nil, {"TOOLS"})
AddRecipe2("mountain_copper_axe", { Ingredient("twigs", 2), Ingredient("ms_copper_detail", 1) }, TECH.SCIENCE_TWO, nil, {"TOOLS"})
AddRecipe2("mountain_aluminum_axe", { Ingredient("twigs", 2), Ingredient("ms_alu_detail", 1) }, TECH.SCIENCE_TWO, nil, {"TOOLS"})
AddRecipe2("mountain_super_gildedaxe", { Ingredient("goldenaxe", 1), Ingredient("ms_gold_detail", 1) }, TECH.SCIENCE_TWO, nil, {"TOOLS"})
AddRecipe2("mountain_super_gildedshovel", { Ingredient("goldenshovel", 1), Ingredient("ms_gold_detail", 1) }, TECH.SCIENCE_TWO, nil, {"TOOLS"})
-- Weapons
AddRecipe2("mountain_copper_bat",  { Ingredient("ms_copper_detail", 2) }, TECH.SCIENCE_TWO, { image = "mountain_copper_bat_1.tex"}, nil, {"WEAPONS"})
AddRecipe2("mountain_aluminum_dagger", { Ingredient("twigs", 2), Ingredient("ms_alu_detail", 1) }, TECH.SCIENCE_TWO, nil, {"WEAPONS"})
AddRecipe2("mountain_yoth_lance", { Ingredient("twigs", 4), Ingredient("ms_bronze_detail", 2) }, TECH.SCIENCE_TWO, nil, {"WEAPONS"})
AddRecipe2("mountain_wathgrithr_shield", { Ingredient("ms_bronze_detail", 2), Ingredient("pigskin", 1)}, TECH.SCIENCE_TWO, nil, {"WEAPONS", "ARMOUR"})
AddRecipe2("mountain_windhorn", { Ingredient("ms_bronze_detail", 1), Ingredient("mountain_goapaca_horn", 1), Ingredient("goose_feather", 3)}, TECH.SCIENCE_TWO,  nil, {"WEAPONS", "MAGIC"})

-- Armour
AddRecipe2("mountain_helmet_copper", { Ingredient("ms_bronze_detail", 2) }, TECH.SCIENCE_TWO, nil, {"ARMOUR"})
AddRecipe2("mountain_armor_copper", { Ingredient("ms_bronze_detail", 2) }, TECH.SCIENCE_TWO, nil, {"ARMOUR"})
