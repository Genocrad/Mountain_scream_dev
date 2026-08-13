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
local PURSUIT_TICK = 0.5

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

local function IsOnMountainTerritory(ent)
	local level = GetMountainLevel(ent)
	return level ~= nil and level <= TUNING.MS_CAVES_START
end

local function ClearPursuitTimers(inst)
	inst._pursuit_start = nil
	inst._pursuit_lost_since = nil
	inst._cross_floor_fail = nil
	inst._cross_floor_dest = nil
end

local function DoReturn(inst)
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
	inst._returning_home = false
	ClearPursuitTimers(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:DropTarget()
	end
	if not DoReturn(inst) then
		-- 无巢：降落到当前位置
		local x, y, z = inst.Transform:GetWorldPosition()
		inst.Physics:Stop()
		inst.Transform:SetPosition(x, 15, z)
		inst.sg:GoToState("flyback")
	end
end

local function RequestReturnHome(inst)
	if (inst.components.health ~= nil and inst.components.health:IsDead()) then
		return
	end
	if inst._returning_home and inst.sg ~= nil and inst.sg.currentstate ~= nil
		and inst.sg.currentstate.name == "return_home_fly" then
		return
	end

	inst._returning_home = true
	inst._deaggro_pending = nil
	ClearPursuitTimers(inst)
	if inst.components.combat ~= nil then
		inst.components.combat:DropTarget()
	end

	if inst.sg ~= nil and not inst.sg:HasStateTag("dead") then
		inst.sg:GoToState("return_home_fly")
	end
end

local function ScheduleReturnHome(inst)
	if inst._returning_home or inst._deaggro_pending then
		return
	end
	inst._deaggro_pending = true
	inst:DoTaskInTime(0, function(i)
		if not i:IsValid() then
			return
		end
		i._deaggro_pending = nil
		RequestReturnHome(i)
	end)
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
	if TheWorld.Map:IsPassableAtPoint(x, 0, z) then
		return x, z
	end
	return nil
end

local function TryCrossFloorPursue(inst, target)
	if inst._returning_home
		or inst._deaggro_pending
		or inst.sg:HasStateTag("flight")
		or inst.sg:HasStateTag("busy")
		or inst.sg:HasStateTag("dead") then
		return
	end

	local cfg = TUNING.MOUNTAIN_FALCON
	if inst._cross_floor_ready ~= nil and GetTime() < inst._cross_floor_ready then
		return
	end

	local lx, lz = FindLandingNearTarget(target)
	if lx == nil then
		inst._cross_floor_fail = (inst._cross_floor_fail or 0) + 1
		if inst._cross_floor_fail >= 2 then
			RequestReturnHome(inst)
		end
		return
	end

	inst._cross_floor_fail = 0
	inst._cross_floor_ready = GetTime() + cfg.CROSS_FLOOR_COOLDOWN
	inst._cross_floor_dest = { x = lx, z = lz }
	inst.sg:GoToState("pursue_crossfloor")
end

local function IsValidPursuitTarget(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	if target:HasTag("playerghost") then
		return false
	end
	if target.components.health == nil or target.components.health:IsDead() then
		return false
	end
	if not inst.components.combat:CanTarget(target) then
		return false
	end
	if not IsOnMountainTerritory(target) then
		return false
	end
	return true
end

local function UpdatePursuit(inst)
	if inst._returning_home
		or inst._deaggro_pending
		or (inst.components.health ~= nil and inst.components.health:IsDead())
		or inst.sg:HasStateTag("flight") then
		return
	end

	local cfg = TUNING.MOUNTAIN_FALCON
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil

	if target ~= nil then
		if not IsValidPursuitTarget(inst, target) then
			ScheduleReturnHome(inst)
			return
		end

		if inst._pursuit_start == nil then
			inst._pursuit_start = GetTime()
		end
		inst._pursuit_lost_since = nil

		if GetTime() - inst._pursuit_start >= cfg.DEAGGRO_TIMEOUT then
			RequestReturnHome(inst)
			return
		end

		local my_level = GetMountainLevel(inst)
		local their_level = GetMountainLevel(target)
		if my_level ~= their_level then
			TryCrossFloorPursue(inst, target)
		end
		return
	end

	-- 曾进入追杀但目标已丢：短暂等待后回巢（死亡/离山走 ScheduleReturnHome，不等待）
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
		and IsValidPursuitTarget(inst, guy)
end

local function Retarget(inst)
	if inst._returning_home or inst._deaggro_pending then
		return nil
	end
	return FindEntity(inst, TUNING.HOUND_TARGET_DIST, IsValidTarget, nil, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
end

local function KeepTarget(inst, target)
	if inst._returning_home or inst._deaggro_pending then
		return false
	end
	if IsValidPursuitTarget(inst, target) then
		return true
	end
	-- 死亡 / 变鬼 / 离开山体 / 进洞穴：立刻安排回巢
	ScheduleReturnHome(inst)
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

	inst.components.combat:SetTarget(attacker)
	inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsFalcon, MAX_TARGET_SHARES)
end

local function OnAttackOther(inst, data)
	if inst._returning_home then
		return
	end
	inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, IsFalcon, MAX_TARGET_SHARES)
end

local function OnNewCombatTarget(inst, data)
	if data ~= nil and data.target ~= nil and not inst._returning_home then
		inst._pursuit_start = GetTime()
		inst._pursuit_lost_since = nil
	end
end

local function OnDroppedTarget(inst)
	if not inst._returning_home and inst._pursuit_start ~= nil and inst._pursuit_lost_since == nil then
		inst._pursuit_lost_since = GetTime()
	end
end

local function OnEntitySleep(inst)
	-- 睡着时收队回巢，避免卡在别层
	ClearPursuitTimers(inst)
	inst._returning_home = false
	DoReturn(inst)
end

local function OnStopDay(inst)
	if inst:IsAsleep() then
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

	-- 支持排箫等催眠；不设自然入睡（夜间走回巢逻辑）
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
	inst.IsValidPursuitTarget = IsValidPursuitTarget
	inst.GetMountainLevel = GetMountainLevel

	inst:DoPeriodicTask(PURSUIT_TICK, UpdatePursuit)

	return inst
end

return Prefab("mountain_falcon", fn, assets, prefabs)
