require("stategraphs/commonstates")

local actionhandlers =
{
	ActionHandler(ACTIONS.GOHOME, "burrow"),
	ActionHandler(ACTIONS.EAT, "eat"),
}

local events =
{
	EventHandler("entershield", function(inst)
		inst.sg:GoToState("burrow_shield")
	end),
	EventHandler("exitshield", function(inst)
		inst.sg:GoToState("emerge")
	end),
	EventHandler("attacked", function(inst)
		if not inst.components.health:IsDead()
			and not inst.sg:HasStateTag("attack")
			and not inst.sg:HasStateTag("shielding") then
			inst.sg:GoToState("hit")
		end
	end),
	EventHandler("doattack", function(inst, data)
		if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
			local target = data ~= nil and data.target or nil
			inst.sg:GoToState(
				target ~= nil
					and target:IsValid()
					and not inst:IsNear(target, TUNING.MOUNTAIN_COCKROACH.MELEE_RANGE)
					and "leap_attack"
					or "attack",
				target
			)
		end
	end),
	EventHandler("death", function(inst)
		inst.sg:GoToState("death")
	end),
	CommonHandlers.OnFreeze(),
	CommonHandlers.OnElectrocute(),
	EventHandler("locomote", function(inst)
		if not inst.sg:HasStateTag("busy") then
			local is_moving = inst.sg:HasStateTag("moving")
			local wants_to_move = inst.components.locomotor:WantsToMoveForward()
			if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
				inst.sg:GoToState(wants_to_move and "premoving" or "idle")
			end
		end
	end),
	EventHandler("trapped", function(inst)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("trapped")
		end
	end),
}

local states =
{
	State{
		name = "death",
		tags = { "busy" },

		onenter = function(inst)
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/death")
			inst.AnimState:PlayAnimation("death")
			inst.AnimState:PushAnimation("dead")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)
			inst.components.lootdropper:DropLoot(inst:GetPosition())
		end,
	},

	State{
		name = "premoving",
		tags = { "moving", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:WalkForward()
			inst.AnimState:PlayAnimation("walk_pre")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("moving")
			end),
		},
	},

	State{
		name = "moving",
		tags = { "moving", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:WalkForward()
			inst.AnimState:PlayAnimation("walk_loop")
		end,

		timeline =
		{
			-- TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/walk") end),
			-- TimeEvent(3 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/walk") end),
			-- TimeEvent(6 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/walk") end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("moving")
			end),
		},
	},

	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst, start_anim)
			inst.Physics:Stop()
			if start_anim then
				inst.AnimState:PlayAnimation(start_anim)
				inst.AnimState:PushAnimation("idle")
			else
				inst.AnimState:PlayAnimation("idle", true)
			end
		end,

		timeline =
		{
			-- TimeEvent(10 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/idle") end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if math.random() < 0.01 then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "burrow_shield",
		tags = { "busy", "shielding" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("burrow")
		end,

		timeline =
		{
			TimeEvent(9 * FRAMES, function(inst)
				inst.DynamicShadow:Enable(false)
				inst.sg:AddStateTag("invisible")
				if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
					inst.components.burnable:Extinguish()
				end
			end),
		},
	},

	State{
		name = "burrow",
		tags = { "busy" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("burrow")
		end,

		timeline =
		{
			-- TimeEvent(5 * FRAMES, function(inst)
			-- 	inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/burrow", "move")
			-- end),
			TimeEvent(9 * FRAMES, function(inst)
				inst.DynamicShadow:Enable(false)
				inst.sg:AddStateTag("invisible")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst:PerformBufferedAction()
			end),
		},

		onexit = function(inst)
			-- inst.SoundEmitter:KillSound("move")
		end,
	},

	State{
		name = "emerge",
		tags = { "busy", "invisible" },

		onenter = function(inst)
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/burrow", "move")
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("unburrow")
			inst.AnimState:SetDeltaTimeMultiplier(GetRandomWithVariance(.9, .2))

			if inst.components.combat ~= nil and inst.components.combat.target ~= nil then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
		end,

		onexit = function(inst)
			-- inst.SoundEmitter:KillSound("move")
			inst.AnimState:SetDeltaTimeMultiplier(1)
			inst.DynamicShadow:Enable(true)
		end,

		timeline =
		{
			TimeEvent(0, function(inst)
				if inst.components.combat ~= nil and inst.components.combat.target ~= nil then
					inst:ForceFacePoint(inst.components.combat.target:GetPosition())
				end
			end),
			TimeEvent(32 * FRAMES, function(inst)
				inst.DynamicShadow:Enable(true)
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
		name = "taunt",
		tags = { "busy" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")

			if inst.components.combat ~= nil and inst.components.combat.target ~= nil then
				inst:ForceFacePoint(inst.components.combat.target:GetPosition())
			end
		end,

		timeline =
		{
			-- TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/taunt") end),
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
		tags = { "busy" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("eat_pre")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst:PerformBufferedAction() then
					inst.sg:GoToState("eat_loop")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "eat_loop",
		tags = { "busy" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("eat_loop", true)
			inst.sg:SetTimeout(1 + math.random())
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("idle", "eat_pst")
		end,
	},

	State{
		name = "attack",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("attack")
			inst.sg.statemem.target = target
		end,

		timeline =
		{
			-- TimeEvent(8 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/attack") end),
			TimeEvent(25 * FRAMES, function(inst)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
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
		name = "leap_attack",
		tags = { "attack", "canrotate", "busy", "jumping" },

		onenter = function(inst, target)
			inst.Physics:Stop()
			inst.components.locomotor:Stop()
			inst.components.locomotor:EnableGroundSpeedMultiplier(false)

			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("leap_attack")
			inst.sg.statemem.target = target

			if target ~= nil and target:IsValid() then
				inst:ForceFacePoint(target:GetPosition())
			end
		end,

		onexit = function(inst)
			-- inst.SoundEmitter:KillSound("buzz")
			inst.components.locomotor:Stop()
			inst.components.locomotor:EnableGroundSpeedMultiplier(true)
			inst.Physics:ClearMotorVelOverride()
		end,

		timeline =
		{
			-- TimeEvent(7 * FRAMES, function(inst)
			-- 	inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/fly_LP", "buzz")
			-- end),
			-- TimeEvent(17 * FRAMES, function(inst)
			-- 	inst.SoundEmitter:KillSound("buzz")
			-- 	inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/idle")
			-- end),
			TimeEvent(11 * FRAMES, function(inst)
				inst.Physics:SetMotorVelOverride(20, 0, 0)
			end),
			TimeEvent(18 * FRAMES, function(inst)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
			end),
			TimeEvent(19 * FRAMES, function(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("taunt")
			end),
		},
	},

	State{
		name = "hit",
		tags = { "busy" },

		onenter = function(inst)
			-- inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/weevole/hit")
			inst.AnimState:PlayAnimation("hit")
			inst.Physics:Stop()
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "trapped",
		tags = { "busy", "trapped" },

		onenter = function(inst)
			inst.Physics:Stop()
			inst:ClearBufferedAction()
			inst.AnimState:PlayAnimation("idle", true)
			inst.sg:SetTimeout(1)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
	},
}

CommonStates.AddFrozenStates(states)
CommonStates.AddElectrocuteStates(states)

return StateGraph("mountain_cockroach", states, events, "idle", actionhandlers)
