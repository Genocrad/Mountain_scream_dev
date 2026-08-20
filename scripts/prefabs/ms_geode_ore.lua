-- Luigi: yes, this is basically a copy of suspicious ore.

local assets =
{
	Asset("ANIM", "anim/ms_ore.zip"),
}

local prefabs =
{
	"rocks",
  "ms_alu_ore",
  "ms_copper_ore",
  "ms_alu_ore",
  "redgem",
  "bluegem",
  "purplegem",
  "greengem",
  "yellowgem",
  "orangegem"
}

local function GetBonusLoot()
	if LOOT_WEIGHTS == nil then
		LOOT_WEIGHTS = BuildLootWeights()
	end
	return 
end

local function DropOpenedLoot(inst, worker)
	local pt = inst:GetPosition()
	SpawnPrefab("rock_break_fx").Transform:SetPosition(pt:Get())
  for _ = 1, 3 do 
    local rocks = SpawnPrefab("rocks")
    LaunchAt(rocks, inst, worker, 0.5, 1, nil, 0)
  end
  for _ = 1, 2 do
    local bonus = weighted_random_choice(TUNING.MS_GEODE_ORE.LOOTS)
    if bonus ~= nil then
      local loot = SpawnPrefab(bonus)
      LaunchAt(loot, inst, worker, 0.5, 1, nil, 0)
    end
  end
end

------------------------------------------------------------------------------------------------------------------------

local function OnWork(inst, worker, workleft, workdone)
	local work_per = TUNING.MS_GEODE_ORE.WORK_LEFT
	local num_opened = math.clamp(math.ceil(workdone / work_per), 1, inst.components.stackable:StackSize())

	for _ = 1, num_opened do
		DropOpenedLoot(inst, worker)
	end

	local top = inst.components.stackable:Get(num_opened)
	top:Remove()
end

local function OnStackSizeChanged(inst, data)
	if data ~= nil and data.stacksize ~= nil and inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(data.stacksize * TUNING.MS_GEODE_ORE.WORK_LEFT)
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

	inst.AnimState:SetBank("ms_ore")
	inst.AnimState:SetBuild("ms_ore")
	inst.AnimState:PlayAnimation("ms_geode_ore")

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
	inst.components.workable:SetWorkLeft(TUNING.MS_GEODE_ORE.WORK_LEFT * inst.components.stackable.stacksize)
	inst.components.workable:SetOnWorkCallback(OnWork)

	inst:ListenForEvent("stacksizechange", OnStackSizeChanged)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("ms_geode_ore", fn, assets, prefabs)
