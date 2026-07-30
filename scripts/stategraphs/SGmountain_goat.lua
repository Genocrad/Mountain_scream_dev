require("stategraphs/commonstates")

local events =
{
	CommonHandlers.OnLocomote(false, true),
	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
	CommonHandlers.OnAttack(),
	CommonHandlers.OnAttacked(),
	CommonHandlers.OnDeath(),
}

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst, playanim)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("idle_loop", true)
			inst.sg:SetTimeout(math.random() * 4 + 2)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("bleet")
		end,

		timeline =
		{
			TimeEvent(GetRandomWithVariance(8, 3) * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/chew")
			end),
			TimeEvent(GetRandomWithVariance(33, 3) * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/chew")
			end),
		},
	},

	State{
		name = "walk_start",
		tags = { "moving", "canrotate" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("walk_pre")
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("walk") end),
		},
	},

	State{
		name = "walk",
		tags = { "moving", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:WalkForward()
			inst.AnimState:PlayAnimation("walk")
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/jump")
		end,

		timeline =
		{
			TimeEvent(2 * FRAMES, function(inst)
				inst.components.locomotor:RunForward()
			end),
			TimeEvent(14 * FRAMES, function(inst)
				inst.components.locomotor:WalkForward()
			end),
		},

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("walk") end),
		},
	},

	State{
		name = "walk_stop",
		tags = { "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("walk_pst", false)
		end,

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "taunt",
		tags = { "busy" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt_pre")
			inst.AnimState:PushAnimation("taunt")
			inst.AnimState:PushAnimation("taunt_pst", false)
		end,

		timeline =
		{
			TimeEvent(5 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/taunt")
			end),
			TimeEvent(27 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/hoof")
			end),
			TimeEvent(53 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/hoof")
			end),
			TimeEvent(79 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/hoof")
			end),
		},

		events =
		{
			EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "bleet",
		tags = { "idle" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("bleet")
		end,

		timeline =
		{
			TimeEvent(10 * FRAMES, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/bleet")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},
}

CommonStates.AddCombatStates(states,
{
	attacktimeline =
	{
		TimeEvent(9 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/headbutt")
		end),
		TimeEvent(12 * FRAMES, function(inst)
			inst.components.combat:DoAttack(inst.sg.statemem.target)
		end),
		TimeEvent(15 * FRAMES, function(inst)
			inst.sg:RemoveStateTag("attack")
		end),
	},
	deathtimeline =
	{
		TimeEvent(0 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/death")
		end),
	},
})
CommonStates.AddFrozenStates(states)
CommonStates.AddSleepStates(states,
{
	sleeptimeline =
	{
		TimeEvent(41 * FRAMES, function(inst)
			inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/lightninggoat/sleep")
		end),
	},
})

CommonStates.AddInitState(states, "idle")

return StateGraph("mountain_goat", states, events, "init")
