local assets =
{
	Asset("ANIM", "anim/mountain_suspicious_ore.zip"),
}

local prefabs =
{
	"rocks",
	"flint",
	"ice",
	"nitre",
	"saltrock",
	"cutstone",
	"ms_geode_ore",
	"fossil_piece",
	"thulecite_pieces",
	"goldnugget",
	"marble",
	"thulecite",
	"dreadstone",
	"heatrock",
	"ancienttree_seed",
	"trinket_4",
	"rock_break_fx",
}

------------------------------------------------------------------------------------------------------------------------
-- 掉落：固定 1 rocks + 按权重抽取表中 1 项
-- 档位内物品均分该档权重
------------------------------------------------------------------------------------------------------------------------

local function BuildLootWeights()
	local weights = {}
	for _, tier in ipairs(TUNING.MOUNTAIN_SUSPICIOUS_ORE.LOOT_TIERS) do
		local n = #tier.items
		if n > 0 and tier.weight > 0 then
			local per = tier.weight / n
			for _, prefab in ipairs(tier.items) do
				weights[prefab] = (weights[prefab] or 0) + per
			end
		end
	end
	return weights
end

local LOOT_WEIGHTS = nil

local function GetBonusLoot()
	if LOOT_WEIGHTS == nil then
		LOOT_WEIGHTS = BuildLootWeights()
	end
	return weighted_random_choice(LOOT_WEIGHTS)
end

local function DropOpenedLoot(inst, worker)
	local pt = inst:GetPosition()
	SpawnPrefab("rock_break_fx").Transform:SetPosition(pt:Get())

	local rocks = SpawnPrefab("rocks")
	LaunchAt(rocks, inst, worker, 0.5, 1, nil, 0)

	local bonus = GetBonusLoot()
	if bonus ~= nil then
		local loot = SpawnPrefab(bonus)
		LaunchAt(loot, inst, worker, 0.5, 1, nil, 0)
	end
end

------------------------------------------------------------------------------------------------------------------------

local function OnWork(inst, worker, workleft, workdone)
	local work_per = TUNING.MOUNTAIN_SUSPICIOUS_ORE.WORK_LEFT
	local num_opened = math.clamp(math.ceil(workdone / work_per), 1, inst.components.stackable:StackSize())

	for _ = 1, num_opened do
		DropOpenedLoot(inst, worker)
	end

	local top = inst.components.stackable:Get(num_opened)
	top:Remove()
end

local function OnStackSizeChanged(inst, data)
	if data ~= nil and data.stacksize ~= nil and inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(data.stacksize * TUNING.MOUNTAIN_SUSPICIOUS_ORE.WORK_LEFT)
	end
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_suspicious_ore")
	inst.AnimState:SetBuild("mountain_suspicious_ore")
	inst.AnimState:PlayAnimation("idle")

	inst.pickupsound = "rock"

	inst:AddTag("molebait")

	inst.scrapbook_anim = "idle"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.scrapbook_deps = {}

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_suspicious_ore"
	inst.components.inventoryitem:SetSinks(true)

	inst:AddComponent("edible")
	inst.components.edible.foodtype = FOODTYPE.ELEMENTAL
	inst.components.edible.hungervalue = 1

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")
	inst:AddComponent("bait")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.MOUNTAIN_SUSPICIOUS_ORE.WORK_LEFT * inst.components.stackable.stacksize)
	inst.components.workable:SetOnWorkCallback(OnWork)

	inst:ListenForEvent("stacksizechange", OnStackSizeChanged)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_suspicious_ore", fn, assets, prefabs)
