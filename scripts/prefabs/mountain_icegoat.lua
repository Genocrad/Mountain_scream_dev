local GoatCommon = require("mountain_goat_common")

local assets =
{
	Asset("ANIM", "anim/mountain_goat.zip"),
	Asset("ANIM", "anim/mountain_goat_actions.zip"),
	Asset("ANIM", "anim/mountain_icegoat_build.zip"),
	Asset("SOUND", "sound/lightninggoat.fsb"),
}

local prefabs =
{
	"meat",
	"mountain_icecream",
	"mountain_goat",
	"mountain_goatherd",
	"splash_snow_fx",
}

local brain = require("brains/mountain_goatbrain")

SetSharedLootTable("mountain_icegoat",
{
	{ "meat", 1.00 },
	{ "meat", 1.00 },
	{ "mountain_icecream", 1.00 },
})

local THAW_TIMER = "thaw"

local RETARGET_MUST_TAGS = { "_combat" }
-- mountain_goat / mountain_icegoat 都带 mountain_goat 标签，一并排除
local RETARGET_CANT_TAGS = { "mountain_goat", "INLIMBO" }

local function RetargetFn(inst)
	return FindEntity(
		inst,
		TUNING.MOUNTAIN_ICEGOAT.TARGET_DIST,
		function(guy)
			return inst.components.combat:CanTarget(guy)
		end,
		RETARGET_MUST_TAGS,
		RETARGET_CANT_TAGS
	)
end

local function IsIceGoatHelper(dude)
	return dude:HasTag("mountain_icegoat")
		and not (dude.components.health ~= nil and dude.components.health:IsDead())
end

local function BecomeGoat(inst)
	return GoatCommon.Transform(inst, "mountain_goat")
end

local function StopThawTimer(inst)
	if inst.components.timer ~= nil and inst.components.timer:TimerExists(THAW_TIMER) then
		inst.components.timer:StopTimer(THAW_TIMER)
	end
end

local function StartThawTimer(inst, time)
	if inst.components.timer == nil then
		return
	end
	StopThawTimer(inst)
	inst.components.timer:StartTimer(THAW_TIMER, time or TUNING.MOUNTAIN_ICEGOAT.THAW_TIME)
end

local function SetSeasonal(inst, seasonal)
	inst._seasonal_ice = seasonal and true or nil
	if seasonal then
		StopThawTimer(inst)
	end
end

local function OnIsWinter(inst, iswinter)
	if iswinter then
		SetSeasonal(inst, true)
	else
		BecomeGoat(inst)
	end
end

local function OnTimerDone(inst, data)
	if data ~= nil and data.name == THAW_TIMER then
		if not TheWorld.state.iswinter then
			BecomeGoat(inst)
		else
			SetSeasonal(inst, true)
		end
	end
end

local function OnTransformed(inst, opts)
	opts = opts or {}
	if opts.seasonal or TheWorld.state.iswinter then
		SetSeasonal(inst, true)
	else
		SetSeasonal(inst, false)
		StartThawTimer(inst, opts.thaw_time)
	end
end

local function OnAttacked(inst, data)
	if data ~= nil and data.attacker ~= nil then
		inst.components.combat:SetTarget(data.attacker)
		inst.components.combat:ShareTarget(
			data.attacker,
			TUNING.MOUNTAIN_ICEGOAT.SHARE_TARGET_DIST,
			IsIceGoatHelper,
			TUNING.MOUNTAIN_ICEGOAT.MAX_TARGET_SHARES
		)
	end
end

local function OnAttackOther(inst, data)
	if data ~= nil and data.target ~= nil then
		inst.components.combat:ShareTarget(
			data.target,
			TUNING.MOUNTAIN_ICEGOAT.SHARE_TARGET_DIST,
			IsIceGoatHelper,
			TUNING.MOUNTAIN_ICEGOAT.MAX_TARGET_SHARES
		)
	end
end

local function OnHitOther(inst, data)
	local target = data ~= nil and data.target or nil
	GoatCommon.KnockbackPlayer(inst, target)
	-- 延后一帧，避免同帧 knockback 顶掉 frozen
	if target ~= nil and target:IsValid() then
		target:DoTaskInTime(0, function(t)
			GoatCommon.TryFreezeOnHit(t)
		end)
	end
end

local function OnSave(inst, data)
	if inst._seasonal_ice then
		data.seasonal_ice = true
	end
end

local function OnLoad(inst, data)
	if (data ~= nil and data.seasonal_ice) or TheWorld.state.iswinter then
		SetSeasonal(inst, true)
	elseif not TheWorld.state.iswinter then
		-- timer 组件会自己恢复 thaw；若没有则补上 3 天倒计时
		if not inst.components.timer:TimerExists(THAW_TIMER) then
			StartThawTimer(inst)
		end
	end
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
	inst.AnimState:SetBuild("mountain_icegoat")
	inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:Hide("fx")

	inst:AddTag("mountain_goat")
	inst:AddTag("mountain_icegoat")
	inst:AddTag("animal")

	--herdmember (from herdmember component) added to pristine state for optimization
	inst:AddTag("herdmember")

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
	inst.components.combat:SetRetargetFunction(1, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(GoatCommon.KeepTargetFn)
	inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/lightninggoat/hurt")

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetResistance(4)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_icegoat")

	inst:AddComponent("inspectable")

	inst:AddComponent("knownlocations")
	inst:AddComponent("herdmember")
	inst.components.herdmember:SetHerdPrefab("mountain_goatherd")
	inst:AddComponent("timer")

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)
	inst:ListenForEvent("onhitother", OnHitOther)
	inst:ListenForEvent("timerdone", OnTimerDone)

	-- 免疫冰冻：不添加 freezable
	MakeMediumBurnableCharacter(inst, "lightning_goat_body")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.MOUNTAIN_GOAT.WALK_SPEED
	inst.components.locomotor.runspeed = TUNING.MOUNTAIN_GOAT.RUN_SPEED

	MakeHauntablePanic(inst)

	inst:SetStateGraph("SGmountain_goat")
	inst:SetBrain(brain)

	inst.OnTransformed = OnTransformed
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	inst:WatchWorldState("iswinter", OnIsWinter)

	if TheWorld.state.iswinter then
		SetSeasonal(inst, true)
	else
		-- 直接生成的冰羊：非冬天按临时形态，3 天后变回
		inst:DoTaskInTime(0, function(inst)
			if inst:IsValid() and not inst._seasonal_ice and not TheWorld.state.iswinter then
				if not inst.components.timer:TimerExists(THAW_TIMER) then
					StartThawTimer(inst)
				end
			end
		end)
	end

	return inst
end

return Prefab("mountain_icegoat", fn, assets, prefabs)
