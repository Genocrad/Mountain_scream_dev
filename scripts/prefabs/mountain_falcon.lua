local assets =
{
	Asset("ANIM", "anim/mountain_falcon.zip"),
	Asset("SOUND", "sound/bat.fsb"),
}

local prefabs =
{
	"mountain_monster_drumstick",
	"houndstooth",
}

local brain = require("brains/mountain_falconbrain")

SetSharedLootTable("mountain_falcon",
{
	{ "mountain_monster_drumstick", 1.000 },
	{ "mountain_monster_drumstick", 1.000 },
	{ "houndstooth", 0.125 },
})

local SHARE_TARGET_DIST = 30
local MAX_TARGET_SHARES = 5
local PURSUIT_TICK = 0.25

local RETARGET_CANT_TAGS = { "wall", "mountain_falcon_base", "mountain_falcon" }
local RETARGET_ONEOF_TAGS = { "character", "monster" }

--------------------------------------------------------------------------

local function GetMountainLevel(ent)
	if ent == nil or not ent:IsValid() then
		return nil
	end
	local overwatch = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch or nil
	if overwatch == nil then
		return nil
	end
	local x, y, z = ent.Transform:GetWorldPosition()
	return overwatch:GetNearestLevel(x, y, z)
end

local function IsMountainSurfaceLevel(level)
	return level ~= nil and level <= TUNING.MS_CAVES_START
end

local function IsOnMountainTerritory(ent)
	return IsMountainSurfaceLevel(GetMountainLevel(ent))
end

local function ClearPursuitTimers(inst)
	inst._pursuit_start = nil
	inst._pursuit_lost_since = nil
	inst._cross_floor_dest = nil
	inst._pursuit_target = nil
	inst._pursuit_target_level = nil
	inst._cross_floor_hold_start = nil
	inst._cross_floor_land_at = nil
end

local function SetPursuitCanSleep(inst, can_sleep)
	if inst._pursuit_can_sleep == can_sleep then
		return
	end
	inst._pursuit_can_sleep = can_sleep
	inst.entity:SetCanSleep(can_sleep)
end

local function IsActivelyPursuing(inst)
	if inst._returning_home or inst._deaggro_pending or inst._cross_flooring then
		return true
	end
	if inst._pursuit_target ~= nil then
		return true
	end
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if target ~= nil then
		return true
	end
	if inst._pursuit_start ~= nil or inst._pursuit_lost_since ~= nil then
		return true
	end
	return false
end

local function SyncPursuitSleep(inst)
	SetPursuitCanSleep(inst, not IsActivelyPursuing(inst))
end

local function DoReturn(inst)
	if not inst:IsValid() then
		return false
	end
	if inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome() then
		local home = inst.components.homeseeker.home
		if home ~= nil and home:IsValid() and home.components.childspawner ~= nil then
			home.components.childspawner:GoHome(inst)
			return true
		end
	end
	return false
end

local function FinishReturnHome(inst)
	if not inst:IsValid() then
		return
	end

	inst._cross_flooring = false
	ClearPursuitTimers(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:DropTarget()
	end

	-- GoHome BEFORE re-enabling sleep. Otherwise EntitySleep can race and the
	-- bird vanishes without being counted back into childreninside.
	local went_home = DoReturn(inst)
	inst._returning_home = false
	if went_home or not inst:IsValid() then
		return
	end

	SetPursuitCanSleep(inst, true)
	local x, y, z = inst.Transform:GetWorldPosition()
	inst.Physics:Stop()
	inst.Transform:SetPosition(x, 15, z)
	inst.sg:GoToState("flyback")
end

local function RequestReturnHome(inst)
	if not inst:IsValid() then
		return
	end
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return
	end
	if inst._returning_home and inst.sg ~= nil and inst.sg.currentstate ~= nil
		and inst.sg.currentstate.name == "return_home_fly" then
		return
	end

	inst._returning_home = true
	inst._deaggro_pending = nil
	inst._cross_flooring = false
	ClearPursuitTimers(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:DropTarget()
	end
	-- Stay awake until GoHome finishes.
	SetPursuitCanSleep(inst, false)

	if inst.sg ~= nil and not inst.sg:HasStateTag("dead") then
		inst.sg:GoToState("return_home_fly")
	else
		FinishReturnHome(inst)
	end
end

local function ScheduleReturnHome(inst)
	if inst._returning_home or inst._deaggro_pending then
		return
	end
	inst._deaggro_pending = true
	SetPursuitCanSleep(inst, false)
	inst:DoTaskInTime(0, function(i)
		if not i:IsValid() then
			return
		end
		i._deaggro_pending = nil
		RequestReturnHome(i)
	end)
end

local function RememberPursuitTarget(inst, target)
	if target == nil or not target:IsValid() then
		return
	end
	inst._pursuit_target = target
	inst._pursuit_target_level = GetMountainLevel(target)
	if inst._pursuit_start == nil then
		inst._pursuit_start = GetTime()
	end
	inst._pursuit_lost_since = nil
	SetPursuitCanSleep(inst, false)
end

local function GetPursuitTarget(inst)
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if target ~= nil and target:IsValid() then
		RememberPursuitTarget(inst, target)
		return target
	end
	target = inst._pursuit_target
	if target ~= nil and target:IsValid() then
		return target
	end
	inst._pursuit_target = nil
	return nil
end

local function IsHardInvalidTarget(target)
	if target == nil or not target:IsValid() then
		return true
	end
	if target:HasTag("playerghost") then
		return true
	end
	if target.components.health == nil or target.components.health:IsDead() then
		return true
	end
	local level = GetMountainLevel(target)
	-- Cave annex / off-mountain: hard stop. nil during teleport gets a grace window instead.
	if level ~= nil and level > TUNING.MS_CAVES_START then
		return true
	end
	return false
end

local function IsSoftValidPursuitTarget(inst, target)
	if IsHardInvalidTarget(target) then
		return false
	end
	if not inst.components.combat:CanTarget(target) then
		-- Mid-teleport / limbo: keep sticky pursuit briefly.
		return inst._pursuit_target == target
	end
	return true
end

local function FindLandingNearTarget(target)
	if target == nil or not target:IsValid() then
		return nil
	end

	local cfg = TUNING.MOUNTAIN_FALCON
	local x, y, z = target.Transform:GetWorldPosition()
	local offset = FindWalkableOffset(
		Vector3(x, 0, z),
		math.random() * TWOPI,
		cfg.CROSS_FLOOR_LAND_RADIUS,
		cfg.CROSS_FLOOR_LAND_ATTEMPTS,
		false,
		true
	)
	if offset ~= nil then
		return x + offset.x, z + offset.z
	end
	-- Always fall back to the target itself so cross-floor never aborts on tile quirks.
	return x, z
end

-- Player can see the new floor: visible, out of climb/drop SG, controls back.
local CLIMB_HOLD_SG = {
	ms_door_use = true,
	ms_door_use_pre = true,
	abyss_drop = true,
}

local function IsPursuitTargetScreenReady(target)
	if target == nil or not target:IsValid() then
		return false
	end
	if target:HasTag("INLIMBO") then
		return false
	end
	if target.IsVisible ~= nil and not target:IsVisible() then
		return false
	end
	if target.sg ~= nil and target.sg.currentstate ~= nil then
		local name = target.sg.currentstate.name
		if CLIMB_HOLD_SG[name] then
			return false
		end
	end
	local pc = target.components.playercontroller
	if pc ~= nil and pc.enabled == false then
		return false
	end
	return true
end

-- Hold above the player until screen is ready (+ post-ready delay for client fade), or timeout.
local function ShouldFinishCrossFloorHold(inst)
	local cfg = TUNING.MOUNTAIN_FALCON
	local hold_start = inst._cross_floor_hold_start or GetTime()
	if GetTime() - hold_start >= cfg.CROSS_FLOOR_LAND_TIMEOUT then
		return true
	end

	local target = inst._pursuit_target
		or (inst.components.combat ~= nil and inst.components.combat.target)
		or nil
	if not IsPursuitTargetScreenReady(target) then
		inst._cross_floor_land_at = nil
		return false
	end

	if inst._cross_floor_land_at == nil then
		local post_ready = cfg.CROSS_FLOOR_LAND_POST_READY_DELAY or 0
		local jitter = cfg.CROSS_FLOOR_LAND_POST_READY_JITTER or 0
		inst._cross_floor_land_at = GetTime() + post_ready + math.random() * jitter
	end
	return GetTime() >= inst._cross_floor_land_at
end

local function NeedsCrossFloorPursue(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end

	local cfg = TUNING.MOUNTAIN_FALCON
	-- Floors are hundreds of units apart; same-floor combat stays well under this.
	local distsq = inst:GetDistanceSqToInst(target)
	if distsq >= cfg.CROSS_FLOOR_DIST * cfg.CROSS_FLOOR_DIST then
		return true
	end

	local my_level = GetMountainLevel(inst)
	local their_level = GetMountainLevel(target)
	local prev_level = inst._pursuit_target_level

	if my_level ~= nil and their_level ~= nil and my_level ~= their_level then
		return true
	end

	-- Target changed floors since last successful sighting (teleport).
	if their_level ~= nil and prev_level ~= nil and their_level ~= prev_level then
		return true
	end

	return false
end

local function TryCrossFloorPursue(inst, target)
	if inst._returning_home or inst._deaggro_pending or inst._cross_flooring then
		return false
	end
	if inst.sg == nil or inst.sg:HasStateTag("dead") then
		return false
	end
	if inst.sg:HasStateTag("flight") then
		return false
	end

	local cfg = TUNING.MOUNTAIN_FALCON
	if inst._cross_floor_ready ~= nil and GetTime() < inst._cross_floor_ready then
		return false
	end

	local lx, lz = FindLandingNearTarget(target)
	if lx == nil then
		return false
	end

	RememberPursuitTarget(inst, target)
	inst._cross_flooring = true
	inst._cross_floor_ready = GetTime() + cfg.CROSS_FLOOR_COOLDOWN
	inst._cross_floor_dest = { x = lx, z = lz }

	-- Re-assert combat target so KeepTarget/brain stay in pursuit after landing.
	if inst.components.combat ~= nil and inst.components.combat.target ~= target then
		inst.components.combat:SetTarget(target)
	end

	inst.sg:GoToState("pursue_crossfloor")
	return true
end

local function OnCrossFloorLanded(inst)
	inst._cross_flooring = false
	inst._cross_floor_hold_start = nil
	inst._cross_floor_land_at = nil
	local target = GetPursuitTarget(inst)
	if target ~= nil and not IsHardInvalidTarget(target) then
		RememberPursuitTarget(inst, target)
		if inst.components.combat ~= nil then
			inst.components.combat:SetTarget(target)
		end
	end
	SyncPursuitSleep(inst)
end

local function IsValidPursuitTarget(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	if IsHardInvalidTarget(target) then
		return false
	end
	if not inst.components.combat:CanTarget(target) then
		return false
	end
	-- Soft territory: allow chase while level is briefly nil (door travel).
	local level = GetMountainLevel(target)
	if level ~= nil and level > TUNING.MS_CAVES_START then
		return false
	end
	if level == nil and inst._pursuit_target ~= target then
		return false
	end
	return true
end

local function UpdatePursuit(inst)
	SyncPursuitSleep(inst)

	if inst._returning_home
		or inst._deaggro_pending
		or inst._cross_flooring
		or (inst.components.health ~= nil and inst.components.health:IsDead())
		or (inst.sg ~= nil and inst.sg:HasStateTag("flight")) then
		return
	end

	local cfg = TUNING.MOUNTAIN_FALCON
	local target = GetPursuitTarget(inst)

	if target ~= nil then
		if IsHardInvalidTarget(target) then
			ScheduleReturnHome(inst)
			return
		end

		local their_level = GetMountainLevel(target)

		-- Distance/level mismatch always wins: climb teleports must trigger even if
		-- GetNearestLevel is briefly nil at door edges.
		if NeedsCrossFloorPursue(inst, target) then
			inst._pursuit_lost_since = nil
			RememberPursuitTarget(inst, target)
			TryCrossFloorPursue(inst, target)
			return
		end

		if their_level ~= nil and their_level > TUNING.MS_CAVES_START then
			ScheduleReturnHome(inst)
			return
		end

		-- Left the mountain for real (both off territory, not mid-door).
		if their_level == nil and not IsOnMountainTerritory(inst) then
			if inst._pursuit_lost_since == nil then
				inst._pursuit_lost_since = GetTime()
			elseif GetTime() - inst._pursuit_lost_since >= cfg.LOST_TARGET_TIME then
				RequestReturnHome(inst)
			end
			return
		end

		if their_level == nil then
			-- Target mid-travel or on a fuzzy edge: hold sticky target.
			return
		end

		inst._pursuit_lost_since = nil
		RememberPursuitTarget(inst, target)

		if inst._pursuit_start ~= nil and GetTime() - inst._pursuit_start >= cfg.DEAGGRO_TIMEOUT then
			RequestReturnHome(inst)
			return
		end

		return
	end

	if inst._pursuit_start ~= nil or inst._pursuit_lost_since ~= nil then
		if inst._pursuit_lost_since == nil then
			inst._pursuit_lost_since = GetTime()
		elseif GetTime() - inst._pursuit_lost_since >= cfg.LOST_TARGET_TIME then
			RequestReturnHome(inst)
		end
	end
end

--------------------------------------------------------------------------

local function IsValidTarget(guy, inst)
	return not inst._returning_home
		and not inst._deaggro_pending
		and IsSoftValidPursuitTarget(inst, guy)
		and IsOnMountainTerritory(guy)
end

local function Retarget(inst)
	if inst._returning_home or inst._deaggro_pending or inst._cross_flooring then
		return nil
	end
	return FindEntity(inst, TUNING.HOUND_TARGET_DIST, IsValidTarget, nil, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
end

local function KeepTarget(inst, target)
	if inst._returning_home or inst._deaggro_pending then
		return false
	end
	-- Keep sticky during cross-floor flight / teleport grace.
	if inst._cross_flooring and inst._pursuit_target == target then
		return true
	end
	if IsSoftValidPursuitTarget(inst, target) then
		RememberPursuitTarget(inst, target)
		return true
	end
	if IsHardInvalidTarget(target) then
		ScheduleReturnHome(inst)
	end
	return false
end

local function IsFalcon(dude)
	return dude:HasTag("mountain_falcon")
end

local function OnAttacked(inst, data)
	if inst._returning_home then
		return
	end
	local attacker = data and data.attacker or nil
	if attacker == nil then
		return
	end

	RememberPursuitTarget(inst, attacker)
	inst.components.combat:SetTarget(attacker)
	inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsFalcon, MAX_TARGET_SHARES)
end

local function OnAttackOther(inst, data)
	if inst._returning_home then
		return
	end
	if data ~= nil and data.target ~= nil then
		RememberPursuitTarget(inst, data.target)
		inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, IsFalcon, MAX_TARGET_SHARES)
	end
end

local function OnNewCombatTarget(inst, data)
	if data ~= nil and data.target ~= nil and not inst._returning_home then
		RememberPursuitTarget(inst, data.target)
	end
end

local function OnDroppedTarget(inst)
	if inst._returning_home or inst._cross_flooring then
		return
	end
	-- Sticky pursuit: restore combat target if we still want them.
	local sticky = inst._pursuit_target
	if sticky ~= nil and sticky:IsValid() and not IsHardInvalidTarget(sticky) then
		inst:DoTaskInTime(0, function(i)
			if not i:IsValid() or i._returning_home then
				return
			end
			if i._pursuit_target == sticky and sticky:IsValid() and not IsHardInvalidTarget(sticky) then
				i.components.combat:SetTarget(sticky)
			end
		end)
		return
	end
	if inst._pursuit_start ~= nil and inst._pursuit_lost_since == nil then
		inst._pursuit_lost_since = GetTime()
	end
	SyncPursuitSleep(inst)
end

local function OnEntitySleep(inst)
	if IsActivelyPursuing(inst) then
		SetPursuitCanSleep(inst, false)
		return
	end
	ClearPursuitTimers(inst)
	inst._returning_home = false
	inst._cross_flooring = false
	SetPursuitCanSleep(inst, true)
	DoReturn(inst)
end

local function OnStopDay(inst)
	if inst:IsAsleep() and not IsActivelyPursuing(inst) then
		DoReturn(inst)
	end
end

local function OnPreLoad(inst, data)
	local x, y, z = inst.Transform:GetWorldPosition()
	if y > 0 then
		inst.Transform:SetPosition(x, 0, z)
	end
	ClearPursuitTimers(inst)
	inst._returning_home = false
	inst._cross_flooring = false
	SetPursuitCanSleep(inst, true)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	MakeGhostPhysics(inst, 1, .5)

	inst.DynamicShadow:SetSize(1.5, .75)

	inst.Transform:SetFourFaced()
	inst.Transform:SetScale(.75, .75, .75)

	inst.AnimState:SetBank("mountain_falcon")
	inst.AnimState:SetBuild("mountain_falcon")

	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("mountain_falcon")
	inst:AddTag("scarytoprey")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.scrapbook_scale = 0.75

	local locomotor = inst:AddComponent("locomotor")
	locomotor:EnableGroundSpeedMultiplier(false)
	locomotor:SetTriggersCreep(false)
	locomotor.walkspeed = TUNING.HOUND_SPEED
	locomotor.runspeed = TUNING.HOUND_SPEED
	locomotor.pathcaps = { allowocean = true }

	inst:SetStateGraph("SGmountain_falcon")
	inst:SetBrain(brain)

	local eater = inst:AddComponent("eater")
	eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
	eater:SetStrongStomach(true)

	local sleeper = inst:AddComponent("sleeper")
	sleeper:SetResistance(3)
	sleeper.sleeptestfn = nil

	local combat = inst:AddComponent("combat")
	combat.hiteffectsymbol = "bat_body"
	combat:SetDefaultDamage(TUNING.HOUND_DAMAGE)
	combat:SetAttackPeriod(TUNING.HOUND_ATTACK_PERIOD)
	combat:SetRetargetFunction(3, Retarget)
	combat:SetKeepTargetFunction(KeepTarget)
	combat:SetHurtSound("dontstarve/creatures/bat/hurt")
	combat.lastwasattackedtime = -math.huge

	local health = inst:AddComponent("health")
	health:SetMaxHealth(TUNING.HOUND_HEALTH)

	local lootdropper = inst:AddComponent("lootdropper")
	lootdropper:SetChanceLootTable("mountain_falcon")

	inst:AddComponent("inspectable")
	inst:AddComponent("knownlocations")

	MakeMediumBurnableCharacter(inst, "bat_body")
	MakeMediumFreezableCharacter(inst, "bat_body")

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)
	inst:ListenForEvent("newcombattarget", OnNewCombatTarget)
	inst:ListenForEvent("droppedtarget", OnDroppedTarget)

	inst:WatchWorldState("stopday", OnStopDay)
	inst.OnEntitySleep = OnEntitySleep
	inst.OnPreLoad = OnPreLoad

	inst.RequestReturnHome = RequestReturnHome
	inst.FinishReturnHome = FinishReturnHome
	inst.OnCrossFloorLanded = OnCrossFloorLanded
	inst.ShouldFinishCrossFloorHold = ShouldFinishCrossFloorHold
	inst.RememberPursuitTarget = RememberPursuitTarget
	inst.IsValidPursuitTarget = IsValidPursuitTarget
	inst.GetMountainLevel = GetMountainLevel

	inst:DoPeriodicTask(PURSUIT_TICK, UpdatePursuit)

	return inst
end

return Prefab("mountain_falcon", fn, assets, prefabs)
