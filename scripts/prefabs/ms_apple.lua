require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/ms_apple.zip"),
}

local prefabs_apple =
{
	"ms_apple_cooked",
	"spoiled_food",
}

local prefabs_big =
{
	"ms_apple_core",
	"spoiled_food",
}

local prefabs_core =
{
	"ms_apple_tree",
}

local function MakeFood(def)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank("ms_apple")
		inst.AnimState:SetBuild("ms_apple")
		inst.AnimState:PlayAnimation(def.anim)

		inst:AddTag("food")
		if def.cookable then
			inst:AddTag("cookable")
		end

		MakeInventoryFloatable(inst)

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
		inst.components.inventoryitem.imagename = def.image

		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

		inst:AddComponent("tradable")

		inst:AddComponent("edible")
		inst.components.edible.healthvalue = def.tuning.HEALTH
		inst.components.edible.hungervalue = def.tuning.HUNGER
		inst.components.edible.sanityvalue = def.tuning.SANITY
		inst.components.edible.foodtype = FOODTYPE.VEGGIE
		if def.oneatenfn ~= nil then
			inst.components.edible:SetOnEatenFn(def.oneatenfn)
		end

		inst:AddComponent("perishable")
		inst.components.perishable:SetPerishTime(def.tuning.PERISH_TIME)
		inst.components.perishable:StartPerishing()
		inst.components.perishable.onperishreplacement = "spoiled_food"

		if def.cookable then
			inst:AddComponent("cookable")
			inst.components.cookable.product = def.cookable
		end

		MakeHauntableLaunchAndPerish(inst)

		return inst
	end

	return Prefab(def.name, fn, assets, def.prefabs)
end

local function OnEatenBigApple(inst, eater)
	local core = SpawnPrefab("ms_apple_core")
	if core == nil then
		return
	end
	if eater ~= nil and eater.components.inventory ~= nil then
		eater.components.inventory:GiveItem(core)
	else
		core.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
end

--------------------------------------------------------------------------
-- apple core (plantable)

local function ondeploy_core(inst, pt, deployer)
	local tree = SpawnPrefab("ms_apple_tree")
	if tree ~= nil then
		tree.Transform:SetPosition(pt:Get())
		if tree.components.growable ~= nil then
			tree.components.growable:SetStage(1)
			tree.components.growable:StartGrowing()
		end
		inst.components.stackable:Get():Remove()
		if deployer ~= nil and deployer.SoundEmitter ~= nil then
			deployer.SoundEmitter:PlaySound("dontstarve/wilson/plant_tree")
		end
	end
end

local function core_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("ms_apple")
	inst.AnimState:SetBuild("ms_apple")
	inst.AnimState:PlayAnimation("idle_core")

	inst:AddTag("deployedplant")
	inst:AddTag("cattoy")

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "ms_apple_core"

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")

	inst:AddComponent("fuel")
	inst.components.fuel.fuelvalue = TUNING.TINY_FUEL

	MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
	MakeSmallPropagator(inst)

	MakeHauntableLaunchAndIgnite(inst)

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = ondeploy_core
	inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
	inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.MEDIUM)

	return inst
end

return MakeFood({
		name = "ms_apple",
		anim = "idle",
		image = "ms_apple",
		tuning = TUNING.MS_APPLE,
		cookable = "ms_apple_cooked",
		prefabs = prefabs_apple,
	}),
	MakeFood({
		name = "ms_apple_cooked",
		anim = "idle_cooked",
		image = "ms_apple_cooked",
		tuning = TUNING.MS_APPLE_COOKED,
	}),
	MakeFood({
		name = "ms_big_apple",
		anim = "idle_big",
		image = "ms_big_apple",
		tuning = TUNING.MS_BIG_APPLE,
		oneatenfn = OnEatenBigApple,
		prefabs = prefabs_big,
	}),
	Prefab("ms_apple_core", core_fn, assets, prefabs_core),
	MakePlacer("ms_apple_core_placer", "ms_apple_tree", "ms_apple_tree", "idle_seed")
