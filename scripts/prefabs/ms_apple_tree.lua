local assets =
{
	Asset("ANIM", "anim/ms_apple_tree.zip"),
}

local prefabs =
{
	"log",
	"twigs",
	"charcoal",
	"ms_apple",
	"ms_big_apple",
}

local short_anims =
{
	idle = "idle_short",
	sway1 = "sway1_loop_short",
	sway2 = "sway2_loop_short",
	chop = "chop_short",
	fallleft = "fallleft_short",
	fallright = "fallright_short",
	stump = "idle_stump",
	burnt = "burnt_short",
	chop_burnt = "chop_burnt_short",
}

local fruit_anims =
{
	idle = "idle_short_fruit",
	sway1 = "sway1_loop_short_fruit",
	sway2 = "sway2_loop_short_fruit",
	chop = "chop_short_fruit",
	fallleft = "fallleft_short_fruit",
	fallright = "fallright_short_fruit",
	stump = "idle_stump",
	burnt = "burnt_short",
	chop_burnt = "chop_burnt_short",
}

local chop_tree, chop_down_tree, tree_burnt

local function RandomizeAnimFrame(inst)
	local n = inst.AnimState:GetCurrentAnimationNumFrames()
	if n > 1 then
		inst.AnimState:SetFrame(math.random(n) - 1)
	end
end

local function PushSway(inst)
	if inst.anims ~= nil and inst.anims.sway1 ~= nil then
		inst.AnimState:PushAnimation(math.random() > .5 and inst.anims.sway1 or inst.anims.sway2, true)
	end
end

local function Sway(inst)
	if inst.anims ~= nil and inst.anims.sway1 ~= nil then
		inst.AnimState:PlayAnimation(math.random() > .5 and inst.anims.sway1 or inst.anims.sway2, true)
	elseif inst.anims ~= nil and inst.anims.idle ~= nil then
		inst.AnimState:PlayAnimation(inst.anims.idle, true)
	end
	RandomizeAnimFrame(inst)
end

local function inspect_tree(inst)
	return (inst:HasTag("burnt") and "BURNT")
		or (inst:HasTag("stump") and "CHOPPED")
		or nil
end

local function MakeLogLoot()
	local loot = {}
	for _ = 1, TUNING.MS_APPLE_TREE.LOGS do
		table.insert(loot, "log")
	end
	return loot
end

local function PickApplePrefab()
	return math.random() < TUNING.MS_APPLE_TREE.BIG_APPLE_CHANCE and "ms_big_apple" or "ms_apple"
end

local function DropApples(inst, pt)
	pt = pt or inst:GetPosition()
	if inst.components.lootdropper == nil then
		return
	end
	for _ = 1, TUNING.MS_APPLE_TREE.APPLES do
		inst.components.lootdropper:SpawnLootPrefab(PickApplePrefab(), pt)
	end
end

local function dig_up_seed(inst)
	inst.components.lootdropper:SpawnLootPrefab("twigs")
	inst:Remove()
end

local function dig_up_stump(inst)
	for _ = 1, TUNING.MS_APPLE_TREE.STUMP_LOOT do
		inst.components.lootdropper:SpawnLootPrefab("log")
	end
	inst:Remove()
end

local function PlayChopSound(inst, chopper)
	if not (chopper ~= nil and chopper:HasTag("playerghost")) then
		inst.SoundEmitter:PlaySound(
			chopper ~= nil and chopper:HasTag("beaver") and
			"dontstarve/characters/woodie/beaver_chop_tree" or
			"dontstarve/wilson/use_axe_tree"
		)
	end
end

local function chop_down_burnt_tree(inst, chopper)
	inst:RemoveComponent("workable")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")
	PlayChopSound(inst, chopper)
	inst.AnimState:PlayAnimation(inst.anims.chop_burnt)
	RemovePhysicsColliders(inst)
	inst:ListenForEvent("animover", inst.Remove)
	inst.components.lootdropper:SpawnLootPrefab("charcoal")
end

local function SetupSeedWorkable(inst)
	if inst.components.workable == nil then
		inst:AddComponent("workable")
	end
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnWorkCallback(nil)
	inst.components.workable:SetOnFinishCallback(dig_up_seed)
end

local function SetupChopWorkable(inst)
	if inst.components.workable == nil then
		inst:AddComponent("workable")
	end
	inst.components.workable:SetWorkAction(ACTIONS.CHOP)
	inst.components.workable:SetWorkLeft(TUNING.MS_APPLE_TREE.CHOPS)
	inst.components.workable:SetOnWorkCallback(chop_tree)
	inst.components.workable:SetOnFinishCallback(chop_down_tree)
end

-- ms_apple_harvestable：能否掉果
-- mountain_throw_target：与灌木相同的投掷标记（结果期），便于左键收集
local function DisableHarvest(inst)
	inst:RemoveTag("ms_apple_harvestable")
	inst:RemoveTag("mountain_throw_target")
end

local function EnableHarvest(inst)
	inst:AddTag("ms_apple_harvestable")
	inst:AddTag("mountain_throw_target")
end

local function MakeSeedBurnable(inst)
	if inst.components.burnable ~= nil then
		inst:RemoveComponent("burnable")
	end
	if inst.components.propagator ~= nil then
		inst:RemoveComponent("propagator")
	end
	MakeSmallBurnable(inst)
	MakeSmallPropagator(inst)
end

local function MakeTreeBurnable(inst)
	if inst.components.burnable ~= nil then
		inst:RemoveComponent("burnable")
	end
	if inst.components.propagator ~= nil then
		inst:RemoveComponent("propagator")
	end
	MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
	inst.components.burnable:SetFXLevel(5)
	inst.components.burnable:SetOnBurntFn(tree_burnt)
	MakeMediumPropagator(inst)
end

local function SetSeed(inst)
	inst.anims = { idle = "idle_seed" }
	inst:RemoveTag("shelter")

	DisableHarvest(inst)

	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:SetLoot({})
	end

	RemovePhysicsColliders(inst)
	SetupSeedWorkable(inst)
	MakeSeedBurnable(inst)

	inst.AnimState:PlayAnimation("idle_seed", true)
	RandomizeAnimFrame(inst)
end

local function GrowToSeed(inst)
	inst.AnimState:PlayAnimation("grow_short_fruit_to_seed")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeWilt")
	inst.AnimState:PushAnimation("idle_seed", true)
end

local function SetShort(inst)
	inst.anims = short_anims
	inst:AddTag("shelter")

	DisableHarvest(inst)

	MakeObstaclePhysics(inst, .25)
	SetupChopWorkable(inst)
	MakeTreeBurnable(inst)

	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:SetLoot(MakeLogLoot())
	end

	Sway(inst)
end

local function GrowToShort(inst)
	inst.AnimState:PlayAnimation("grow_seed_to_short")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeGrow")
	PushSway(inst)
end

local function SetFruit(inst)
	inst.anims = fruit_anims
	inst:AddTag("shelter")

	MakeObstaclePhysics(inst, .25)
	SetupChopWorkable(inst)
	MakeTreeBurnable(inst)
	EnableHarvest(inst)

	if inst.components.lootdropper ~= nil then
		inst.components.lootdropper:SetLoot(MakeLogLoot())
	end

	-- 结果期不自动退回 sapling；旧档残留计时也一并清掉
	if inst.components.growable ~= nil then
		inst.components.growable:StopGrowing()
	end

	Sway(inst)
end

local function GrowToFruit(inst)
end

local function grow_times(t)
	return function()
		return GetRandomWithVariance(t.base, t.random)
	end
end

local growth_stages =
{
	{
		name = "seed",
		time = grow_times(TUNING.MS_APPLE_TREE.SEED_TO_SHORT),
		fn = SetSeed,
		growfn = GrowToSeed,
	},
	{
		name = "short",
		time = grow_times(TUNING.MS_APPLE_TREE.SHORT_TO_FRUIT),
		fn = SetShort,
		growfn = GrowToShort,
	},
	{
		name = "short_fruit",
		-- 必须返回 nil：字段缺失会走 FALLBACK_GROWTH_TIME（10s）
		time = function() return nil end,
		fn = SetFruit,
		growfn = GrowToFruit,
	},
}

local function make_stump(inst)
	inst:RemoveTag("shelter")
	inst:AddTag("stump")

	if inst.components.growable ~= nil then
		inst.components.growable:StopGrowing()
		inst:RemoveComponent("growable")
	end

	DisableHarvest(inst)

	RemovePhysicsColliders(inst)

	if inst.components.burnable ~= nil then
		inst:RemoveComponent("burnable")
	end
	if inst.components.propagator ~= nil then
		inst:RemoveComponent("propagator")
	end
	MakeSmallBurnable(inst)
	MakeSmallPropagator(inst)

	if inst.components.workable ~= nil then
		inst:RemoveComponent("workable")
	end
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetOnFinishCallback(dig_up_stump)
	inst.components.workable:SetWorkLeft(1)

	inst.MiniMapEntity:SetIcon("ms_apple_tree.tex")
end

chop_tree = function(inst, chopper)
	PlayChopSound(inst, chopper)
	inst.AnimState:PlayAnimation(inst.anims.chop)
	inst.AnimState:PushAnimation(inst.anims.sway1, true)
end

chop_down_tree = function(inst, chopper)
	inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
	local pt = inst:GetPosition()

	local he_right = true
	if chopper then
		local hispos = chopper:GetPosition()
		he_right = (hispos - pt):Dot(TheCamera:GetRightVec()) > 0
	else
		he_right = math.random() > 0.5
	end

	if he_right then
		inst.AnimState:PlayAnimation(inst.anims.fallleft)
		inst.components.lootdropper:DropLoot(pt - TheCamera:GetRightVec())
	else
		inst.AnimState:PlayAnimation(inst.anims.fallright)
		inst.components.lootdropper:DropLoot(pt + TheCamera:GetRightVec())
	end

	local was_fruiting = inst:HasTag("ms_apple_harvestable")
	if was_fruiting then
		DropApples(inst, he_right and (pt - TheCamera:GetRightVec()) or (pt + TheCamera:GetRightVec()))
	end

	make_stump(inst)
	inst.AnimState:PushAnimation(inst.anims.stump, false)
end

local function OnBurnt(inst, immediate)
	local function changes()
		if inst.components.burnable ~= nil then
			inst.components.burnable:Extinguish()
		end
		inst:RemoveComponent("burnable")
		inst:RemoveComponent("propagator")

		if inst.components.growable ~= nil then
			inst.components.growable:StopGrowing()
			inst:RemoveComponent("growable")
		end

		DisableHarvest(inst)

		inst:RemoveTag("shelter")
		MakeHauntableWork(inst)

		inst.components.lootdropper:SetLoot({})

		if inst.components.workable ~= nil then
			inst.components.workable:SetWorkLeft(1)
			inst.components.workable:SetOnWorkCallback(nil)
			inst.components.workable:SetOnFinishCallback(chop_down_burnt_tree)
		end
	end

	if immediate then
		changes()
	else
		inst:DoTaskInTime(.5, changes)
	end

	inst.anims = inst.anims or short_anims
	inst.AnimState:PlayAnimation(inst.anims.burnt, true)
	inst.AnimState:SetRayTestOnBB(true)
	inst:AddTag("burnt")
end

tree_burnt = function(inst)
	OnBurnt(inst)
end

-- 铝斧命中调用：有果则掉落并回到 short 阶段；无果则 false（斧仍正常落地）
local function HarvestApples(inst, harvester)
	if not inst:HasTag("ms_apple_harvestable") then
		return false
	end

	DropApples(inst)
	DisableHarvest(inst)

	if inst.components.growable ~= nil then
		inst.components.growable:SetStage(2)
		inst.components.growable:StartGrowing()
	end

	PlayChopSound(inst, harvester)
	if inst.anims ~= nil and inst.anims.chop ~= nil then
		inst.AnimState:PlayAnimation(inst.anims.chop)
		PushSway(inst)
	end

	return true
end

local function onsave(inst, data)
	if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
		data.burnt = true
	end
	if inst:HasTag("stump") then
		data.stump = true
	end
end

local function ApplySnowTrunk(inst)
	inst.AnimState:OverrideSymbol("jungletrunk", "ms_apple_tree", "jungletrunk_snow")
end

local function onload(inst, data)
	if inst._snowy then
		ApplySnowTrunk(inst)
	end
	-- 结果期不继续生长（挡住旧档里残留的 FRUIT_TO_SEED 计时）
	if inst.components.growable ~= nil
		and inst.components.growable:GetStage() == 3
		and not inst:HasTag("stump")
		and not inst:HasTag("burnt") then
		inst.components.growable:StopGrowing()
	end
	if data == nil then
		return
	end
	if data.stump then
		inst.anims = short_anims
		make_stump(inst)
		inst.AnimState:PlayAnimation(inst.anims.stump)
	elseif data.burnt then
		inst.anims = short_anims
		OnBurnt(inst, true)
	end
end

local function MakeTree(snowy)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		MakeObstaclePhysics(inst, .25)

		inst.MiniMapEntity:SetIcon("ms_apple_tree.tex")
		inst.MiniMapEntity:SetPriority(-1)

		inst:AddTag("plant")
		inst:AddTag("tree")
		inst:AddTag("shelter")
		inst:AddTag("ms_apple_tree")

		inst.AnimState:SetBank("ms_apple_tree")
		inst.AnimState:SetBuild("ms_apple_tree")
		inst.AnimState:PlayAnimation("sway1_loop_short", true)
		if snowy then
			ApplySnowTrunk(inst)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst._snowy = snowy == true

		local color = .7 + math.random() * .3
		inst.AnimState:SetMultColour(color, color, color, 1)

		inst:AddComponent("inspectable")
		inst.components.inspectable.getstatus = inspect_tree

		inst:AddComponent("lootdropper")

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(ACTIONS.CHOP)
		inst.components.workable:SetOnWorkCallback(chop_tree)
		inst.components.workable:SetOnFinishCallback(chop_down_tree)

		MakeLargeBurnable(inst, TUNING.TREE_BURN_TIME)
		inst.components.burnable:SetFXLevel(5)
		inst.components.burnable:SetOnBurntFn(tree_burnt)
		MakeMediumPropagator(inst)

		inst:AddComponent("growable")
		inst.components.growable.stages = growth_stages
		inst.components.growable:SetStage(math.random(1, 3))
		inst.components.growable.loopstages = false
		inst.components.growable.springgrowth = true
		inst.components.growable:StartGrowing()

		MakeHauntableWork(inst)
		MakeSnowCovered(inst)
		MakeWaxablePlant(inst)

		inst.HarvestApples = HarvestApples
		inst.OnSave = onsave
		inst.OnLoad = onload

		return inst
	end

	return fn
end

return Prefab("ms_apple_tree", MakeTree(false), assets, prefabs),
	Prefab("ms_apple_tree_snow", MakeTree(true), assets, prefabs)
