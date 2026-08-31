require("stategraphs/commonstates")

local WATCH_LEAVE_DELAY = 1

local PLAYER_MUST_TAGS = { "player" }
local PLAYER_CANT_TAGS = { "playerghost", "INLIMBO" }

local function GetWatchRange()
	return TUNING.MOUNTAIN_CRATER_POOL.DEFEND_RANGE
end

local function IsValidWatchPlayer(player)
	return player ~= nil and player:IsValid()
		and player:HasTag("player")
		and not player:HasTag("playerghost")
		and player.components.combat ~= nil
		and player.components.health ~= nil
		and not player.components.health:IsDead()
end

local function FindWatchPlayer(inst, pool)
	local range = GetWatchRange()
	local range_sq = range * range
	local nearest, nearest_dsq

	local ix, iy, iz = inst.Transform:GetWorldPosition()
	for _, player in ipairs(TheSim:FindEntities(ix, iy, iz, range, PLAYER_MUST_TAGS, PLAYER_CANT_TAGS)) do
		if IsValidWatchPlayer(player) then
			local dsq = player:GetDistanceSqToPoint(ix, iy, iz)
			if nearest_dsq == nil or dsq < nearest_dsq then
				nearest = player
				nearest_dsq = dsq
			end
		end
	end

	if pool ~= nil and pool:IsValid() then
		local px, py, pz = pool.Transform:GetWorldPosition()
		for _, player in ipairs(TheSim:FindEntities(px, py, pz, range, PLAYER_MUST_TAGS, PLAYER_CANT_TAGS)) do
			if IsValidWatchPlayer(player) then
				local dsq = player:GetDistanceSqToPoint(px, py, pz)
				if nearest_dsq == nil or dsq < nearest_dsq then
					nearest = player
					nearest_dsq = dsq
				end
			end
		end
	end

	return nearest
end

local function IsStillInPool(inst, pool)
	return pool ~= nil and pool:IsValid()
		and pool.components.bathingpool ~= nil
		and pool.components.bathingpool:IsOccupant(inst)
end

local function StartSoakTimer(inst)
	if inst.components.timer ~= nil then
		inst.components.timer:StopTimer("soaktime")
		inst.components.timer:StartTimer("soaktime", TUNING.MOUNTAIN_KIKI.BATH_DURATION)
	end
end

local function StopSoakTimer(inst)
	if inst.components.timer ~= nil then
		inst.components.timer:StopTimer("soaktime")
	end
end

local function StartBathCooldown(inst)
	if inst.components.timer ~= nil then
		inst.components.timer:StartTimer("kiki_bath_cooldown", TUNING.MOUNTAIN_KIKI.BATH_COOLDOWN)
	end
end

-- local function ForceStopHeavyLifting(inst)
-- 	if inst.components.inventory ~= nil and inst.components.inventory:IsHeavyLifting() then
-- 		inst.components.inventory:DropItem(
-- 			inst.components.inventory:Unequip(EQUIPSLOTS.BODY),
-- 			true,
-- 			true
-- 		)
-- 	end
-- end

local function EnsureObstacleCollision(inst, force)
	if not force and inst.sg ~= nil and inst.sg:HasStateTag("soakin") then
		return
	end
	if inst.Physics == nil then
		return
	end
	local mask = inst.Physics:GetCollisionMask()
	if not force and mask ~= nil and bit.band(mask, COLLISION.OBSTACLES) ~= 0 then
		return
	end
	if inst.sg ~= nil then
		inst.sg.statemem.isphysicstoggle = nil
	end
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
	inst.Physics:CollidesWith(COLLISION.CHARACTERS)
	inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local function ToggleOffPhysics(inst)
	inst.sg.statemem.isphysicstoggle = true
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
	EnsureObstacleCollision(inst)
end

local function on_bath_block_knockback()
end

local function GetAdjustedBathDest(pool, dest)
	local px, py, pz = pool.Transform:GetWorldPosition()
	local dx, dy, dz = dest:Get()
	local offset_x = dx - px
	local offset_z = dz - pz
	local dist_sq = offset_x * offset_x + offset_z * offset_z
	if dist_sq <= 0 then
		return dx, dy, dz
	end
	local mult = TUNING.MOUNTAIN_KIKI.BATH_DEST_RADIUS_MULT
	if mult >= 1 then
		return dx, dy, dz
	end
	local dist = math.sqrt(dist_sq)
	local scale = (dist * mult) / dist
	return px + offset_x * scale, dy, pz + offset_z * scale
end

local function LockBathPosition(inst)
	if inst.sg.statemem.bath_x ~= nil then
		inst.Physics:Teleport(inst.sg.statemem.bath_x, inst.sg.statemem.bath_y, inst.sg.statemem.bath_z)
	end
end

local function SetupBathing(inst, data)
	inst.sg.statemem.occupying_bathingpool = data.target

	inst:ForceFacePoint(data.target.Transform:GetWorldPosition())
	-- ForceStopHeavyLifting(inst)
	ToggleOffPhysics(inst)
	inst.sg.statemem.isphysicstoggle = true
	inst.components.locomotor:StopMoving()
	inst.DynamicShadow:Enable(false)

	inst.sg.statemem.range = math.max(0, data.target.components.bathingpool:GetRadius() - inst:GetPhysicsRadius(0))
	local bath_x, bath_y, bath_z = GetAdjustedBathDest(data.target, data.dest)
	inst.sg.statemem.bath_x = bath_x
	inst.sg.statemem.bath_y = bath_y
	inst.sg.statemem.bath_z = bath_z
	inst.Physics:Teleport(bath_x, bath_y, bath_z)

	inst.AnimState:PlayAnimation("bath1", true)
	StartSoakTimer(inst)

	if inst.components.combat ~= nil then
		inst.components.combat:SetTarget(nil)
	end
	inst:ListenForEvent("knockback", on_bath_block_knockback)
end

local function CleanupBathing(inst, teleport_out)
	local pool = inst.sg.statemem.occupying_bathingpool
	if pool ~= nil and teleport_out and pool:IsValid() then
		local radius = inst:GetPhysicsRadius(0) + pool:GetPhysicsRadius(0) + TUNING.MOUNTAIN_KIKI.BATH_DEST_RADIUS_MULT
		if radius > 0 then
			local x, _, z = pool.Transform:GetWorldPosition()
			local passable = GetActionPassableTestFnAt(x, 0, z)
			local dir = inst:GetAngleToPoint(x, 0, z)
			dir = (dir + 180) * DEGREES
			x = x + radius * math.cos(dir)
			z = z - radius * math.sin(dir)
			if passable(x, 0, z) then
				inst.Physics:Teleport(x, 0, z)
			end
		end
	end

	EnsureObstacleCollision(inst, true)
	inst.DynamicShadow:Enable(true)
	StopSoakTimer(inst)
	StartBathCooldown(inst)
	inst:RemoveEventCallback("knockback", on_bath_block_knockback)
	inst.sg.statemem.occupying_bathingpool = nil
	inst.sg.statemem.watch_player = nil
	inst.sg.statemem.watch_clear_time = nil
	inst.sg.statemem.is_watching = nil
	inst.sg.statemem.bath_x = nil
	inst.sg.statemem.bath_y = nil
	inst.sg.statemem.bath_z = nil
end

local function LeaveBathingPool(inst)
	local pool = inst.sg.statemem.occupying_bathingpool
	if pool ~= nil and pool:IsValid() and pool.components.bathingpool ~= nil then
		pool.components.bathingpool:LeavePool(inst)
	end
end

local function on_bath_attacked(inst, data)
	if not inst.sg:HasStateTag("soakin") then
		return
	end
	if data == nil or data.attacker == nil or not data.attacker:HasTag("player") then
		return
	end
	inst.sg.statemem.attacked_while_bathing = true
	inst.sg.statemem.pending_attacker = data.attacker
	LeaveBathingPool(inst)
	if inst.sg:HasStateTag("soakin") then
		inst.sg:GoToState("soakin_exit")
	end
end

local function on_attacked(inst, data)
	if inst.sg:HasStateTag("soakin") then
		return
	end
	if CommonHandlers.TryElectrocuteOnAttacked(inst, data) then
		return
	end
	if inst.components.health ~= nil and not inst.components.health:IsDead()
			and not inst.sg:HasStateTag("dead")
			and not inst.sg:HasStateTag("noattack")
			and CommonHandlers.HitRecoveryDelay(inst) then
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("hit")
		end
	end
end

local actionhandlers =
{
	ActionHandler(ACTIONS.GOHOME, "action"),
	ActionHandler(ACTIONS.PICKUP, "action"),
	ActionHandler(ACTIONS.STEAL, "action"),
	ActionHandler(ACTIONS.PICK, "action"),
	ActionHandler(ACTIONS.HARVEST, "action"),
	ActionHandler(ACTIONS.ATTACK, "throw"),
	ActionHandler(ACTIONS.EAT, "eat"),
	ActionHandler(ACTIONS.SOAKIN, "soakin_pre"),
	ActionHandler(ACTIONS.MS_KNOCK_APPLE, "knock_apple"),
}

local events =
{
	CommonHandlers.OnLocomote(false, true),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
	EventHandler("attacked", on_attacked),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnSleep(),
	EventHandler("doattack", function(inst, data)
		if inst.sg:HasStateTag("soakin") then
			return
		end
		if inst.components.health and not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
			inst.sg:GoToState(
				(not (data.target ~= nil and data.target:IsValid()) and "idle") or
				(inst:GetDistanceSqToInst(data.target) <= (TUNING.MOUNTAIN_KIKI.MELEE_RANGE * TUNING.MOUNTAIN_KIKI.MELEE_RANGE) + 1 and
					"attack"
				) or
				"throw"
			)
		end
	end),
	CommonHandlers.OnCorpseChomped(),
}

local function go_to_idle(inst)
	inst.sg:GoToState("idle")
end

local function play_eat(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/eat")
end

local function play_chest_pound(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/chest_pound")
end

local function on_bath_leave(inst, target)
	if target == inst.sg.statemem.occupying_bathingpool then
		inst.sg.statemem.leaving_bath = true
		inst.sg:GoToState("soakin_exit")
	end
end

local function update_bath_loop(inst)
	local pool = inst.sg.statemem.occupying_bathingpool
	if not IsStillInPool(inst, pool) then
		inst.sg:GoToState("soakin_exit")
		return
	end

	if inst.components.timer ~= nil and not inst.components.timer:TimerExists("soaktime") then
		LeaveBathingPool(inst)
		return
	end

	local player = FindWatchPlayer(inst, pool)
	if player ~= nil then
		if inst.components.combat ~= nil then
			inst.components.combat:SetTarget(nil)
		end
		inst.sg.statemem.watch_player = player
		inst.sg.statemem.watch_clear_time = nil
		if not inst.sg.statemem.is_watching then
			inst.sg.statemem.is_watching = true
			inst.AnimState:PlayAnimation("bath", true)
		end
		inst:ForceFacePoint(player.Transform:GetWorldPosition())
		LockBathPosition(inst)
	elseif inst.sg.statemem.is_watching then
		if inst.sg.statemem.watch_clear_time == nil then
			inst.sg.statemem.watch_clear_time = GetTime() + WATCH_LEAVE_DELAY
		elseif GetTime() >= inst.sg.statemem.watch_clear_time then
			inst.sg.statemem.is_watching = nil
			inst.sg.statemem.watch_clear_time = nil
			inst.sg.statemem.watch_player = nil
			inst.AnimState:PlayAnimation("bath1", true)
		end
	end
end

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },
		onenter = function(inst, playanim)
			EnsureObstacleCollision(inst)
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation("idle_loop", true)
			else
				inst.AnimState:PlayAnimation("idle_loop", true)
			end
			inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/idle")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				local combat_target = inst.components.combat.target
				inst.sg:GoToState((combat_target and combat_target.isplayer and math.random() < 0.05 and "taunt")
					or "idle")
			end),
		},
	},

	State{
		name = "action",
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("interact")
			inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
		end,
		onexit = function(inst)
			inst.SoundEmitter:KillSound("make")
		end,
		timeline =
		{
			FrameEvent(25, function(inst)
				inst:PerformBufferedAction()
			end),
		},
		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "eat",
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("eat", true)
		end,
		onexit = function(inst)
			inst:PerformBufferedAction()
		end,
		timeline =
		{
			TimeEvent(8 * FRAMES, function(inst)
				local waittime = 8 * FRAMES
				for i = 0, 3 do
					inst:DoTaskInTime((i * waittime), play_eat)
				end
			end),
		},
		events =
		{
			EventHandler("animover", go_to_idle),
		},
	},

	State{
		name = "taunt",
		tags = { "busy" },
		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
		end,
		timeline =
		{
			TimeEvent(8 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/taunt")
				local waittime = 2 * FRAMES
				for i = 0, 11 do
					inst:DoTaskInTime((i * waittime), play_chest_pound)
				end
			end),
		},
		events =
		{
			EventHandler("animover", go_to_idle),
		},
	},

	State{
		name = "knock_apple",
		tags = { "attack", "busy", "canrotate" },
		onenter = function(inst)
			inst.components.locomotor:Stop()
			local ba = inst:GetBufferedAction()
			if ba ~= nil and ba.target ~= nil and ba.target:IsValid() then
				inst:ForceFacePoint(ba.target.Transform:GetWorldPosition())
			end
			inst.AnimState:PlayAnimation("atk")
		end,
		timeline =
		{
			TimeEvent(17 * FRAMES, function(inst)
				inst:PerformBufferedAction()
				inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/attack")
				if inst.components.timer ~= nil then
					inst.components.timer:StopTimer("kiki_knock_apple")
					inst.components.timer:StartTimer("kiki_knock_apple", TUNING.MOUNTAIN_KIKI.KNOCK_APPLE_COOLDOWN)
				end
			end),
		},
		events =
		{
			EventHandler("animover", go_to_idle),
		},
	},

	State{
		name = "throw",
		tags = { "attack", "busy", "canrotate", "throwing" },
		onenter = function(inst)
			if not inst.HasAmmo(inst) then
				inst.sg:GoToState("idle")
				return
			end
			inst.sg.statemem.throw_projectile = inst.PickRandomProjectile ~= nil and inst:PickRandomProjectile() or nil
			if inst.sg.statemem.throw_projectile == nil then
				inst.sg:GoToState("idle")
				return
			end
			inst.sg.statemem.throw_target = nil
			local ba = inst:GetBufferedAction()
			if ba ~= nil and ba.target ~= nil and ba.target:IsValid() then
				inst.sg.statemem.throw_target = ba.target
			elseif inst.components.combat ~= nil
					and inst.components.combat.target ~= nil
					and inst.components.combat.target:IsValid() then
				inst.sg.statemem.throw_target = inst.components.combat.target
			end
			if inst.EquipThrower ~= nil then
				inst:EquipThrower()
			end
			if inst.components.locomotor then
				inst.components.locomotor:StopMoving()
			end
			inst.AnimState:PlayAnimation("throw")
		end,
		timeline =
		{
			TimeEvent(14 * FRAMES, function(inst)
				if inst.LaunchThrow ~= nil then
					inst:LaunchThrow()
				end
				inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/throw")
			end),
		},
		events =
		{
			EventHandler("animover", go_to_idle),
		},
	},

	State{
		name = "soakin_pre",
		tags = { "soakin", "busy" },
		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.sg.statemem._soakin_fail_time = GetTime() + 1
		end,
		timeline =
		{
			TimeEvent(0, function(inst)
				inst:PerformBufferedAction()
			end),
		},
		events =
		{
			EventHandler("ms_enterbathingpool", function(inst, data)
				if data and data.target and data.dest then
					inst.sg.statemem._soakin_fail_time = nil
					inst.sg.statemem.occupying_bathingpool = data.target
					inst.sg:GoToState("soakin", data)
				end
			end),
		},
		onupdate = function(inst)
			if inst.sg.statemem._soakin_fail_time ~= nil and GetTime() > inst.sg.statemem._soakin_fail_time then
				inst.sg.statemem._soakin_fail_time = nil
				inst.sg:GoToState("idle")
			end
		end,
	},

	State{
		name = "soakin",
		tags = { "soakin", "busy", "nopredict" },
		onenter = function(inst, data)
			if data ~= nil and data.target ~= nil and data.target:IsValid() and data.target.components.bathingpool ~= nil then
				if inst.sg.statemem.occupying_bathingpool == nil then
					SetupBathing(inst, data)
				else
					inst.AnimState:PlayAnimation(
						inst.sg.statemem.is_watching and "bath" or "bath1",
						true
					)
				end
			else
				inst.sg:GoToState("soakin_exit")
			end
		end,
		onupdate = update_bath_loop,
		events =
		{
			EventHandler("attacked", on_bath_attacked),
			EventHandler("ms_leavebathingpool", on_bath_leave),
		},
	},

	State{
		name = "soakin_exit",
		tags = { "busy", "nopredict" },
		onenter = function(inst)
			local attacked = inst.sg.statemem.attacked_while_bathing
			local attacker = inst.sg.statemem.pending_attacker
			-- CleanupBathing(inst, not attacked)
			CleanupBathing(inst, true)
			inst.sg.statemem.leaving_bath = nil
			inst.sg.statemem.attacked_while_bathing = nil
			inst.sg.statemem.pending_attacker = nil
			if attacked and attacker ~= nil and attacker:IsValid() then
				inst.components.combat:SetTarget(attacker)
				inst.sg:GoToState("hit")
			else
				inst.sg:GoToState("idle")
			end
		end,
	},
}

CommonStates.AddWalkStates(states,
{
	walktimeline =
	{
		TimeEvent(4 * FRAMES, PlayFootstep),
		TimeEvent(5 * FRAMES, PlayFootstep),
		TimeEvent(10 * FRAMES, function(inst)
			PlayFootstep(inst)
			if math.random() < 0.1 then
				inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/idle")
			end
		end),
		TimeEvent(11 * FRAMES, PlayFootstep),
	},
}, nil, nil, nil, nil, {
	startonenter = EnsureObstacleCollision,
	walkonenter = EnsureObstacleCollision,
})

CommonStates.AddSleepStates(states,
{
	sleeptimeline =
	{
		TimeEvent(1 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/sleep")
		end),
	},
})

CommonStates.AddCombatStates(states,
{
	attacktimeline =
	{
		TimeEvent(17 * FRAMES, function(inst)
			inst.components.combat:DoAttack()
			inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/attack")
		end),
	},
	hittimeline =
	{
		TimeEvent(1 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/hurt")
		end),
	},
	deathtimeline =
	{
		TimeEvent(1 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey"..inst.soundtype.."/death")
		end),
	},
},
nil,
nil,
{
	has_corpse_handler = true,
})

CommonStates.AddFrozenStates(states)
CommonStates.AddElectrocuteStates(states)

CommonStates.AddInitState(states, "idle")
CommonStates.AddCorpseStates(states)

return StateGraph("mountain_kiki", states, events, "init", actionhandlers)
