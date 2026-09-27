require "prefabutil"

local assets =
{
	Asset("ANIM", "anim/ms_butterfly.zip"),
}

local prefabs =
{
	"butterflywings",
	"butter",
	"mountain_plants_flower",
}

local brain = require "brains/mountain_butterflybrain"

local function OnDropped(inst)
	inst.sg:GoToState("idle")
	if inst.mountainbutterflyspawner ~= nil then
		inst.mountainbutterflyspawner:StartTracking(inst)
	end
	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(1)
	end
	if inst.components.stackable ~= nil then
		while inst.components.stackable:StackSize() > 1 do
			local item = inst.components.stackable:Get()
			if item ~= nil then
				if item.components.inventoryitem ~= nil then
					item.components.inventoryitem:OnDropped()
				end
				item.Physics:Teleport(inst.Transform:GetWorldPosition())
			end
		end
	end
end

local function OnPickedUp(inst)
	if inst.mountainbutterflyspawner ~= nil then
		inst.mountainbutterflyspawner:StopTracking(inst)
	end
end

local function OnWorked(inst, worker)
	if worker.components.inventory ~= nil then
		if inst.mountainbutterflyspawner ~= nil then
			inst.mountainbutterflyspawner:StopTracking(inst)
		end
		worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
		worker.SoundEmitter:PlaySound("dontstarve/common/butterfly_trap")
	end
end

local function OnDeploy(inst, pt, deployer)
	local flower = SpawnPrefab("mountain_plants_flower")
	if flower then
		flower.Transform:SetPosition(pt:Get())
		inst.components.stackable:Get():Remove()
		if deployer ~= nil and deployer.SoundEmitter ~= nil then
			deployer.SoundEmitter:PlaySound("dontstarve/common/plant")
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddDynamicShadow()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeTinyFlyingCharacterPhysics(inst, 1, .5)

	inst:AddTag("butterfly")
	inst:AddTag("mountain_butterfly")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")
	inst:AddTag("insect")
	inst:AddTag("smallcreature")
	inst:AddTag("cattoyairborne")
	inst:AddTag("wildfireprotected")
	inst:AddTag("deployedplant")
	inst:AddTag("noember")
	inst:AddTag("pollinator")

	inst.Transform:SetTwoFaced()

	inst.AnimState:SetBuild("ms_butterfly")
	inst.AnimState:SetBank("ms_butterfly")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetRayTestOnBB(true)

	inst.DynamicShadow:SetSize(.8, .5)

	MakeInventoryFloatable(inst)

	MakeFeedableSmallLivestockPristine(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor")
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor:SetTriggersCreep(false)

	inst:SetStateGraph("SGbutterfly")
	inst.sg.mem.burn_on_electrocute = true

	inst:AddComponent("stackable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.canbepickedup = false
	inst.components.inventoryitem.canbepickedupalive = true
	inst.components.inventoryitem.nobounce = true
	inst.components.inventoryitem.pushlandedevents = false
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "ms_butterfly"

	inst:AddComponent("pollinator")

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1)

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "butterfly_body"

	inst:AddComponent("knownlocations")

	MakeSmallBurnableCharacter(inst, "butterfly_body")
	MakeTinyFreezableCharacter(inst, "butterfly_body")
	inst.components.burnable:SetBurnTime(6 * TUNING.PLANTMOB_BURNTIME_MULT)
	inst.components.health.fire_damage_scale = TUNING.PLANTMOB_FIRE_DAMAGE_SCALE

	inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:AddRandomLoot("butter", 0.06)
	inst.components.lootdropper:AddRandomLoot("butterflywings", 0.94)
	inst.components.lootdropper.numrandomloot = 1

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.NET)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(OnWorked)

	inst:AddComponent("tradable")

	inst:AddComponent("deployable")
	inst.components.deployable.ondeploy = OnDeploy
	inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
	inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)

	MakeHauntablePanicAndIgnite(inst)

	inst:SetBrain(brain)

	inst.mountainbutterflyspawner = TheWorld.components.mountainbutterflyspawner
	if inst.mountainbutterflyspawner ~= nil then
		inst.components.inventoryitem:SetOnPutInInventoryFn(inst.mountainbutterflyspawner.StopTrackingFn)
		inst:ListenForEvent("onremove", inst.mountainbutterflyspawner.StopTrackingFn)
		inst.mountainbutterflyspawner:StartTracking(inst)
	end

	MakeFeedableSmallLivestock(inst, TUNING.BUTTERFLY_PERISH_TIME, OnPickedUp, OnDropped)

	return inst
end

return Prefab("mountain_butterfly", fn, assets, prefabs),
	MakePlacer("mountain_butterfly_placer", "mountain_plants", "mountain_plants", "flower_1")
