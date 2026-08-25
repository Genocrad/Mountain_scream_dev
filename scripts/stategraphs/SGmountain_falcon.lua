require("stategraphs/commonstates")

local actionhandlers =
{
	ActionHandler(ACTIONS.GOHOME, "flyaway"),
	ActionHandler(ACTIONS.EAT, "eat_enter"),
}

local events =
{
	EventHandler("fly_back", function(inst, data)
		inst.sg:GoToState("flyback")
	end),
	EventHandler("ms_falcon_return_home", function(inst)
		if not inst.sg:HasStateTag("flight") and not inst.sg:HasStateTag("dead") then
			inst.sg:GoToState("return_home_fly")
		end
	end),
	CommonHandlers.OnLocomote(false, true),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
	CommonHandlers.OnAttack(),
	CommonHandlers.OnAttacked(),
	CommonHandlers.OnDeath(),
	CommonHandlers.OnSleepEx(),
	CommonHandlers.OnWakeEx(),
}

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation("fly_loop", true)
			else
				inst.AnimState:PlayAnimation("fly_loop", true)
			end
		end,

		timeline =
		{
			TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		},

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "action",
		onenter = function(inst, playanim)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("fly_loop", true)
			inst:PerformBufferedAction()
		end,
		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "flyaway",
		tags = { "flight", "busy", "noelectrocute" },
		onenter = function(inst)
			inst.Physics:Stop()

			inst.DynamicShadow:Enable(false)
			inst.components.health:SetInvincible(true)

			inst.AnimState:PlayAnimation("fly_away_pre")
			inst.AnimState:PushAnimation("fly_away_loop", true)

			inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)
		end,

		onupdate = function(inst)
			inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)
		end,

		timeline =
		{
			TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(41 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(51 * FRAMES, function(inst) inst:PerformBufferedAction() end),
		},
	},

	State{
		name = "flyback",
		tags = { "flight", "busy", "noelectrocute" },
		onenter = function(inst)
			inst.Physics:Stop()

			inst.DynamicShadow:Enable(false)
			inst.components.health:SetInvincible(true)

			inst.AnimState:PlayAnimation("fly_back_loop", true)

			local x, y, z = inst.Transform:GetWorldPosition()
			inst.Transform:SetPosition(x, 15, z)
			inst.Physics:SetMotorVel(0, -10 + math.random() * 2, 0)
		end,

		onupdate = function(inst)
			inst.Physics:SetMotorVel(0, -10 + math.random() * 2, 0)
			local pt = Point(inst.Transform:GetWorldPosition())

			if pt.y <= .1 or inst:IsAsleep() then
				pt.y = 0
				inst.Physics:Stop()
				inst.Physics:Teleport(pt.x, pt.y, pt.z)
				inst.DynamicShadow:Enable(true)
				inst.components.health:SetInvincible(false)
				if inst.OnCrossFloorLanded ~= nil then
					inst:OnCrossFloorLanded()
				else
					inst._cross_flooring = false
				end
				inst.sg:GoToState("idle", "fly_back_pst")
			end
		end,

		timeline =
		{
			TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(34 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(41 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		},
	},

	-- 跨层追杀：飞起 → 瞬移到目标层高空待命 → 玩家看清后再降落
	State{
		name = "pursue_crossfloor",
		tags = { "flight", "busy", "noelectrocute" },
		onenter = function(inst)
			inst._cross_flooring = true
			inst.Physics:Stop()
			inst.DynamicShadow:Enable(false)
			if inst.components.health ~= nil then
				inst.components.health:SetInvincible(true)
			end

			inst.AnimState:PlayAnimation("fly_away_pre")
			inst.AnimState:PushAnimation("fly_away_loop", true)

			inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)
			local fly_up = (TUNING.MOUNTAIN_FALCON.CROSS_FLOOR_FLY_UP_TIME or 0.85)
			inst.sg.statemem.teleport_at = GetTime() + fly_up

			local target = inst._pursuit_target
				or (inst.components.combat ~= nil and inst.components.combat.target)
			if target ~= nil and target:IsValid() then
				local x, y, z = target.Transform:GetWorldPosition()
				inst._cross_floor_dest = { x = x, z = z }
			end
		end,

		onupdate = function(inst)
			inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)

			if inst.sg.statemem.did_teleport then
				return
			end
			if GetTime() < inst.sg.statemem.teleport_at then
				local target = inst._pursuit_target
					or (inst.components.combat ~= nil and inst.components.combat.target)
				if target ~= nil and target:IsValid() then
					local x, y, z = target.Transform:GetWorldPosition()
					inst._cross_floor_dest = { x = x, z = z }
				end
				return
			end

			inst.sg.statemem.did_teleport = true
			local dest = inst._cross_floor_dest
			inst._cross_floor_dest = nil

			local target = inst._pursuit_target
				or (inst.components.combat ~= nil and inst.components.combat.target)
			if target ~= nil and target:IsValid() then
				local x, y, z = target.Transform:GetWorldPosition()
				dest = { x = x, z = z }
			end

			inst.Physics:Stop()
			if dest ~= nil then
				inst.Transform:SetPosition(dest.x, 15, dest.z)
			else
				local x, y, z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition(x, 15, z)
			end
			inst.sg:GoToState("pursue_crossfloor_hold")
		end,

		timeline =
		{
			TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(41 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		},
	},

	-- 新层高空待命：跟踪玩家水平位置，等画面就绪（或超时）后再 flyback
	State{
		name = "pursue_crossfloor_hold",
		tags = { "flight", "busy", "noelectrocute" },
		onenter = function(inst)
			inst._cross_flooring = true
			inst._cross_floor_hold_start = GetTime()
			inst._cross_floor_land_at = nil

			inst.Physics:Stop()
			inst.DynamicShadow:Enable(false)
			if inst.components.health ~= nil then
				inst.components.health:SetInvincible(true)
			end

			inst.AnimState:PlayAnimation("fly_away_loop", true)

			local x, y, z = inst.Transform:GetWorldPosition()
			inst.Transform:SetPosition(x, 15, z)
		end,

		onupdate = function(inst)
			-- Hover and track the target so landing stays near the player.
			local target = inst._pursuit_target
				or (inst.components.combat ~= nil and inst.components.combat.target)
			if target ~= nil and target:IsValid() then
				local tx, ty, tz = target.Transform:GetWorldPosition()
				inst.Transform:SetPosition(tx, 15, tz)
			else
				local x, y, z = inst.Transform:GetWorldPosition()
				inst.Transform:SetPosition(x, 15, z)
			end

			local should_land = inst.ShouldFinishCrossFloorHold ~= nil
				and inst:ShouldFinishCrossFloorHold()
			if should_land then
				inst.sg:GoToState("flyback")
			end
		end,

		timeline =
		{
			TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(41 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		},
	},

	-- 脱战回巢：飞起后收入 childspawner（异层也可直接回家）
	State{
		name = "return_home_fly",
		tags = { "flight", "busy", "noelectrocute" },
		onenter = function(inst)
			inst._returning_home = true
			if inst.components.combat ~= nil then
				inst.components.combat:DropTarget()
			end

			inst.Physics:Stop()
			inst.DynamicShadow:Enable(false)
			inst.components.health:SetInvincible(true)

			inst.AnimState:PlayAnimation("fly_away_pre")
			inst.AnimState:PushAnimation("fly_away_loop", true)

			inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)
			inst.sg.statemem.finish_at = GetTime() + 0.85
		end,

		onupdate = function(inst)
			inst.Physics:SetMotorVel(0, 10 + math.random() * 2, 0)

			if inst.sg.statemem.did_finish then
				return
			end
			if GetTime() < inst.sg.statemem.finish_at then
				return
			end

			inst.sg.statemem.did_finish = true
			inst.Physics:Stop()

			if inst.FinishReturnHome ~= nil then
				inst:FinishReturnHome()
			else
				inst.DynamicShadow:Enable(true)
				inst.components.health:SetInvincible(false)
				inst._returning_home = false
				inst.sg:GoToState("idle")
			end
		end,

		timeline =
		{
			TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(41 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
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
			TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("ms_sfx/ms_fx/hawk_taunt") end),
			TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(18 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(28 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(43 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		},

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "eat_enter",
		tags = { "busy" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("eat", false)
		end,

		timeline =
		{
			TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
			TimeEvent(9 * FRAMES, function(inst)
				inst:PerformBufferedAction()
				inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/bite")
			end),
			TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		},

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},
}

local walkanims =
{
	startwalk = "fly_loop",
	walk = "fly_loop",
	stopwalk = "fly_loop",
}

CommonStates.AddWalkStates(states,
{
	starttimeline =
	{
		TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
	},
	walktimeline =
	{
		TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
	},
	endtimeline =
	{
		TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
	},
}, walkanims, true)

CommonStates.AddSleepExStates(states,
{
	starttimeline =
	{
		TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
	},
	sleeptimeline =
	{
		TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("ms_sfx/ms_fx/hawk_sleep") end),
	},
	endtimeline =
	{
		TimeEvent(13 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
	},
},
{
	onsleeping = LandFlyingCreature,
	onexitsleeping = RaiseFlyingCreature,
})

CommonStates.AddCombatStates(states,
{
	attacktimeline =
	{
		TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("ms_sfx/ms_fx/hawk_attack") end),
		TimeEvent(11 * FRAMES, function(inst)
			inst.components.combat:DoAttack()
			inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap")
		end),
	},
	hittimeline =
	{
		TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("ms_sfx/ms_fx/hawk_hurt") end),
		TimeEvent(7 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
	},
	deathtimeline =
	{
		TimeEvent(1 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("ms_sfx/ms_fx/hawk_death") end),
		TimeEvent(4 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/bat/flap") end),
		TimeEvent(15 * FRAMES, LandFlyingCreature),
	},
})

CommonStates.AddFrozenStates(states, LandFlyingCreature, RaiseFlyingCreature)
CommonStates.AddElectrocuteStates(states)

CommonStates.AddInitState(states, "idle")

return StateGraph("mountain_falcon", states, events, "init", actionhandlers)
