require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/mountain_bush.zip"),
	Asset("MINIMAP_IMAGE", "marsh_bush"),
}

local prefabs =
{
	"dug_mountain_bush",
	"cutgrass",
	"twigs",
	"petals",
	"foliage",
	"silk",
	"rope",
	"seeds",
	"purplegem",
	"bluegem",
	"redgem",
	"orangegem",
	"yellowgem",
	"greengem",
	"trinket_6",
	"trinket_4",
	"cutreeds",
	"feather_crow",
	"feather_robin",
	"feather_robin_winter",
	"feather_canary",
	"trinket_3",
	"beefalowool",
	"rabbit",
	"mole",
	"butterflywings",
	"beardhair",
	"berries",
	"blueprint",
	"petals_evil",
	"trinket_8",
	"houndstooth",
	"stinger",
	"gears",
	"spider",
	"frog",
	"bee",
	"mosquito",
	"boneshard",
	"cookingrecipecard",
	"scrapbook_page",
}

local CHESS_LOOT =
{
	"chesspiece_pawn_sketch",
	"chesspiece_muse_sketch",
	"chesspiece_formal_sketch",
	"trinket_15",
	"trinket_16",
	"trinket_28",
	"trinket_29",
	"trinket_30",
	"trinket_31",
}

for _, v in ipairs(CHESS_LOOT) do
	table.insert(prefabs, v)
end

-- 与 tumbleweed 完全一致的掉落池 / 抽样逻辑
local function MakeLoot(inst)
	local possible_loot =
	{
		{ chance = 40,   item = "cutgrass" },
		{ chance = 40,   item = "twigs" },
		{ chance = 1,    item = "petals" },
		{ chance = 1,    item = "foliage" },
		{ chance = 1,    item = "silk" },
		{ chance = 1,    item = "rope" },
		{ chance = 2,    item = "seeds" },
		{ chance = 0.01, item = "purplegem" },
		{ chance = 0.04, item = "bluegem" },
		{ chance = 0.02, item = "redgem" },
		{ chance = 0.02, item = "orangegem" },
		{ chance = 0.01, item = "yellowgem" },
		{ chance = 0.02, item = "greengem" },
		{ chance = 0.5,  item = "trinket_6" },
		{ chance = 0.5,  item = "trinket_4" },
		{ chance = 1,    item = "cutreeds" },
		{ chance = 0.33, item = "feather_crow" },
		{ chance = 0.33, item = "feather_robin" },
		{ chance = 0.33, item = "feather_robin_winter" },
		{ chance = 0.33, item = "feather_canary" },
		{ chance = 1,    item = "trinket_3" },
		{ chance = 1,    item = "beefalowool" },
		{ chance = 0.1,  item = "rabbit" },
		{ chance = 0.1,  item = "mole" },
		{ chance = 0.1,  item = "spider", aggro = true },
		{ chance = 0.1,  item = "frog", aggro = true },
		{ chance = 0.1,  item = "bee", aggro = true },
		{ chance = 0.1,  item = "mosquito", aggro = true },
		{ chance = 1,    item = "butterflywings" },
		{ chance = .02,  item = "beardhair" },
		{ chance = 1,    item = "berries" },
		{ chance = 1,    item = "blueprint" },
		{ chance = 1,    item = "petals_evil" },
		{ chance = 1,    item = "trinket_8" },
		{ chance = 1,    item = "houndstooth" },
		{ chance = 1,    item = "stinger" },
		{ chance = 1,    item = "gears" },
		{ chance = 0.1,  item = "boneshard" },
		{ chance = 0.25, item = "cookingrecipecard" },
		{ chance = 0.25, item = "scrapbook_page" },
	}

	local chessunlocks = TheWorld.components.chessunlocks
	if chessunlocks ~= nil then
		for _, v in ipairs(CHESS_LOOT) do
			if not chessunlocks:IsLocked(v) then
				table.insert(possible_loot, { chance = .1, item = v })
			end
		end
	end

	local totalchance = 0
	for _, n in ipairs(possible_loot) do
		totalchance = totalchance + n.chance
	end

	inst.loot = {}
	inst.lootaggro = {}
	local num_loots = 3
	while num_loots > 0 do
		local next_chance = math.random() * totalchance
		local next_loot = nil
		local next_aggro = nil
		for _, n in ipairs(possible_loot) do
			next_chance = next_chance - n.chance
			if next_chance <= 0 then
				next_loot = n.item
				if n.aggro then
					next_aggro = true
				end
				break
			end
		end
		if next_loot ~= nil then
			table.insert(inst.loot, next_loot)
			table.insert(inst.lootaggro, next_aggro == true)
			num_loots = num_loots - 1
		end
	end
end

local function DropTumbleweedLoot(inst, picker)
	MakeLoot(inst)

	if IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) then
		if TryLuckRoll(picker, TUNING.HALLOWEEN_ORNAMENT_TUMBLEWEED_CHANCE, LuckFormulas.LootDropperChance) then
			table.insert(inst.loot, "halloween_ornament_" .. tostring(math.random(NUM_HALLOWEEN_ORNAMENTS)))
			table.insert(inst.lootaggro, false)
		end
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(inst.loot) do
		local item = SpawnPrefab(v)
		if item ~= nil then
			item.Transform:SetPosition(x, y, z)

			if item.components.inventoryitem ~= nil and item.components.inventoryitem.ondropfn ~= nil then
				item.components.inventoryitem.ondropfn(item)
			end

			if inst.lootaggro[i] and item.components.combat ~= nil and picker ~= nil then
				if not (
					item:HasTag("spider") and (picker:HasTag("spiderwhisperer") or picker:HasTag("spiderdisguise") or (picker:HasTag("monster") and not picker:HasTag("player")))
					or item:HasTag("frog") and picker:HasTag("merm")
				) then
					item.components.combat:SuggestTarget(picker)
				end
			end
		end
	end
end

local function ontransplantfn(inst)
	inst.components.pickable:MakeEmpty()
end

local function dig_up(inst, digger)
	if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
		DropTumbleweedLoot(inst, digger)
	end
	inst.components.lootdropper:SpawnLootPrefab("dug_mountain_bush")
	inst:Remove()
end

local function onpickedfn(inst, picker)
	inst.AnimState:PlayAnimation("picking")
	inst.AnimState:PushAnimation("picked", false)
	DropTumbleweedLoot(inst, picker)
end

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow")
	inst.AnimState:PushAnimation("idle", true)
end

local function makeemptyfn(inst)
	inst.AnimState:PlayAnimation("idle_dead")
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	inst:SetDeploySmartRadius(DEPLOYSPACING_RADIUS[DEPLOYSPACING.MEDIUM] / 2)

	inst.AnimState:SetBank("mountain_bush")
	inst.AnimState:SetBuild("mountain_bush")
	inst.AnimState:PlayAnimation("idle", true)

	inst.MiniMapEntity:SetIcon("mountain_bush.tex")
	inst.MiniMapEntity:SetPriority(-1)

	inst:AddTag("plant")
	inst:AddTag("silviculture")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

	local color = 0.5 + math.random() * 0.5
	inst.AnimState:SetMultColour(color, color, color, 1)

	inst:AddComponent("pickable")
	inst.components.pickable.picksound = "dontstarve/wilson/harvest_sticks"
	-- product 为 nil：掉落全部由 onpickedfn 按风滚草表生成
	inst.components.pickable:SetUp(nil, TUNING.MOUNTAIN_BUSH.REGROW_TIME)
	inst.components.pickable.onregenfn = onregenfn
	inst.components.pickable.onpickedfn = onpickedfn
	inst.components.pickable.makeemptyfn = makeemptyfn
	inst.components.pickable.ontransplantfn = ontransplantfn

	inst:AddComponent("lootdropper")
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(dig_up)
	inst.components.workable:SetWorkLeft(1)

	inst:AddComponent("inspectable")

	MakeLargeBurnable(inst)
	MakeMediumPropagator(inst)
	MakeHauntableIgnite(inst)

	MakeWaxablePlant(inst)

	return inst
end

--------------------------------------------------------------------------
-- dug_mountain_bush

local dug_assets =
{
	Asset("ANIM", "anim/mountain_bush.zip"),
}

local function ondeploy(inst, pt, deployer)
	local bush = SpawnPrefab("mountain_bush")
	if bush ~= nil then
		bush.Transform:SetPosition(pt:Get())
		inst.components.stackable:Get():Remove()
		if bush.components.pickable ~= nil then
			bush.components.pickable:OnTransplant()
		end
		if deployer ~= nil and deployer.SoundEmitter ~= nil then
			deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
		end
	end
end

local function dug_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst:AddTag("deployedplant")

	inst.AnimState:SetBank("mountain_bush")
	inst.AnimState:SetBuild("mountain_bush")
	inst.AnimState:PlayAnimation("dropped")
	inst.scrapbook_anim = "dropped"
	inst.scrapbook_specialinfo = "PLANTABLE"

	MakeInventoryFloatable(inst, "med", 0.1, 0.9)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	-- 暂无沼泽荆棘挖起物图标；有自制图后可改回 dug_mountain_bush
	inst.components.inventoryitem.imagename = "dug_mountain_bush"

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

	MakeMediumBurnable(inst, TUNING.LARGE_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunchAndIgnite(inst)

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = ondeploy
	inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
	inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)

	return inst
end

return Prefab("mountain_bush", fn, assets, prefabs),
	Prefab("dug_mountain_bush", dug_fn, dug_assets, { "mountain_bush" }),
	MakePlacer("dug_mountain_bush_placer", "mountain_bush", "mountain_bush", "idle")
