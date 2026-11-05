local UIClock = require("widgets/uiclock")
local AddGlobalClassPostConstruct = AddGlobalClassPostConstruct

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local CAVE_LIGHT_MUST_TAGS = { "sinkhole", "lightsource" }

local old_update = UIClock.UpdateCaveClock
local UIAnim = require "widgets/uianim"

AddGlobalClassPostConstruct("widgets/uiclock", "UIClock", function(self)

  if self._cave then
    self._rim2 = self:AddChild(Image("images/hud.xml", "clock_rim.tex"))
    self._rim2:SetScale(0.5)
    self._rim2:SetClickable(false)
    self._rim2:Hide()
    
    self.inst:ListenForEvent("phasechanged", function(inst, data) self:OnCavePhaseChanged(data) end, TheWorld)
    self.inst:ListenForEvent("moonphasechanged2", function(inst, data) self:OnMoonPhaseChanged2(data) end, TheWorld)
  end
  
  
  if not self._moonanim then
    self._moonanim = self:AddChild(UIAnim())
    self._moonanim:GetAnimState():SetBank("moon_phases_clock")
    self._moonanim:GetAnimState():SetBuild("moon_phases_clock")
    self._moonanim:GetAnimState():PlayAnimation("hidden")
    self._moonanim:GetAnimState():AnimateWhilePaused(false)
    self._moonanim:MoveToBack()
  end
end)
        
function UIClock:OnCavePhaseChanged(phase)
    if self._phase == phase or not self.is_in_level then
        return
    end
    if self._phase == "night" then
        self._moonanim:GetAnimState():PlayAnimation("trans_in")
    end

    if phase == "day" then
        if self._phase ~= nil then
            self._rim:GetAnimState():PlayAnimation("trans_night_day")
            self._rim:GetAnimState():PushAnimation("idle_day", true)
        else
            self._rim:GetAnimState():PlayAnimation("idle_day", true)
        end
    elseif phase == "dusk" then
        if self._phase ~= nil then
            self._rim:GetAnimState():PlayAnimation("trans_day_dusk")
            self._rim:GetAnimState():PushAnimation("idle_dusk", true)
        else
            self._rim:GetAnimState():PlayAnimation("idle_dusk", true)
        end
    elseif phase == "night" then
        if self._phase ~= nil then
            self._rim:GetAnimState():PlayAnimation("trans_dusk_night")
            self._rim:GetAnimState():PushAnimation("idle_night", true)
        else
            self._rim:GetAnimState():PlayAnimation("idle_night", true)
        end
        self:ShowMoon()
    end

    self._phase = phase
end

function UIClock:UpdateCaveClock(owner, ...)
  if owner == nil then
    return
  end
  -- UIClock() has no owner argument; Controls supplies it on the first update.
  if self._ms_clockowner ~= owner then
    if self._ms_clockowner ~= nil then
      self.inst:RemoveEventCallback("msenvironmentchanged", self._ms_onenvironmentchanged, self._ms_clockowner)
    end
    self._ms_clockowner = owner
    self._ms_onenvironmentchanged = function() self:UpdateCaveClock(owner) end
    self.inst:ListenForEvent("msenvironmentchanged", self._ms_onenvironmentchanged, owner)
  end
  local tracker = owner.components.dungeonplayertracker
  if tracker ~= nil and not tracker:IsReady() then
    return
  end
  if tracker ~= nil and tracker:IsInMsOverWorld() then
    if not self.is_in_level then
      self.is_in_level = true
      self._caveopen = nil
      self._phase = nil
      -- Cancel a pending cave-clock close and restore its hidden/shrunk hand.
      self:StopUpdating()
      self._hands._animtime = nil
      self._hands._img:SetScale(1, 1, 1)
      self._hands._img:Show()
      self._rim2:Show()
      self._rim:GetAnimState():SetBuild("clock_transitions")
      self._rim:MoveToBack()
      self:OnMoonPhaseChanged2({moonphase = TheWorld.state.cavemoonphase, waxing = TheWorld.state.iscavewaxingmoon})
    end
    self:OnCavePhaseChanged(TheWorld.state.cavephase)
  else
    if self.is_in_level then
      self.is_in_level = false
      self._phase = nil
      self._caveopen = nil
      self._lastsinkhole = nil
      self:StopUpdating()
      self._hands._animtime = nil
      self._rim2:Hide()
      self._moonanim:GetAnimState():PlayAnimation("hidden")
      self._rim:GetAnimState():SetBuild("cave_clock")
      self._rim:MoveToFront()
      self._hands:MoveToFront()
      self._text:MoveToFront()
    end
    -- MSCaves and the base cave share the native skylight detection and animations.
    return old_update(self, owner, ...)
  end
end
