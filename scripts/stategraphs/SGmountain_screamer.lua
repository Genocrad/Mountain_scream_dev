require("stategraphs/commonstates")

--------------------------------------------------------------------------

local SCREAM_DRAIN_MUST = { "_combat", "_health" }
local SCREAM_DRAIN_CANT = { "INLIMBO", "flight", "invisible", "notarget", "playerghost", "mountain_screamer", "FX", "DECOR", "epic" }

local function ChooseIdleAnim(inst)
	if not inst._engaged then
		local r = math.random()
		if r < 0.55 then
			return "idolidle"
		elseif r < 0.8 then
			return "idle"
		end
		return "idleshake"
	end
	local r = math.random()
	if r < 0.7 then
		return "idle"
	elseif r < 0.9 then
		return "idleshake"
	end
	return "idolidle"
end

local function GetHomePos(inst)
	return inst.components.knownlocations ~= nil
		and inst.components.knownlocations:GetLocation("spawnpoint")
		or nil
end

local function IsNearHome(inst, dist)
	local home = GetHomePos(inst)
	if home == nil then
		return true
	end
	dist = dist or 3
	return inst:GetDistanceSqToPoint(home) < dist * dist
end

local function DoScreamDrain(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local range = TUNING.MOUNTAIN_SCREAMER.SCREAM_RANGE
	local healed = 0
	for i, v in ipairs(TheSim:FindEntities(x, y, z, range, SCREAM_DRAIN_MUST, SCREAM_DRAIN_CANT)) do
		if v:IsValid()
			and v.components.health ~= nil
			and not v.components.health:IsDead()
			and not v.components.health:IsInvincible()
			and inst.components.combat:CanTarget(v)
		then
			v.components.health:DoDelta(-TUNING.MOUNTAIN_SCREAMER.SCREAM_DRAIN_DAMAGE, false, "mountain_screamer_scream", false, inst, true)
			healed = healed + TUNING.MOUNTAIN_SCREAMER.SCREAM_DRAIN_HEAL
		end
	end
	if healed > 0 and inst.components.health ~= nil and not inst.components.health:IsDead() then
		inst.components.health:DoDelta(healed, false, "mountain_screamer_scream")
	end
end

local BLINK_HIT_MUST = { "_combat" }
local BLINK_HIT_CANT = { "INLIMBO", "flight", "invisible", "notarget", "playerghost", "mountain_screamer", "FX", "DECOR" }

local function CanBlinkTo(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	if inst.components.timer:TimerExists("blink_cd") then
		return false
	end
	local dsq = inst:GetDistanceSqToInst(target)
	local min = TUNING.MOUNTAIN_SCREAMER.BLINK_MIN_DIST
	local max = TUNING.MOUNTAIN_SCREAMER.BLINK_RANGE
	return dsq >= min * min and dsq <= max * max
end

local function GetBlinkLandingPos(target)
	local x, y, z = target.Transform:GetWorldPosition()
	return Vector3(x, 0, z)
end

local function ClearBlinkWarning(inst)
	local fx = inst.sg.statemem.blink_fx
	if fx ~= nil then
		inst.sg.statemem.blink_fx = nil
		if fx:IsValid() then
			fx:Remove()
		end
	end
end

local function SpawnBlinkWarning(inst, pos)
	ClearBlinkWarning(inst)
	local fx = SpawnPrefab("warningshadow")
	if fx ~= nil then
		fx.Transform:SetPosition(pos.x, 0, pos.z)
		local s = TUNING.MOUNTAIN_SCREAMER.BLINK_WARNING_SCALE
		fx.Transform:SetScale(s, s, s)
		inst.sg.statemem.blink_fx = fx
	end
	return fx
end

local function DoBlinkImpact(inst)
	local pos = inst.sg.statemem.blink_pos
	local x, y, z
	if pos ~= nil then
		x, y, z = pos.x, 0, pos.z
	else
		x, y, z = inst.Transform:GetWorldPosition()
	end

	ClearBlinkWarning(inst)

	local radius = TUNING.MOUNTAIN_SCREAMER.BLINK_HIT_RADIUS
	local kb_radius = TUNING.MOUNTAIN_SCREAMER.BLINK_KNOCKBACK_RADIUS
	local kb_str = TUNING.MOUNTAIN_SCREAMER.BLINK_KNOCKBACK_STRENGTH
	local damage = TUNING.MOUNTAIN_SCREAMER.BLINK_DAMAGE

	inst.components.combat.ignorehitrange = true
	for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + 2, BLINK_HIT_MUST, BLINK_HIT_CANT)) do
		if v:IsValid()
			and not v:IsInLimbo()
			and v.components.health ~= nil
			and not v.components.health:IsDead()
			and inst.components.combat:CanTarget(v)
		then
			local range = radius + v:GetPhysicsRadius(0)
			if v:GetDistanceSqToPoint(x, y, z) < range * range then
				local old = inst.components.combat.defaultdamage
				inst.components.combat:SetDefaultDamage(damage)
				inst.components.combat:DoAttack(v)
				inst.components.combat:SetDefaultDamage(old)
				v:PushEvent("knockback", {
					knocker = inst,
					radius = kb_radius,
					strengthmult = kb_str,
					forcelanded = false,
				})
			end
		end
	end
	inst.components.combat.ignorehitrange = false

	ShakeAllCameras(CAMERASHAKE.FULL, 0.55, 0.03, 0.35, inst, 28)
end

local function ChooseAttack(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	-- 瞬移闪烁：消失 → 目标脚下出现并击飞
	if CanBlinkTo(inst, target) then
		inst.sg:GoToState("blink_out", target)
		return true
	end
	-- 血量不满且尖啸冷却完毕 → 尖啸汲取
	if not inst.components.timer:TimerExists("scream_cd")
		and inst.components.health:GetPercent() < 1
	then
		inst.sg:GoToState("scream_pre", target)
		return true
	end
	inst.sg:GoToState("attack", target)
	return true
end

--------------------------------------------------------------------------

local events =
{
	CommonHandlers.OnLocomote(false, true),
	CommonHandlers.OnSink(),
	CommonHandlers.OnFallInVoid(),
	CommonHandlers.OnDeath(),

	EventHandler("doattack", function(inst, data)
		if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
			ChooseAttack(inst, data ~= nil and data.target or inst.components.combat.target)
		end
	end),

	EventHandler("attacked", function(inst, data)
		if inst.components.health:IsDead() then
			return
		end
		if inst.sg:HasStateTag("screaming") then
			-- 打断由 prefab OnAttacked → ms_screamer_screambreak 处理
			return
		end
		if not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("caninterrupt") then
			if not CommonHandlers.HitRecoveryDelay(inst, TUNING.MOUNTAIN_SCREAMER.HIT_RECOVERY) then
				inst.sg:GoToState("hit")
			end
		end
	end),

	EventHandler("ms_screamer_screambreak", function(inst, data)
		if inst.sg:HasStateTag("screaming") and not inst.components.health:IsDead() then
			inst.sg:GoToState("scream_breakoff")
		end
	end),

	EventHandler("ms_screamer_eat", function(inst, data)
		if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
			local target = data ~= nil and data.target or nil
			if target ~= nil and target:IsValid() then
				inst.sg:GoToState("eat_pre", target)
			end
		end
	end),

	EventHandler("ms_screamer_despawn", function(inst)
		if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
			inst.sg:GoToState("disappear")
		end
	end),

	-- 胜利笑：busy 时由 prefab 置 _wants_victory_laugh，idle/periodic 再进
	EventHandler("ms_screamer_victory", function(inst)
		if inst.components.health:IsDead() or inst.sg:HasStateTag("dead") then
			return
		end
		if not inst.sg:HasStateTag("busy") then
			inst._wants_victory_laugh = false
			inst.sg:GoToState("laugh_pre", true)
		end
	end),
}

--------------------------------------------------------------------------

local states =
{
	--------------------------------------------------------------------------
	-- 出现 / 消失
	--------------------------------------------------------------------------
	State{
		name = "appear",
		tags = { "busy", "noattack", "nointerrupt" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("appear")
			inst.components.health:SetInvincible(true)
		end,

		timeline =
		{
			FrameEvent(1, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/appear")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.components.health:SetInvincible(false)
		end,
	},

	-- 脱战回巢：闪烁消失（disappear）后回到出生点
	State{
		name = "disappear",
		tags = { "busy", "noattack", "nointerrupt" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.components.combat:DropTarget()
			inst.AnimState:PlayAnimation("disappear")
			inst.components.health:SetInvincible(true)
		end,

		timeline =
		{
			FrameEvent(1, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/disappear")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					local home = GetHomePos(inst)
					if home ~= nil then
						inst.Physics:Teleport(home.x, 0, home.z)
					end
					inst._engaged = false
					inst._wants_despawn = false
					inst._wants_victory_laugh = false
					inst.sg:GoToState("idle", "idolidle")
				end
			end),
		},

		onexit = function(inst)
			inst.components.health:SetInvincible(false)
		end,
	},

	--------------------------------------------------------------------------
	-- 瞬移闪烁：锁点刷预警 → disappear → 落到锁点 → appearbig 击飞
	--------------------------------------------------------------------------
	State{
		name = "blink_out",
		tags = { "busy", "attack", "noattack", "nointerrupt", "blinking" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.sg.statemem.target = target

			-- 开始时锁死落点，不再追玩家当前位置
			local pos = (target ~= nil and target:IsValid()) and GetBlinkLandingPos(target) or inst:GetPosition()
			inst.sg.statemem.blink_pos = pos
			SpawnBlinkWarning(inst, pos)

			inst.AnimState:PlayAnimation("disappear")
			inst.components.health:SetInvincible(true)
		end,

		timeline =
		{
			FrameEvent(1, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/disappear")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if not inst.AnimState:AnimDone() then
					return
				end

				local pos = inst.sg.statemem.blink_pos
				if pos ~= nil then
					inst.Physics:Teleport(pos.x, 0, pos.z)
					local target = inst.sg.statemem.target
					if target ~= nil and target:IsValid() then
						inst:ForceFacePoint(target.Transform:GetWorldPosition())
					end
					inst.sg.statemem.keep_invincible = true
					inst.sg.statemem.keep_blink = true
					inst.sg:GoToState("blink_in", {
						target = target,
						blink_pos = pos,
						blink_fx = inst.sg.statemem.blink_fx,
					})
				else
					ClearBlinkWarning(inst)
					inst.components.timer:StopTimer("blink_cd")
					inst.components.timer:StartTimer("blink_cd", TUNING.MOUNTAIN_SCREAMER.BLINK_CD)
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.keep_invincible then
				inst.components.health:SetInvincible(false)
			end
			-- 未成功转入 blink_in 时清掉预警
			if not inst.sg.statemem.keep_blink then
				ClearBlinkWarning(inst)
			end
		end,
	},

	State{
		name = "blink_in",
		tags = { "busy", "attack", "noattack", "nointerrupt", "blinking" },

		onenter = function(inst, data)
			inst.components.locomotor:Stop()
			if data ~= nil then
				inst.sg.statemem.target = data.target
				inst.sg.statemem.blink_pos = data.blink_pos
				inst.sg.statemem.blink_fx = data.blink_fx
			end
			inst.AnimState:PlayAnimation("appearbig")
			inst.components.health:SetInvincible(true)
			inst.DynamicShadow:Enable(true)
		end,

		timeline =
		{
			FrameEvent(1, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/appear")
			end),
			-- 落地冲击略往后挪，给预警后的走位时间
			FrameEvent(16, DoBlinkImpact),
			FrameEvent(22, function(inst)
				inst.sg:RemoveStateTag("noattack")
				inst.components.health:SetInvincible(false)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.components.timer:StopTimer("blink_cd")
					inst.components.timer:StartTimer("blink_cd", TUNING.MOUNTAIN_SCREAMER.BLINK_CD)
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			ClearBlinkWarning(inst)
			inst.components.health:SetInvincible(false)
			if not inst.components.timer:TimerExists("blink_cd") then
				inst.components.timer:StartTimer("blink_cd", TUNING.MOUNTAIN_SCREAMER.BLINK_CD)
			end
		end,
	},

	--------------------------------------------------------------------------
	-- Idle
	--------------------------------------------------------------------------
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst, playanim)
			inst.components.locomotor:Stop()

			-- 胜利笑优先于回巢/进食
			if inst._wants_victory_laugh then
				inst._wants_victory_laugh = false
				inst.sg:GoToState("laugh_pre", true)
				return
			end

			-- 脱战回巢到位 → 消失
			if inst._wants_despawn and IsNearHome(inst, 3) then
				inst.sg:GoToState("disappear")
				return
			end

			-- 附近有骷髅且缺血 → 进食
			if not inst._wants_despawn and inst.FindSkeleton ~= nil then
				local skel = inst:FindSkeleton()
				if skel ~= nil and inst:IsNear(skel, TUNING.MOUNTAIN_SCREAMER.EAT_DIST) then
					inst.sg:GoToState("eat_pre", skel)
					return
				end
			end

			local anim = playanim or ChooseIdleAnim(inst)
			inst.AnimState:PlayAnimation(anim, true)
			inst.sg:SetTimeout(GetRandomMinMax(2.5, 5))
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,
	},

	--------------------------------------------------------------------------
	-- 攻击 / 受击 / 死亡
	--------------------------------------------------------------------------
	State{
		name = "attack",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			if target ~= nil and target:IsValid() then
				inst.sg.statemem.target = target
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
			inst.AnimState:PlayAnimation("atk_Rhand")
		end,

		timeline =
		{
			FrameEvent(20, function(inst)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
			end),
			FrameEvent(30, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "hit",
		tags = { "hit", "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("hit")
			CommonHandlers.UpdateHitRecoveryDelay(inst)
		end,

		timeline =
		{
			FrameEvent(10, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "death",
		tags = { "busy", "dead" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("death")
			RemovePhysicsColliders(inst)
			inst.components.lootdropper:DropLoot(inst:GetPosition())
			inst:AddTag("NOCLICK")
			inst.persists = false
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.DynamicShadow:Enable(false)
					-- nofadeout=true 时不会自动消失，播完死亡动画后移除
					inst:Remove()
				end
			end),
		},
	},

	--------------------------------------------------------------------------
	-- 嘲讽 / 大笑
	--------------------------------------------------------------------------
	-- 由 Combat:BattleCry（ChaseAndAttack 追击时）进入；CD 在 battlecryinterval
	State{
		name = "taunt",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("taunt")
		end,

		timeline =
		{
			FrameEvent(5, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	-- data/victory=true：战斗胜利笑（略长）；播完后走回巢 disappear
	State{
		name = "laugh_pre",
		tags = { "busy" },

		onenter = function(inst, victory)
			inst.components.locomotor:Stop()
			inst.sg.statemem.victory = victory == true
			inst._wants_victory_laugh = false
			inst.AnimState:PlayAnimation("laugh_pre")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("laugh_loop", inst.sg.statemem.victory)
				end
			end),
		},
	},

	State{
		name = "laugh_loop",
		tags = { "busy" },

		onenter = function(inst, victory)
			inst.sg.statemem.victory = victory == true
			inst.AnimState:PlayAnimation("laugh_loop", true)
			inst.sg.statemem.loops = victory and 2 or math.random(1, 2)
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() * inst.sg.statemem.loops)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("laugh_pst", inst.sg.statemem.victory)
		end,
	},

	State{
		name = "laugh_pst",
		tags = { "busy" },

		onenter = function(inst, victory)
			inst.sg.statemem.victory = victory == true
			inst.AnimState:PlayAnimation("laugh_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					-- 胜利笑后交回 idle → brain 回巢 / 近家 disappear
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	--------------------------------------------------------------------------
	-- 尖啸（可被玩家打断）
	--------------------------------------------------------------------------
	State{
		name = "scream_pre",
		tags = { "busy", "screaming", "caninterrupt" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			if target ~= nil and target:IsValid() then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
			inst.AnimState:PlayAnimation("scream_pre")
		end,

		timeline =
		{
			FrameEvent(5, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/scream")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("scream_loop")
				end
			end),
		},
	},

	State{
		name = "scream_loop",
		tags = { "busy", "screaming", "caninterrupt" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("scream_loop", true)
			local loop_len = inst.AnimState:GetCurrentAnimationLength()
			inst.sg:SetTimeout(loop_len * TUNING.MOUNTAIN_SCREAMER.SCREAM_LOOP_COUNT)
			inst.sg.statemem.next_drain = GetTime()
			DoScreamDrain(inst)
		end,

		onupdate = function(inst)
			local now = GetTime()
			if now >= inst.sg.statemem.next_drain then
				inst.sg.statemem.next_drain = now + TUNING.MOUNTAIN_SCREAMER.SCREAM_DRAIN_PERIOD
				DoScreamDrain(inst)
			end
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("scream_pst")
		end,
	},

	State{
		name = "scream_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("scream_pst")
			inst.components.timer:StopTimer("scream_cd")
			inst.components.timer:StartTimer("scream_cd", TUNING.MOUNTAIN_SCREAMER.SCREAM_CD)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "scream_breakoff",
		tags = { "busy", "hit" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("scream_breakoff")
			inst.components.timer:StopTimer("scream_cd")
			inst.components.timer:StartTimer("scream_cd", TUNING.MOUNTAIN_SCREAMER.SCREAM_CD * 0.5)
			CommonHandlers.UpdateHitRecoveryDelay(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	--------------------------------------------------------------------------
	-- 进食骷髅
	--------------------------------------------------------------------------
	State{
		name = "eat_pre",
		tags = { "busy", "eating" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.sg.statemem.target = target
			if target ~= nil and target:IsValid() then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
			inst.AnimState:PlayAnimation("eat_pre")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("eat_loop", inst.sg.statemem.target)
				end
			end),
		},
	},

	State{
		name = "eat_loop",
		tags = { "busy", "eating" },

		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.AnimState:PlayAnimation("eat_loop", true)
			inst.sg.statemem.loops = 2
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() * inst.sg.statemem.loops)
		end,

		timeline =
		{
			FrameEvent(8, function(inst)
				local target = inst.sg.statemem.target
				if target ~= nil and target:IsValid() and not target:IsInLimbo() then
					target:Remove()
					inst.sg.statemem.target = nil
					inst.sg.statemem.ate = true
					inst.components.health:DoDelta(TUNING.MOUNTAIN_SCREAMER.EAT_HEAL, false, "mountain_screamer_eat")
				end
			end),
		},

		ontimeout = function(inst)
			inst.sg:GoToState("eat_pst", inst.sg.statemem.ate)
		end,
	},

	State{
		name = "eat_pst",
		tags = { "busy" },

		onenter = function(inst, ate)
			inst.AnimState:PlayAnimation("eat_pst")
			inst.sg.statemem.ate = ate
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},
}

CommonStates.AddWalkStates(states)
CommonStates.AddSinkAndWashAshoreStates(states, { washashore = "hit" })
CommonStates.AddVoidFallStates(states, { voiddrop = "hit" })

return StateGraph("mountain_screamer", states, events, "appear")
