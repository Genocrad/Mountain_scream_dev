

local UpvalueHacker = require("tools/upvaluehacker")
local AddPlayerPostInit = AddPlayerPostInit
local DynamicMusic = require("components/dynamicmusic")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

-- Doing this in postinit to make sure it loads after the player.
local EPIC_TAGS = { "epic" }
local NO_EPIC_TAGS = { "noepicmusic" }

local function musicsetup(inst)
          
          local old_startdanger = UpvalueHacker.GetUpvalue(inst.event_listeners["attacked"][TheWorld][1], "StartDanger")

          local oldSEASON_EPICFIGHT_MUSIC = UpvalueHacker.GetUpvalue(inst.event_listeners["attacked"][TheWorld][1], "StartDanger", "SEASON_EPICFIGHT_MUSIC")
          local oldSEASON_DANGER_MUSIC = UpvalueHacker.GetUpvalue(inst.event_listeners["attacked"][TheWorld][1], "StartDanger", "SEASON_DANGER_MUSIC")
          local StopBusy = UpvalueHacker.GetUpvalue(inst.event_listeners["attacked"][TheWorld][1], "StartDanger", "StopBusy")
          local StopDanger = UpvalueHacker.GetUpvalue(inst.event_listeners["attacked"][TheWorld][1], "StartDanger", "StopDanger")
          local _soundemitter = UpvalueHacker.GetUpvalue(inst.event_listeners["attacked"][TheWorld][1], "StartDanger", "_soundemitter")

          local function StartDanger(player, ...)
            -- Hooks just in case
            local SEASON_EPICFIGHT_MUSIC = oldSEASON_EPICFIGHT_MUSIC
            local SEASON_DANGER_MUSIC = oldSEASON_DANGER_MUSIC
            local _isenabled = UpvalueHacker.GetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], "_isenabled")
            local _dangertask = UpvalueHacker.GetUpvalue(player.event_listeners["buildsuccess"][TheWorld][1], "_dangertask")
            local _extendtime = UpvalueHacker.GetUpvalue(player.event_listeners["goinsane"][TheWorld][1], "_extendtime")
            if  player.map_level_current and player.map_level_current < TUNING.MS_CAVES_START and _isenabled then
              if _dangertask == nil then
                local x, y, z = player.Transform:GetWorldPosition()
                local epics = TheSim:FindEntities(x, y, z, 30, EPIC_TAGS, NO_EPIC_TAGS)

                 
                  StopBusy()        
                  _soundemitter:PlaySound(
                    #epics > 0
                    and "ms_sfx/ms_music/boss_music"
                    or "dontstarve/music/music_danger_winter",
                    "danger")
                
                local _dangertask = TheWorld:DoTaskInTime(10, StopDanger, true)
              
                UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], _dangertask, "StopDanger", "_dangertask")
                UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], nil, "StopDanger", "_triggeredlevel")
                UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], 0, "StopDanger", "_extendtime")
              else
                local time = GetTime() + 10
                UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1],  time, "StopDanger", "_extendtime")
              end
            else
              old_startdanger(player, ...)
            end
          end

          UpvalueHacker.SetUpvalue(inst.event_listeners["attacked"][TheWorld][1], StartDanger, "StartDanger")

          -- Now for busy theme.

          local old_startbusy = inst.event_listeners["buildsuccess"][TheWorld][1]
          local BUSYTHEMES = UpvalueHacker.GetUpvalue(inst.event_listeners["buildsuccess"][TheWorld][1], "BUSYTHEMES")
          BUSYTHEMES.MOUNTAINS = GetTableSize(BUSYTHEMES)
          local function StartBusy(player, ...)
            local _isenabled = UpvalueHacker.GetUpvalue(player.event_listeners["buildsuccess"][TheWorld][1], "_isenabled")
            if player.map_level_current and player.map_level_current < TUNING.MS_CAVES_START and _isenabled then
              local _busytask = UpvalueHacker.GetUpvalue(player.event_listeners["buildsuccess"][TheWorld][1], "_busytask")
              local _busytheme = UpvalueHacker.GetUpvalue(player.event_listeners["buildsuccess"][TheWorld][1], "_busytheme")
              local _extendtime = UpvalueHacker.GetUpvalue(player.event_listeners["buildsuccess"][TheWorld][1], "_extendtime")
              local _dangertask = UpvalueHacker.GetUpvalue(player.event_listeners["buildsuccess"][TheWorld][1], "_dangertask")
              if not (TheWorld.state.iscaveday or TheWorld.state.iscavedusk) then
                return
              elseif _busytask ~= nil then
                _extendtime = GetTime() + 15
                UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], _extendtime, "StopBusy", "_extendtime")
              elseif _dangertask == nil and (_extendtime == 0 or GetTime() >= _extendtime) then
                if _busytheme ~= BUSYTHEMES.MOUNTAINS then
                  _soundemitter:KillSound("busy")
                  _soundemitter:PlaySound("dontstarve/music/music_work_winter", "busy")
                end

                _soundemitter:SetParameter("busy", "intensity", 1)
                _busytask = TheWorld:DoTaskInTime(15, StopBusy, true)

                UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], BUSYTHEMES.MOUNTAINS, "StopBusy", "_busytheme")
                UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], _busytask, "StopBusy", "_busytask")
                UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], 0, "StopBusy", "_extendtime")
              end
            else
              old_startbusy(player, ...)
            end
          end

          UpvalueHacker.SetUpvalue(inst.event_listeners["performaction"][TheWorld][1], StartBusy, "StartBusy")

          -- Dawn/Dusk stingers 


          local function OnPhase(inst, phase)
            if ThePlayer.map_level_current and ThePlayer.map_level_current < TUNING.MS_CAVES_START then
              local _isenabled = UpvalueHacker.GetUpvalue(ThePlayer.event_listeners["buildsuccess"][TheWorld][1], "_isenabled")
              local _extendtime = UpvalueHacker.GetUpvalue(ThePlayer.event_listeners["buildsuccess"][TheWorld][1], "_extendtime")
              local _dangertask = UpvalueHacker.GetUpvalue(ThePlayer.event_listeners["buildsuccess"][TheWorld][1], "_dangertask")
              local _busytask = UpvalueHacker.GetUpvalue(ThePlayer.event_listeners["buildsuccess"][TheWorld][1], "_busytask")
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
              StopBusy()
              --Repurpose this as a delay before stingers or busy can start again
              _extendtime = (time or GetTime()) + 15
              UpvalueHacker.SetUpvalue(TheWorld.event_listeners["enabledynamicmusic"][TheWorld][1], _extendtime, "StopBusy", "_extendtime")
            end
          end

          TheWorld:WatchWorldState("cavephase", OnPhase)
        end
    
AddPlayerPostInit(function(inst)
    local music_was_set_upped = false -- Not the best way to do it, but who cares -\_(-_-)_
    if not TheNet:IsDedicated() then
      inst:DoTaskInTime(2, function(inst) if inst.event_listeners["attacked"] ~= nil and not music_was_set_upped then music_was_set_upped = true musicsetup(inst) end end)
      inst:DoTaskInTime(4, function(inst) if inst.event_listeners["attacked"] ~= nil and not music_was_set_upped then music_was_set_upped = true musicsetup(inst) end end)
      inst:DoTaskInTime(6, function(inst) if inst.event_listeners["attacked"] ~= nil and not music_was_set_upped then music_was_set_upped = true musicsetup(inst) end end)
      inst:DoTaskInTime(8, function(inst) if inst.event_listeners["attacked"] ~= nil and not music_was_set_upped then music_was_set_upped = true musicsetup(inst) end end)
      inst:DoTaskInTime(10, function(inst) if inst.event_listeners["attacked"] ~= nil and not music_was_set_upped then music_was_set_upped = true musicsetup(inst) end end)
      inst:DoTaskInTime(12, function(inst) if inst.event_listeners["attacked"] ~= nil and not music_was_set_upped then music_was_set_upped = true musicsetup(inst) end end)
      inst:DoTaskInTime(14, function(inst) if inst.event_listeners["attacked"] ~= nil and not music_was_set_upped then music_was_set_upped = true musicsetup(inst) end end)
    end
  end)
