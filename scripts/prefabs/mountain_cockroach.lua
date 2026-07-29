local assets =
{
	Asset("ANIM", "anim/mountain_cockroach.zip"),
}

local prefabs =
{
	"monstermeat",
}

local brain = require("brains/mountain_cockroachbrain")

SetSharedLootTable("mountain_cockroach",
{
	{ "monstermeat", 1.00 },
	{ "mountain_suspicious_ore", 1.00 },
})

local RETARGET_CANT_TAGS = { "FX", "NOCLICK", "INLIMBO", "wall", "mountain_cockroach", "structure", "aquatic" }

local function RetargetFn(inst)
	return FindEntity(inst, TUNING.MOUNTAIN_COCKROACH.TARGET_DIST, function(guy)
		return inst.components.combat:CanTarget(guy)
	end, nil, RETARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
	return target ~= nil
		and target:IsValid()
		and not target:IsInLimbo()
		and target.components.combat ~= nil
		and target.components.health ~= nil
		and not target.components.health:IsDead()
end

local function OnAttacked(inst, data)
	if data ~= nil and data.attacker ~= nil then
		inst.components.combat:SetTarget(data.attacker)
		inst.components.combat:ShareTarget(data.attacker, TUNING.MOUNTAIN_COCKROACH.SHARE_TARGET_DIST, function(dude)
			return dude:HasTag("mountain_cockroach")
				and not dude.components.health:IsDead()
		end, TUNING.MOUNTAIN_COCKROACH.MAX_TARGET_SHARES)
	end
end

local function DoReturn(inst)
	if inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome() then
		local home = inst.components.homeseeker.home
		if home ~= nil and home:IsValid() and home.components.childspawner ~= nil then
			home.components.childspawner:GoHome(inst)
		end
	end
end

local function OnEntitySleep(inst)
	-- 非傍晚时卸载区块则直接收进巢穴
	if not TheWorld.state.isdusk then
		DoReturn(inst)
	end
end

local function OnStopDusk(inst)
	if inst:IsAsleep() then
		DoReturn(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, .5)

	inst.DynamicShadow:SetSize(1.5, .5)
	inst.Transform:SetSixFaced()

	inst.AnimState:SetBank("mountain_cockroach")
	inst.AnimState:SetBuild("mountain_cockroach")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("insect")
	inst:AddTag("hostile")
	inst:AddTag("canbetrapped")
	inst:AddTag("smallcreature")
	inst:AddTag("mountain_cockroach")
	inst:AddTag("animal")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("locomotor")
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }
	inst.components.locomotor.walkspeed = TUNING.MOUNTAIN_COCKROACH.WALK_SPEED

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.MOUNTAIN_COCKROACH.HEALTH)

	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "body"
	inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_COCKROACH.DAMAGE)
	inst.components.combat:SetAttackPeriod(TUNING.MOUNTAIN_COCKROACH.ATTACK_PERIOD)
	inst.components.combat:SetRange(TUNING.MOUNTAIN_COCKROACH.ATTACK_RANGE, TUNING.MOUNTAIN_COCKROACH.HIT_RANGE)
	inst.components.combat:SetRetargetFunction(3, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

	inst:AddComponent("eater")
	-- 任何食物 + 矿物（ELEMENTAL / NITRE / GEARS 等）
	inst.components.eater:SetDiet({
		FOODGROUP.OMNI,
		FOODTYPE.ELEMENTAL,
		FOODTYPE.NITRE,
		FOODTYPE.GEARS,
		FOODTYPE.ROUGHAGE,
		FOODTYPE.WOOD,
		FOODTYPE.RAW,
		FOODTYPE.BURNT,
		FOODTYPE.HORRIBLE,
		FOODTYPE.LUNAR_SHARDS,
	})
	inst.components.eater:SetStrongStomach(true)
	inst.components.eater:SetIgnoresSpoilage(true)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_cockroach")

	inst:AddComponent("inspectable")
	inst:AddComponent("knownlocations")

	inst:ListenForEvent("attacked", OnAttacked)
	inst:WatchWorldState("stopdusk", OnStopDusk)
	inst.OnEntitySleep = OnEntitySleep

	MakeSmallBurnableCharacter(inst, "body")
	MakeSmallFreezableCharacter(inst, "body")
	MakeHauntablePanic(inst)

	inst:SetStateGraph("SGmountain_cockroach")
	inst:SetBrain(brain)

	return inst
end

return Prefab("mountain_cockroach", fn, assets, prefabs)
