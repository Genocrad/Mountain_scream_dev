require "prefabutil"

local RACK_BUILD = "ms_meat_rack_foods"

local assets =
{
	Asset("ANIM", "anim/ms_apple.zip"),
	Asset("ANIM", "anim/ms_meat_rack_foods.zip"),
}

local prefabs_apple =
{
	"ms_apple_cooked",
	"ms_apple_dried",
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

local prefabs_golden =
{
	"buff_ms_golden_apple",
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
		if def.dryable then
			inst:AddTag("dryable")
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
		inst.components.edible.foodtype = def.foodtype or FOODTYPE.VEGGIE
		if def.oneatenfn ~= nil then
			inst.components.edible:SetOnEatenFn(def.oneatenfn)
		end

		if def.tuning.PERISH_TIME ~= nil then
			inst:AddComponent("perishable")
			inst.components.perishable:SetPerishTime(def.tuning.PERISH_TIME)
			inst.components.perishable:StartPerishing()
			inst.components.perishable.onperishreplacement = "spoiled_food"
		end

		if def.cookable then
			inst:AddComponent("cookable")
			inst.components.cookable.product = def.cookable
		end

		if def.dryable then
			inst:AddComponent("dryable")
			inst.components.dryable:SetProduct(def.dryable.product)
			inst.components.dryable:SetDryTime(def.dryable.time)
			inst.components.dryable:SetBuildFile(def.dryable.build)
			inst.components.dryable:SetDriedBuildFile(def.dryable.dried_build)
		end

		if def.tuning.PERISH_TIME ~= nil then
			MakeHauntableLaunchAndPerish(inst)
		else
			MakeHauntableLaunch(inst)
		end

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

local function dried_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("ms_apple")
	inst.AnimState:SetBuild("ms_apple")
	inst.AnimState:PlayAnimation("idle_dried")

	inst:AddTag("food")

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "ms_apple_dried"

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")

	inst:AddComponent("edible")
	inst.components.edible.healthvalue = TUNING.MS_APPLE_DRIED.HEALTH
	inst.components.edible.hungervalue = TUNING.MS_APPLE_DRIED.HUNGER
	inst.components.edible.sanityvalue = TUNING.MS_APPLE_DRIED.SANITY
	inst.components.edible.foodtype = FOODTYPE.VEGGIE

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.MS_APPLE_DRIED.PERISH_TIME)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	MakeHauntableLaunchAndPerish(inst)

	return inst
end

--------------------------------------------------------------------------
-- golden apple buff: 1 HP/s and 80% damage absorption for 1 minute

local function GoldenApple_HealTick(inst, target)
	if target == nil or not target:IsValid() or target.components.health == nil or target.components.health:IsDead() then
		inst.components.debuff:Stop()
		return
	end
	target.components.health:DoDelta(TUNING.MS_GOLDEN_APPLE.REGEN_PER_SECOND, true, "ms_golden_apple")
end

local function GoldenAppleBuff_OnAttached(inst, target)
	inst.entity:SetParent(target.entity)
	inst.Transform:SetPosition(0, 0, 0)
	inst:ListenForEvent("death", function()
		inst.components.debuff:Stop()
	end, target)
	if target.components.health ~= nil then
		target.components.health.externalabsorbmodifiers:SetModifier(inst, TUNING.MS_GOLDEN_APPLE.ABSORPTION, "ms_golden_apple")
	end
	inst.healtask = inst:DoPeriodicTask(1, GoldenApple_HealTick, nil, target)
end

local function GoldenApple_Say(target, strid)
	if target ~= nil and target:IsValid() and target.components.talker ~= nil then
		target.components.talker:Say(GetString(target, strid))
	end
end

local function GoldenAppleBuff_OnDetached(inst, target)
	if inst.healtask ~= nil then
		inst.healtask:Cancel()
		inst.healtask = nil
	end
	if target ~= nil and target:IsValid() then
		if target.components.health ~= nil then
			target.components.health.externalabsorbmodifiers:RemoveModifier(inst, "ms_golden_apple")
		end
		if target.components.health == nil or not target.components.health:IsDead() then
			GoldenApple_Say(target, "MS_GOLDEN_APPLE_BUFF_END")
		end
	end
	inst:Remove()
end

local function GoldenAppleBuff_OnExtended(inst, target)
	inst.components.timer:StopTimer("buffover")
	inst.components.timer:StartTimer("buffover", TUNING.MS_GOLDEN_APPLE.BUFF_DURATION)
	if inst.healtask ~= nil then
		inst.healtask:Cancel()
	end
	if target ~= nil then
		inst.healtask = inst:DoPeriodicTask(1, GoldenApple_HealTick, nil, target)
	end
end

local function GoldenAppleBuff_OnTimerDone(inst, data)
	if data.name == "buffover" then
		inst.components.debuff:Stop()
	end
end

local function golden_apple_buff_fn()
	local inst = CreateEntity()

	if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, inst.Remove)
		return inst
	end

	inst.entity:AddTransform()
	inst.entity:Hide()
	inst.persists = false

	inst:AddTag("CLASSIFIED")

	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(GoldenAppleBuff_OnAttached)
	inst.components.debuff:SetDetachedFn(GoldenAppleBuff_OnDetached)
	inst.components.debuff:SetExtendedFn(GoldenAppleBuff_OnExtended)
	inst.components.debuff.keepondespawn = true

	inst:AddComponent("timer")
	inst.components.timer:StartTimer("buffover", TUNING.MS_GOLDEN_APPLE.BUFF_DURATION)
	inst:ListenForEvent("timerdone", GoldenAppleBuff_OnTimerDone)

	return inst
end

local function OnEatenGoldenApple(inst, eater)
	if eater ~= nil and eater.components.debuffable ~= nil and eater:HasTag("player") then
		eater:AddDebuff("buff_ms_golden_apple", "buff_ms_golden_apple")
		GoldenApple_Say(eater, "MS_GOLDEN_APPLE_BUFF_START")
	end
end

return MakeFood({
		name = "ms_apple",
		anim = "idle",
		image = "ms_apple",
		tuning = TUNING.MS_APPLE,
		cookable = "ms_apple_cooked",
		dryable = {
			product = "ms_apple_dried",
			time = TUNING.DRY_FAST,
			build = RACK_BUILD,
			dried_build = RACK_BUILD,
		},
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
	MakeFood({
		name = "ms_golden_apple",
		anim = "idle_golden",
		image = "ms_golden_apple",
		tuning = TUNING.MS_GOLDEN_APPLE,
		foodtype = FOODTYPE.GOODIES,
		oneatenfn = OnEatenGoldenApple,
		prefabs = prefabs_golden,
	}),
	Prefab("buff_ms_golden_apple", golden_apple_buff_fn),
	Prefab("ms_apple_dried", dried_fn, assets),
	Prefab("ms_apple_core", core_fn, assets, prefabs_core),
	MakePlacer("ms_apple_core_placer", "ms_apple_tree", "ms_apple_tree", "idle_seed")
