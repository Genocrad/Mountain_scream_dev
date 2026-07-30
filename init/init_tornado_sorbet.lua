------------------------------------------------------------------------------------------------------------------------
-- 龙卷风星酪：右键自身进入/退出龙卷风形态
------------------------------------------------------------------------------------------------------------------------

local GoatCommon = require("mountain_goat_common")

local is_chinese = locale == "zh" or locale == "zht" or locale == "zhr"

local MS_TORNADO_FORM = Action({ priority = 3, rmb = true, distance = math.huge, mount_valid = false, invalid_hold_action = true })
MS_TORNADO_FORM.id = "MS_TORNADO_FORM"
MS_TORNADO_FORM.strfn = function(act)
	if act.doer ~= nil and act.doer:HasTag("ms_tornado_active") then
		return "CANCEL"
	end
	return "CAST"
end
MS_TORNADO_FORM.fn = function(act)
	return act.doer ~= nil and act.doer:IsValid()
end

AddAction(MS_TORNADO_FORM)

STRINGS.ACTIONS.MS_TORNADO_FORM = {
	CAST = is_chinese and "化为龙卷风" or "Become Tornado",
	CANCEL = is_chinese and "解除龙卷风" or "End Tornado",
}

local function IsTornadoActive(doer)
	return doer ~= nil and doer:HasTag("ms_tornado_active")
end

local function CanCastTornado(doer)
	if doer == nil or not doer:IsValid() then
		return false
	end
	-- 已在龙卷风中：不可再次变身（只能解除）
	if IsTornadoActive(doer) then
		return false
	end
	if doer:HasTag("playerghost") or doer:HasTag("ms_tornado_cd") then
		return false
	end
	if not doer:HasTag("ms_tornado_buff") then
		return false
	end
	if doer.replica.rider ~= nil and doer.replica.rider:IsRiding() then
		return false
	end
	if doer.replica.inventory ~= nil and doer.replica.inventory:IsHeavyLifting() then
		return false
	end
	return true
end

-- 右键自己：有 buff 时可进入；已在龙卷风中可退出
AddComponentAction("SCENE", "combat", function(inst, doer, actions, right)
	if not right or inst ~= doer or not doer:HasTag("player") then
		return
	end
	if IsTornadoActive(doer) then
		table.insert(actions, ACTIONS.MS_TORNADO_FORM)
	elseif CanCastTornado(doer) then
		table.insert(actions, ACTIONS.MS_TORNADO_FORM)
	end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MS_TORNADO_FORM, function(inst, action)
	if IsTornadoActive(inst) then
		inst.sg.statemem.exiting_to_pst = true
		return "ms_tornado_pst"
	elseif CanCastTornado(inst) then
		return "ms_tornado_pre"
	end
end))

AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MS_TORNADO_FORM, function(inst, action)
	if IsTornadoActive(inst) then
		return "ms_tornado_pst"
	elseif CanCastTornado(inst) then
		return "ms_tornado_pre"
	end
end))

------------------------------------------------------------------------------------------------------------------------
-- AoE 伤害 + 冰冻
------------------------------------------------------------------------------------------------------------------------

local WORK_ACTIONS =
{
	CHOP = true,
	DIG = true,
	HAMMER = true,
	MINE = true,
}

local TARGET_TAGS = { "_combat" }
for k in pairs(WORK_ACTIONS) do
	table.insert(TARGET_TAGS, k.."_workable")
end

local TARGET_IGNORE_TAGS = { "INLIMBO", "playerghost", "FX", "DECOR", "tornado_immune", "companion", "abigail" }

local function DestroyStuff(inst)
	local cfg = TUNING.MOUNTAIN_TORNADO_SORBET
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, cfg.AOE_RADIUS, nil, TARGET_IGNORE_TAGS, TARGET_TAGS)
	for _, v in ipairs(ents) do
		if v ~= inst and v:IsValid() then
			if v.components.health ~= nil
					and not v.components.health:IsDead()
					and v.components.combat ~= nil
					and v.components.combat:CanBeAttacked()
					and (TheNet:GetPVPEnabled() or not v:HasAnyTag("player", "possessedbody")) then
				local damage = cfg.AOE_DAMAGE
				if TheNet:GetPVPEnabled() and v:HasTag("player") then
					damage = damage * TUNING.PVP_DAMAGE_MOD
				end
				v.components.combat:GetAttacked(inst, damage, nil, "wind")
				if v:IsValid() then
					GoatCommon.PartialFreeze(v, cfg.FREEZE_PERCENT)
				end
			elseif v.components.workable ~= nil
					and v.components.workable:CanBeWorked()
					and v.components.workable:GetWorkAction() ~= nil
					and WORK_ACTIONS[v.components.workable:GetWorkAction().id] then
				SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
				v.components.workable:WorkedBy(inst, 1)
			end
		end
	end
end

local function StartCooldown(inst)
	if inst._ms_tornado_cd_task ~= nil then
		inst._ms_tornado_cd_task:Cancel()
		inst._ms_tornado_cd_task = nil
	end
	inst:AddTag("ms_tornado_cd")
	inst._ms_tornado_cd_task = inst:DoTaskInTime(TUNING.MOUNTAIN_TORNADO_SORBET.COOLDOWN, function()
		inst._ms_tornado_cd_task = nil
		inst:RemoveTag("ms_tornado_cd")
	end)
end

local function EnsureSpinAnimBuild(inst)
	if not inst._ms_tornado_spin_build then
		inst.AnimState:AddOverrideBuild("player_wx78_actions")
		inst._ms_tornado_spin_build = true
	end
end

local function RemoveTornadoFx(inst, play_pst)
	local fx = inst._ms_tornado_fx
	inst._ms_tornado_fx = nil
	if fx == nil or not fx:IsValid() then
		return
	end
	if play_pst then
		fx.entity:SetParent(nil)
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		if fx.SoundEmitter ~= nil then
			fx.SoundEmitter:KillSound("spinLoop")
		end
		fx.AnimState:PlayAnimation("tornado_pst")
		fx:ListenForEvent("animover", function(f)
			if f:IsValid() then
				f:Remove()
			end
		end)
	else
		fx:Remove()
	end
end

local function ClearTornadoVisual(inst, play_fx_pst)
	RemoveTornadoFx(inst, play_fx_pst)
	inst:RemoveTag("ms_tornado_active")
	inst.AnimState:SetMultColour(1, 1, 1, 1)
	if inst.DynamicShadow ~= nil then
		inst.DynamicShadow:Enable(true)
	end
	if inst.components.locomotor ~= nil then
		inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "ms_tornado_speed")
	end
end

local function SetupTornadoVisual(inst)
	RemoveTornadoFx(inst, false)
	inst:AddTag("ms_tornado_active")
	inst.AnimState:SetMultColour(0, 0, 0, 0)
	if inst.DynamicShadow ~= nil then
		inst.DynamicShadow:Enable(false)
	end
	local fx = SpawnPrefab("mountain_tornado_player_fx")
	if fx ~= nil then
		fx.entity:SetParent(inst.entity)
		fx.Transform:SetPosition(0, 0, 0)
		inst._ms_tornado_fx = fx
	end
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "ms_tornado_speed", TUNING.MOUNTAIN_TORNADO_SORBET.MOVE_SPEED_MULT)
end

------------------------------------------------------------------------------------------------------------------------
-- 移动：对齐 WX78 spin（本机摇杆 + 联机 PredictOverrideLocomote）
------------------------------------------------------------------------------------------------------------------------

-- playercontroller.lua 里同名函数是 local，模组侧需自行实现
local function GetWorldControllerVector()
	local xdir = TheInput:GetAnalogControlValue(CONTROL_MOVE_RIGHT) - TheInput:GetAnalogControlValue(CONTROL_MOVE_LEFT)
	local ydir = TheInput:GetAnalogControlValue(CONTROL_MOVE_UP) - TheInput:GetAnalogControlValue(CONTROL_MOVE_DOWN)
	local deadzone = TUNING.CONTROLLER_DEADZONE_RADIUS
	if math.abs(xdir) >= deadzone or math.abs(ydir) >= deadzone then
		local dir = TheCamera:GetRightVec() * xdir - TheCamera:GetDownVec() * ydir
		return dir:GetNormalized()
	end
end

local function GetLocalAnalogDir(inst)
	if inst.HUD == nil or inst.components.playercontroller == nil then
		return nil
	end
	local isenabled, ishudblocking = inst.components.playercontroller:IsEnabled()
	if not (isenabled or ishudblocking) then
		return nil
	end
	return GetWorldControllerVector()
end

local function SetTornadoRemoteOverride(inst, enable)
	if inst.player_classified ~= nil then
		inst.player_classified.busyremoteoverridelocomote:set(enable)
	end
end

-- 非主机客户端：nopredict 下普通 DirectWalking 发不出去，需手动发 OverrideLocomote
-- （官方只在 busy 时走这条；我们不加 busy 以保留右键取消）
AddComponentPostInit("playercontroller", function(self)
	local _OnUpdate = self.OnUpdate
	function self:OnUpdate(dt, ...)
		_OnUpdate(self, dt, ...)
		if self.ismastersim or self.handler == nil or self.classified == nil then
			return
		end
		if not self.inst:HasTag("ms_tornado_active") then
			self._ms_tornado_override_locomote_tick = nil
			return
		end
		if not self.classified.busyremoteoverridelocomote:value() then
			return
		end
		local isenabled, ishudblocking = self:IsEnabled()
		if not (isenabled or ishudblocking) then
			return
		end
		local dir = GetWorldControllerVector()
		local tick = GetTick()
		if dir ~= nil then
			self._ms_tornado_override_locomote_tick = tick
			self:RemotePredictOverrideLocomote(math.atan2(-dir.z, dir.x) * RADIANS)
		elseif self._ms_tornado_override_locomote_tick == tick - 1 then
			self:RemotePredictOverrideLocomote(nil, false)
			self._ms_tornado_override_locomote_tick = nil
		end
	end
end)

------------------------------------------------------------------------------------------------------------------------
-- Stategraphs
------------------------------------------------------------------------------------------------------------------------

local SPIN_LOOP_ANIM_SPEED = 3
local SPIN_LOOP_COUNT = 3

local function ResetAnimSpeed(inst)
	inst.AnimState:SetDeltaTimeMultiplier(1)
end

local function StartSpinLoops(inst, play_sound)
	inst.sg.statemem.phase = "spin"
	inst.sg.statemem.spin_loops_left = SPIN_LOOP_COUNT
	inst.AnimState:SetDeltaTimeMultiplier(SPIN_LOOP_ANIM_SPEED)
	inst.AnimState:PlayAnimation("wx_spin_attack_loop")
	if play_sound then
		inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
	end
end

-- animover 时调用：若还需继续转则返回 true
local function ContinueSpinLoops(inst)
	local left = (inst.sg.statemem.spin_loops_left or 1) - 1
	inst.sg.statemem.spin_loops_left = left
	if left > 0 then
		inst.AnimState:PlayAnimation("wx_spin_attack_loop")
		return true
	end
	return false
end

AddStategraphState("wilson", State{
	name = "ms_tornado_pre",
	tags = { "busy", "nopredict", "nomorph", "ms_tornado" },

	onenter = function(inst)
		EnsureSpinAnimBuild(inst)
		inst.components.locomotor:Stop()
		inst:PerformBufferedAction()
		-- 抬手 → 加速多播几轮旋转 loop → 再换成龙卷风外观
		inst.sg.statemem.phase = "pre"
		inst.AnimState:PlayAnimation("chop_pre")
	end,

	events =
	{
		EventHandler("animover", function(inst)
			if not inst.AnimState:AnimDone() then
				return
			end
			if inst.sg.statemem.phase == "pre" then
				StartSpinLoops(inst, true)
			elseif inst.sg.statemem.phase == "spin" then
				if ContinueSpinLoops(inst) then
					return
				end
				ResetAnimSpeed(inst)
				inst.sg.statemem.tornadoing = true
				SetupTornadoVisual(inst)
				inst.sg:GoToState("ms_tornado_loop")
			end
		end),
	},

	onexit = function(inst)
		ResetAnimSpeed(inst)
		if not inst.sg.statemem.tornadoing then
			ClearTornadoVisual(inst, false)
		end
	end,
})

AddStategraphState("wilson_client", State{
	name = "ms_tornado_pre",
	tags = { "busy", "nopredict", "nomorph", "ms_tornado" },
	server_states = { "ms_tornado_pre", "ms_tornado_loop" },

	onenter = function(inst)
		EnsureSpinAnimBuild(inst)
		inst.components.locomotor:Stop()
		inst.sg.statemem.phase = "pre"
		inst.AnimState:PlayAnimation("chop_pre")
		inst:PerformPreviewBufferedAction()
		inst.sg:SetTimeout(5)
	end,

	events =
	{
		EventHandler("animover", function(inst)
			if not inst.AnimState:AnimDone() then
				return
			end
			if inst.sg.statemem.phase == "pre" then
				StartSpinLoops(inst, false)
			elseif inst.sg.statemem.phase == "spin" then
				ContinueSpinLoops(inst)
			end
		end),
	},

	onupdate = function(inst)
		if inst.sg:ServerStateMatches() then
			if inst.entity:FlattenMovementPrediction() then
				ResetAnimSpeed(inst)
				-- 服务端已进 loop 时切到客户端 loop，便于保留 overridelocomote
				if inst:HasTag("ms_tornado_active") then
					inst.sg:GoToState("ms_tornado_loop")
				else
					inst.sg:GoToState("idle", "noanim")
				end
			end
		elseif inst.bufferedaction == nil then
			inst.sg:GoToState("idle")
		end
	end,

	ontimeout = function(inst)
		inst:ClearBufferedAction()
		inst.sg:GoToState("idle")
	end,

	onexit = function(inst)
		ResetAnimSpeed(inst)
	end,
})

AddStategraphState("wilson", State{
	name = "ms_tornado_loop",
	-- 不加 busy：否则右键自身无法取消；nointerrupt 防止被全局 hit 抢走
	tags = { "nopredict", "nomorph", "ms_tornado", "canrotate", "overridelocomote", "nointerrupt" },

	onenter = function(inst)
		inst.sg.statemem.tornadoing = true
		inst.sg.statemem.aoe_dt = 0
		inst.sg.statemem.remotedir = nil
		inst.components.locomotor:Stop()
		inst.components.locomotor:Clear()
		if inst._ms_tornado_fx == nil then
			SetupTornadoVisual(inst)
		end
		SetTornadoRemoteOverride(inst, true)
		inst.sg:SetTimeout(TUNING.MOUNTAIN_TORNADO_SORBET.FORM_DURATION)
		DestroyStuff(inst)
	end,

	onupdate = function(inst)
		local speed = inst.components.locomotor:GetRunSpeed()
		local dir = GetLocalAnalogDir(inst)
		if dir ~= nil then
			inst.Transform:SetRotation(math.atan2(-dir.z, dir.x) * RADIANS)
			inst.Physics:SetMotorVel(speed, 0, 0)
		elseif inst.sg.statemem.remotedir ~= nil then
			inst.Transform:SetRotation(inst.sg.statemem.remotedir)
			inst.Physics:SetMotorVel(speed, 0, 0)
		else
			inst.Physics:Stop()
		end

		inst.sg.statemem.aoe_dt = inst.sg.statemem.aoe_dt + FRAMES
		if inst.sg.statemem.aoe_dt >= 0.25 then
			inst.sg.statemem.aoe_dt = 0
			DestroyStuff(inst)
		end
	end,

	ontimeout = function(inst)
		inst.sg.statemem.exiting_to_pst = true
		inst.sg:GoToState("ms_tornado_pst")
	end,

	events =
	{
		EventHandler("locomote", function(inst, data)
			if data ~= nil and data.remoteoverridelocomote then
				inst.sg.statemem.remotedir = data.dir
			end
			return true
		end),
		EventHandler("attacked", function(inst)
			if not inst.components.health:IsDead() then
				inst.sg.statemem.exiting_to_pst = true
				inst.sg:GoToState("ms_tornado_pst")
				return true
			end
		end),
	},

	onexit = function(inst)
		inst.Physics:Stop()
		SetTornadoRemoteOverride(inst, false)
		-- 正常进 pst 时留给收招状态处理外观；异常离开则立刻清掉
		if not inst.sg.statemem.exiting_to_pst then
			ClearTornadoVisual(inst, false)
		end
		-- 退出即进 CD，避免客户端在解除瞬间再次点到「化为龙卷风」
		StartCooldown(inst)
	end,
})

AddStategraphState("wilson_client", State{
	name = "ms_tornado_loop",
	tags = { "nopredict", "nomorph", "ms_tornado", "canrotate", "overridelocomote", "nointerrupt" },
	server_states = { "ms_tornado_loop" },

	onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.components.locomotor:Clear()
		inst.entity:SetIsPredictingMovement(false)
	end,

	onupdate = function(inst)
		if inst.sg:ServerStateMatches() then
			inst.entity:FlattenMovementPrediction()
		else
			inst.sg:GoToState("idle", "noanim")
		end
	end,

	events =
	{
		EventHandler("locomote", function()
			return true
		end),
	},
})

AddStategraphState("wilson", State{
	name = "ms_tornado_pst",
	tags = { "busy", "nopredict", "nomorph" },

	onenter = function(inst)
		-- 显形后：加速多转几轮 → 正常速度播 wx_spin_attack_pst → 虚弱
		EnsureSpinAnimBuild(inst)
		inst.components.locomotor:Stop()
		inst.Physics:Stop()
		ClearTornadoVisual(inst, true)
		StartCooldown(inst)
		StartSpinLoops(inst, true)
	end,

	events =
	{
		EventHandler("animover", function(inst)
			if not inst.AnimState:AnimDone() then
				return
			end
			if inst.sg.statemem.phase == "spin" then
				if ContinueSpinLoops(inst) then
					return
				end
				inst.sg.statemem.phase = "pst"
				ResetAnimSpeed(inst)
				inst.AnimState:PlayAnimation("wx_spin_attack_pst")
			elseif inst.sg.statemem.phase == "pst" then
				if inst.components.grogginess ~= nil then
					inst.components.grogginess:AddGrogginess(1, 0)
				end
				inst.sg:GoToState("idle")
			end
		end),
	},

	onexit = function(inst)
		ResetAnimSpeed(inst)
	end,
})

AddStategraphState("wilson_client", State{
	name = "ms_tornado_pst",
	tags = { "busy", "nopredict", "nomorph" },
	server_states = { "ms_tornado_pst" },

	onenter = function(inst)
		EnsureSpinAnimBuild(inst)
		inst.components.locomotor:Stop()
		StartSpinLoops(inst, false)
		inst:PerformPreviewBufferedAction()
		inst.sg:SetTimeout(4)
	end,

	events =
	{
		EventHandler("animover", function(inst)
			if not inst.AnimState:AnimDone() then
				return
			end
			if inst.sg.statemem.phase == "spin" then
				if ContinueSpinLoops(inst) then
					return
				end
				inst.sg.statemem.phase = "pst"
				ResetAnimSpeed(inst)
				inst.AnimState:PlayAnimation("wx_spin_attack_pst")
			end
		end),
	},

	onupdate = function(inst)
		if inst.sg:ServerStateMatches() then
			if inst.entity:FlattenMovementPrediction() then
				ResetAnimSpeed(inst)
				inst.sg:GoToState("idle", "noanim")
			end
		elseif inst.bufferedaction == nil then
			inst.sg:GoToState("idle")
		end
	end,

	ontimeout = function(inst)
		inst:ClearBufferedAction()
		ResetAnimSpeed(inst)
		inst.sg:GoToState("idle")
	end,

	onexit = function(inst)
		ResetAnimSpeed(inst)
	end,
})
