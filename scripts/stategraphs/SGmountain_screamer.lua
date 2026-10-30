require("stategraphs/commonstates")

local AOEUtil = require("aoeutil")

--------------------------------------------------------------------------

local SCREAM_DRAIN_MUST = { "_combat", "_health" }
local SCREAM_DRAIN_CANT = { "INLIMBO", "flight", "invisible", "notarget", "playerghost", "mountain_screamer", "FX", "DECOR" }

local function ChooseIdleAnim(inst)
	if inst._stalking then
		return "idolidle"
	end
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

-- 官方击飞没有单独 API：打中后 PushEvent("knockback", ...)；范围技用 AOEUtil.Attack
local BLINK_AOE_TAGS
local function GetBlinkAOETags()
	if BLINK_AOE_TAGS == nil then
		BLINK_AOE_TAGS = AOEUtil.AttackTagSet()
		BLINK_AOE_TAGS:AppendCantTags("playerghost", "mountain_screamer", "FX", "DECOR")
	end
	return BLINK_AOE_TAGS
end

local function ClearScreamBloodFx(target)
	if target == nil then
		return
	end
	if target._ms_scream_blood_fx ~= nil then
		if target._ms_scream_blood_fx:IsValid() then
			target._ms_scream_blood_fx:Remove()
		end
		target._ms_scream_blood_fx = nil
	end
end

local function ClearScreamAffected(inst)
	local affected = inst.sg ~= nil and inst.sg.statemem.scream_affected or nil
	if affected ~= nil then
		for target in pairs(affected) do
			ClearScreamBloodFx(target)
		end
		inst.sg.statemem.scream_affected = nil
	end
end

local function EnsureScreamBloodFx(target)
	if target._ms_scream_blood_fx ~= nil and target._ms_scream_blood_fx:IsValid() then
		return
	end
	local fx = SpawnPrefab("ms_blood_fx")
	if fx == nil then
		return
	end
	fx.entity:SetParent(target.entity)
	fx.Transform:SetPosition(0, 0, 0)
	target._ms_scream_blood_fx = fx
	fx:ListenForEvent("onremove", function()
		if target._ms_scream_blood_fx == fx then
			target._ms_scream_blood_fx = nil
		end
	end)
end

local function ApplyScreamFear(player)
	if player == nil or not player:IsValid() or player:HasTag("playerghost") then
		return
	end
	if player.components.health == nil or player.components.health:IsDead() then
		return
	end
	-- 必须走联网 debuff：MindControlOver 只在「该玩家客户端」收 mindcontrollevel
	-- 纯服务端 PushEvent 看不到黑影占屏
	if player.AddDebuff ~= nil then
		player:AddDebuff("ms_scream_fear", "ms_scream_fear")
	elseif player.components.debuffable ~= nil then
		player.components.debuffable:AddDebuff("ms_scream_fear", "ms_scream_fear")
	end
end

local function DoScreamFearPulse(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local range = TUNING.MOUNTAIN_SCREAMER.SCREAM_RANGE
	for i, v in ipairs(TheSim:FindEntities(x, y, z, range, { "player" }, { "playerghost", "INLIMBO" })) do
		if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
			ApplyScreamFear(v)
		end
	end
end

local function DoScreamDrain(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local range = TUNING.MOUNTAIN_SCREAMER.SCREAM_RANGE
	local player_dmg = TUNING.MOUNTAIN_SCREAMER.SCREAM_PLAYER_DAMAGE
	local creature_dmg = TUNING.MOUNTAIN_SCREAMER.SCREAM_CREATURE_DAMAGE
	local sanity_drain = TUNING.MOUNTAIN_SCREAMER.SCREAM_PLAYER_SANITY
	local heal_ratio = TUNING.MOUNTAIN_SCREAMER.SCREAM_HEAL_RATIO
	local panic_time = TUNING.MOUNTAIN_SCREAMER.SCREAM_PANIC_TIME
	local prev_affected = inst.sg.statemem.scream_affected or {}
	local now_affected = {}
	local healed = 0

	for i, v in ipairs(TheSim:FindEntities(x, y, z, range, SCREAM_DRAIN_MUST, SCREAM_DRAIN_CANT)) do
		if v:IsValid()
			and v.components.health ~= nil
			and not v.components.health:IsDead()
			and not v.components.health:IsInvincible()
			and inst.components.combat:CanTarget(v)
		then
			local is_player = v:HasTag("player")
			local dmg = is_player and player_dmg or creature_dmg
			local hp_before = v.components.health.currenthealth
			v.components.health:DoDelta(-dmg, false, "mountain_screamer_scream", false, inst, true)
			local dealt = math.max(0, hp_before - v.components.health.currenthealth)
			healed = healed + dealt * heal_ratio

			if is_player then
				if v.components.sanity ~= nil then
					v.components.sanity:DoDelta(-sanity_drain)
				end
			else
				if v.components.hauntable ~= nil then
					v.components.hauntable:Panic(panic_time)
				end
			end

			EnsureScreamBloodFx(v)
			now_affected[v] = true
		end
	end

	for target in pairs(prev_affected) do
		if now_affected[target] == nil then
			ClearScreamBloodFx(target)
		end
	end
	inst.sg.statemem.scream_affected = now_affected

	if healed > 0 and inst.components.health ~= nil and not inst.components.health:IsDead() then
		inst.components.health:DoDelta(healed, false, "mountain_screamer_scream")
	end
end

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
	ClearBlinkWarning(inst)

	-- 已 Teleport 到落点；官方 AOEUtil：范围内 DoAttack，有 knockback_str 才击飞
	local old = inst.components.combat.defaultdamage
	inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_SCREAMER.BLINK_DAMAGE)
	AOEUtil.Attack(inst, {
		radius = TUNING.MOUNTAIN_SCREAMER.BLINK_HIT_RADIUS,
		knockback_str = TUNING.MOUNTAIN_SCREAMER.BLINK_KNOCKBACK_STRENGTH,
		knockback_heavystr = 1,
		knockback_forcelanded = false,
	}, GetBlinkAOETags())
	inst.components.combat:SetDefaultDamage(old)

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
		if inst._stalking or inst.sg:HasStateTag("busy") or inst.components.health:IsDead() then
			return
		end
		ChooseAttack(inst, data ~= nil and data.target or inst.components.combat.target)
	end),

	EventHandler("attacked", function(inst, data)
		if inst.components.health:IsDead() then
			return
		end
		-- 注视态开战：prefab 切 taunt，不播 hit
		if inst._stalking or inst._just_engaged_from_stalk or inst.sg.currentstate.name == "taunt" then
			inst._just_engaged_from_stalk = nil
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

	EventHandler("ms_screamer_leave", function(inst)
		if inst.components.health:IsDead() or inst.sg:HasStateTag("dead") then
			return
		end
		-- 胜利笑进行中 / 等待胜利笑：先笑完（由 laugh_pst 再 leave）
		if inst.sg:HasStateTag("laughing") then
			inst._leave_after_victory_laugh = true
			return
		end
		if inst._wants_victory_laugh then
			inst._leave_after_victory_laugh = true
			return
		end
		if not inst.sg:HasStateTag("leaving") then
			inst.sg:GoToState("leave")
		end
	end),

	EventHandler("ms_screamer_stalkrelocate", function(inst)
		if not inst._stalking or inst.components.health:IsDead() then
			return
		end
		if not (inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("dead")) then
			inst.sg:GoToState("stalk_relocate_out")
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
		if inst.components.health:IsDead() or inst.sg:HasStateTag("dead") then
			return
		end
		if not inst.sg:HasStateTag("leaving") then
			inst.sg:GoToState("leave")
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

		onupdate = function(inst)
			if not inst._stalking then
				return
			end
			local target = inst._stalk_target
			if target ~= nil and target:IsValid() then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
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

	-- 离开：播 disappear 后移除（天亮、脱战、目标失效）
	State{
		name = "leave",
		tags = { "busy", "noattack", "nointerrupt", "leaving" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.components.combat:DropTarget()
			inst._stalking = false
			inst._stalk_target = nil
			inst._wants_despawn = false
			inst._engaged = false
			inst.AnimState:PlayAnimation("disappear")
			inst.components.health:SetInvincible(true)
			inst.persists = false
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
					inst:Remove()
				end
			end),
		},
	},

	-- 注视跟随：disappear → 落到玩家附近 → appear
	State{
		name = "stalk_relocate_out",
		tags = { "busy", "noattack", "nointerrupt", "stalking" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			local target = inst._stalk_target
			local pos = inst.GetStalkRelocatePos ~= nil and inst:GetStalkRelocatePos(target) or nil
			inst.sg.statemem.relocate_pos = pos
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
				local pos = inst.sg.statemem.relocate_pos
				if pos ~= nil then
					inst.Physics:Teleport(pos.x, 0, pos.z)
					local target = inst._stalk_target
					if target ~= nil and target:IsValid() then
						inst:ForceFacePoint(target.Transform:GetWorldPosition())
					end
					inst.sg.statemem.keep_invincible = true
					inst.sg:GoToState("stalk_relocate_in")
				else
					inst.sg:GoToState("leave")
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.keep_invincible then
				inst.components.health:SetInvincible(false)
			end
		end,
	},

	State{
		name = "stalk_relocate_in",
		tags = { "busy", "noattack", "nointerrupt", "stalking" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("appear")
			inst.components.health:SetInvincible(true)
		end,

		onupdate = function(inst)
			local target = inst._stalk_target
			if target ~= nil and target:IsValid() then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
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

			-- 注视态只播 idolidle；朝向由 onupdate ForceFacePoint 持续跟随（同 kiki 泡澡盯人）
			if inst._stalking then
				inst.AnimState:PlayAnimation("idolidle", true)
				inst.sg:SetTimeout(GetRandomMinMax(2.5, 5))
				return
			end

			-- 胜利笑优先；笑完后闲逛，天亮再 leave
			if inst._wants_victory_laugh then
				inst._wants_victory_laugh = false
				inst.sg:GoToState("laugh_pre", true)
				return
			end

			-- 附近有骷髅且缺血 → 进食
			if inst.FindSkeleton ~= nil then
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

		onupdate = function(inst)
			if not inst._stalking then
				return
			end
			local target = inst._stalk_target
			if target ~= nil and target:IsValid() then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
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
				-- 官方单目标：打中才 PushEvent("knockback")
				local target = inst.sg.statemem.target
				local canhit = target ~= nil and target:IsValid() and inst.components.combat:CanHitTarget(target)
				inst.components.combat:DoAttack(target)
				if canhit then
					target:PushEvent("knockback", {
						knocker = inst,
						radius = TUNING.MOUNTAIN_SCREAMER.ATTACK_RANGE,
						strengthmult = TUNING.MOUNTAIN_SCREAMER.ATTACK_KNOCKBACK_STRENGTH,
					})
				end
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
	-- 仅开战切入（EngageFromStalk）；战斗中不重复嘲讽
	State{
		name = "taunt",
		tags = { "busy" },

		onenter = function(inst)
			inst._just_engaged_from_stalk = nil
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

	-- data/victory=true：战斗胜利笑（略长）；播完后闲逛等天亮
	State{
		name = "laugh_pre",
		tags = { "busy", "laughing" },

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
		tags = { "busy", "laughing" },

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
		tags = { "busy", "laughing" },

		onenter = function(inst, victory)
			inst.sg.statemem.victory = victory == true
			inst.AnimState:PlayAnimation("laugh_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					-- 白天击杀：笑完再离开；夜晚：闲逛等天亮
					if inst.sg.statemem.victory and inst._leave_after_victory_laugh then
						inst._leave_after_victory_laugh = nil
						inst.sg:GoToState("leave")
					else
						inst.sg:GoToState("idle")
					end
				end
			end),
		},
	},

	--------------------------------------------------------------------------
	-- 尖啸（仅铝器右键砸脸投掷可打断）
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
			inst.sg:SetTimeout(TUNING.MOUNTAIN_SCREAMER.SCREAM_DURATION)
			inst.sg.statemem.scream_affected = {}
			inst.sg.statemem.next_drain = GetTime()
			-- 开场一次织影恐惧（仅对当前范围内玩家）
			DoScreamFearPulse(inst)
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

		onexit = function(inst)
			ClearScreamAffected(inst)
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
			inst.components.timer:StartTimer("scream_cd", TUNING.MOUNTAIN_SCREAMER.SCREAM_CD_BREAK)
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
