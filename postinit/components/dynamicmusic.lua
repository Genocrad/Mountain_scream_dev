
local UpvalueHacker = require("tools/upvaluehacker")
local AddPlayerPostInit = AddPlayerPostInit
local DynamicMusic = require("components/dynamicmusic")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

-- Doing this in postinit to make sure it loads after the player.
local EPIC_TAGS = { "epic" }
local NO_EPIC_TAGS = { "noepicmusic" }

local function GetWorldListeners(entity, event)
	local listeners = entity ~= nil and entity.event_listeners and entity.event_listeners[event]
	return listeners and listeners[TheWorld]
end

local function FirstFn(entity, event)
	local fns = GetWorldListeners(entity, event)
	return fns and fns[1]
end

-- GetUpvalue asserts if an intermediate hop isn't a function. Never let that kill setup.
local function SafeGetUpvalue(fn, ...)
	if type(fn) ~= "function" then
		return nil
	end
	local ok, result = pcall(UpvalueHacker.GetUpvalue, fn, ...)
	if ok then
		return result
	end
	return nil
end

local function SafeSetUpvalue(start_fn, new_val, ...)
	if type(start_fn) ~= "function" then
		return false
	end
	local ok = pcall(UpvalueHacker.SetUpvalue, start_fn, new_val, ...)
	return ok == true
end

local function IsOnMountainSurface(player)
	return player ~= nil
		and player.map_level_current ~= nil
		and player.map_level_current < TUNING.MS_CAVES_START
end

local function musicsetup(inst)
	if TheWorld._ms_dynamicmusic_hooked then
		return
	end

	local attacked_fn = FirstFn(inst, "attacked")
	local perform_fn = FirstFn(inst, "performaction")
	local startbusy_fn = FirstFn(inst, "buildsuccess")
	local insane_fn = FirstFn(inst, "goinsane")
	local trigger_fn = FirstFn(inst, "triggeredevent")
	local enable_fn = FirstFn(TheWorld, "enabledynamicmusic")

	-- Vanilla CheckAction (performaction) is the caller in the crash log.
	-- StartDanger is a shared local; patching either listener is enough if we hit the real one.
	local old_startdanger = SafeGetUpvalue(perform_fn, "StartDanger")
		or SafeGetUpvalue(attacked_fn, "StartDanger")
	if type(old_startdanger) ~= "function" then
		return
	end

	-- Current DST StartDanger often no longer closes over StopBusy / season tables.
	-- Those still live on StartBusy, OnInsane, and the enable handler.
	local StopBusy = SafeGetUpvalue(startbusy_fn, "StopBusy")
		or SafeGetUpvalue(insane_fn, "StopBusy")
		or SafeGetUpvalue(enable_fn, "StopBusy")
		or SafeGetUpvalue(trigger_fn, "StopBusy")
		or SafeGetUpvalue(old_startdanger, "StopBusy")

	local StopDanger = SafeGetUpvalue(trigger_fn, "StopDanger")
		or SafeGetUpvalue(enable_fn, "StopDanger")
		or SafeGetUpvalue(old_startdanger, "StopDanger")

	local _soundemitter = SafeGetUpvalue(startbusy_fn, "_soundemitter")
		or SafeGetUpvalue(enable_fn, "_soundemitter")
		or SafeGetUpvalue(old_startdanger, "_soundemitter")
		or (TheFocalPoint ~= nil and TheFocalPoint.SoundEmitter)

	local function SetDangerState(value, name)
		return SafeSetUpvalue(enable_fn, value, "StopDanger", name)
			or SafeSetUpvalue(trigger_fn, value, "StopDanger", name)
			or SafeSetUpvalue(startbusy_fn, value, "StopDanger", name)
	end

	local function SetBusyState(value, name)
		return SafeSetUpvalue(enable_fn, value, "StopBusy", name)
			or SafeSetUpvalue(startbusy_fn, value, "StopBusy", name)
			or SafeSetUpvalue(insane_fn, value, "StopBusy", name)
	end

	local function StartDanger(player, ...)
		local _isenabled = SafeGetUpvalue(enable_fn, "_isenabled")
		if _isenabled == nil then
			_isenabled = SafeGetUpvalue(startbusy_fn, "_isenabled")
		end
		local _dangertask = SafeGetUpvalue(startbusy_fn, "_dangertask")
			or SafeGetUpvalue(enable_fn, "StopDanger", "_dangertask")

		local can_play_custom = IsOnMountainSurface(player)
			and _isenabled
			and _soundemitter ~= nil
			and _soundemitter.PlaySound ~= nil

		if can_play_custom then
			if _dangertask == nil then
				local x, y, z = player.Transform:GetWorldPosition()
				local epics = TheSim:FindEntities(x, y, z, 30, EPIC_TAGS, NO_EPIC_TAGS)

				if type(StopBusy) == "function" then
					StopBusy()
				else
					_soundemitter:KillSound("busy")
				end

				_soundemitter:PlaySound(
					#epics > 0
					and "ms_sfx/ms_music/boss_music"
					or "dontstarve/music/music_danger_winter",
					"danger")

				if type(StopDanger) == "function" then
					local dangertask = TheWorld:DoTaskInTime(10, StopDanger, true)
					SetDangerState(dangertask, "_dangertask")
					SetDangerState(nil, "_triggeredlevel")
					SetDangerState(0, "_extendtime")
				end
			else
				SetDangerState(GetTime() + 10, "_extendtime")
			end
		elseif old_startdanger ~= nil then
			old_startdanger(player, ...)
		end
	end

	local patched = SafeSetUpvalue(perform_fn, StartDanger, "StartDanger")
	patched = SafeSetUpvalue(attacked_fn, StartDanger, "StartDanger") or patched
	if not patched then
		return
	end

	TheWorld._ms_dynamicmusic_hooked = true

	-- Now for busy theme.
	local old_startbusy = startbusy_fn
	local BUSYTHEMES = SafeGetUpvalue(startbusy_fn, "BUSYTHEMES")
	if type(BUSYTHEMES) == "table" and type(old_startbusy) == "function" then
		BUSYTHEMES.MOUNTAINS = GetTableSize(BUSYTHEMES)
		local function StartBusy(player, ...)
			local _isenabled = SafeGetUpvalue(startbusy_fn, "_isenabled")
			if IsOnMountainSurface(player) and _isenabled and _soundemitter ~= nil then
				local _busytask = SafeGetUpvalue(startbusy_fn, "_busytask")
				local _busytheme = SafeGetUpvalue(startbusy_fn, "_busytheme")
				local _extendtime = SafeGetUpvalue(startbusy_fn, "_extendtime")
				local _dangertask = SafeGetUpvalue(startbusy_fn, "_dangertask")
				if not (TheWorld.state.iscaveday or TheWorld.state.iscavedusk) then
					return
				elseif _busytask ~= nil then
					SetBusyState(GetTime() + 15, "_extendtime")
				elseif _dangertask == nil and (_extendtime == 0 or GetTime() >= _extendtime) then
					if _busytheme ~= BUSYTHEMES.MOUNTAINS then
						_soundemitter:KillSound("busy")
						_soundemitter:PlaySound("dontstarve/music/music_work_winter", "busy")
					end

					_soundemitter:SetParameter("busy", "intensity", 1)
					if type(StopBusy) == "function" then
						_busytask = TheWorld:DoTaskInTime(15, StopBusy, true)
					end

					SetBusyState(BUSYTHEMES.MOUNTAINS, "_busytheme")
					SetBusyState(_busytask, "_busytask")
					SetBusyState(0, "_extendtime")
				end
			else
				old_startbusy(player, ...)
			end
		end

		SafeSetUpvalue(perform_fn, StartBusy, "StartBusy")
	end

	-- Dawn/Dusk stingers
	local function OnPhase(world, phase)
		if not IsOnMountainSurface(ThePlayer) or _soundemitter == nil then
			return
		end
		local _isenabled = SafeGetUpvalue(startbusy_fn, "_isenabled")
		local _extendtime = SafeGetUpvalue(startbusy_fn, "_extendtime")
		local _dangertask = SafeGetUpvalue(startbusy_fn, "_dangertask")
		local _busytask = SafeGetUpvalue(startbusy_fn, "_busytask")
		if _dangertask ~= nil or not _isenabled then
			return
		end
		local time
		if _busytask == nil and _extendtime ~= 0 then
			time = GetTime()
			if time < _extendtime then
				return
			end
		end

		if phase == "day" then
			_soundemitter:PlaySound("dontstarve/music/music_dawn_stinger")
		elseif phase == "dusk" then
			_soundemitter:PlaySound("dontstarve/music/music_dusk_stinger")
		else
			return
		end
		if type(StopBusy) == "function" then
			StopBusy()
		else
			_soundemitter:KillSound("busy")
		end
		SetBusyState((time or GetTime()) + 15, "_extendtime")
	end

	TheWorld:WatchWorldState("cavephase", OnPhase)
end

AddPlayerPostInit(function(inst)
	if TheNet:IsDedicated() then
		return
	end
	local function try_setup(player)
		if TheWorld._ms_dynamicmusic_hooked or player ~= ThePlayer then
			return
		end
		if GetWorldListeners(player, "attacked") ~= nil or GetWorldListeners(player, "performaction") ~= nil then
			musicsetup(player)
		end
	end
	-- DynamicMusic attaches player listeners on activation; retry until they exist.
	inst:DoTaskInTime(1, try_setup)
	inst:DoTaskInTime(2, try_setup)
	inst:DoTaskInTime(4, try_setup)
	inst:DoTaskInTime(8, try_setup)
	inst:DoTaskInTime(12, try_setup)
end)
