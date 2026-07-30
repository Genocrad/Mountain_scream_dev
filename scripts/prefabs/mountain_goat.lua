local GoatCommon = require("mountain_goat_common")

local assets =
{
	Asset("ANIM", "anim/mountain_goat.zip"),
	Asset("ANIM", "anim/mountain_goat_actions.zip"),
	Asset("ANIM", "anim/mountain_goat_build.zip"),
	Asset("SOUND", "sound/lightninggoat.fsb"),
}

local prefabs =
{
	"meat",
	"mountain_icegoat",
	"splash_snow_fx",
}

local brain = require("brains/mountain_goatbrain")

SetSharedLootTable("mountain_goat",
{
	{ "meat", 1.00 },
	{ "meat", 1.00 },
	{ "mountain_goapaca_horn", 0.40 },
})

local function BecomeIceGoat(inst, opts)
	return GoatCommon.Transform(inst, "mountain_icegoat", opts)
end

local function OnIsWinter(inst, iswinter)
	if iswinter then
		BecomeIceGoat(inst, { seasonal = true })
	end
end

local function OnFreezeAttack(inst, coldness, freezetime, nofreeze)
	-- 仅拦截真正的冰冻输入；负数冷气来自着火 propagator 解冻，不能变冰羊
	if coldness == nil or coldness <= 0 then
		return false
	end
	BecomeIceGoat(inst, {
		seasonal = TheWorld.state.iswinter,
		thaw_time = TheWorld.state.iswinter and nil or TUNING.MOUNTAIN_ICEGOAT.THAW_TIME,
	})
	return true
end

local function OnAttacked(inst, data)
	if data ~= nil and data.attacker ~= nil then
		inst.components.combat:SetTarget(data.attacker)
		inst.components.combat:ShareTarget(data.attacker, 20, function(dude)
			return dude:HasTag("mountain_goat")
				and not dude:HasTag("mountain_icegoat")
				and not dude.components.health:IsDead()
		end, 3)
	end
end

local function OnHitOther(inst, data)
	GoatCommon.KnockbackPlayer(inst, data ~= nil and data.target or nil)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(1.75, .75)

	inst.Transform:SetFourFaced()

	MakeCharacterPhysics(inst, 100, .5)

	inst.AnimState:SetBank("mountain_goat")
	inst.AnimState:SetBuild("mountain_goat")
	inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:Hide("fx")

	inst:AddTag("mountain_goat")
	inst:AddTag("animal")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.MOUNTAIN_GOAT.HEALTH)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_GOAT.DAMAGE)
	inst.components.combat:SetRange(TUNING.MOUNTAIN_GOAT.ATTACK_RANGE)
	inst.components.combat.hiteffectsymbol = "lightning_goat_body"
	inst.components.combat:SetAttackPeriod(TUNING.MOUNTAIN_GOAT.ATTACK_PERIOD)
	inst.components.combat:SetKeepTargetFunction(GoatCommon.KeepTargetFn)
	inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/lightninggoat/hurt")

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetResistance(4)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_goat")

	inst:AddComponent("inspectable")

	inst:AddComponent("knownlocations")

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onhitother", OnHitOther)

	MakeMediumBurnableCharacter(inst, "lightning_goat_body")
	MakeMediumFreezableCharacter(inst, "lightning_goat_body")
	inst.components.freezable:SetRedirectFn(OnFreezeAttack)

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.MOUNTAIN_GOAT.WALK_SPEED
	inst.components.locomotor.runspeed = TUNING.MOUNTAIN_GOAT.RUN_SPEED

	MakeHauntablePanic(inst)

	inst:SetStateGraph("SGmountain_goat")
	inst:SetBrain(brain)

	inst:WatchWorldState("iswinter", OnIsWinter)
	if TheWorld.state.iswinter then
		inst:DoTaskInTime(0, function(inst)
			if inst:IsValid() and TheWorld.state.iswinter then
				BecomeIceGoat(inst, { seasonal = true })
			end
		end)
	end

	return inst
end

return Prefab("mountain_goat", fn, assets, prefabs)
