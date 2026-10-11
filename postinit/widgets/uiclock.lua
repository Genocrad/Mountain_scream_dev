local UIClock = require("widgets/uiclock")
local AddGlobalClassPostConstruct = AddGlobalClassPostConstruct

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local CAVE_LIGHT_MUST_TAGS = { "sinkhole", "lightsource" }

local old_update = UIClock.UpdateCaveClock
local UIAnim = require "widgets/uianim"

AddGlobalClassPostConstruct("widgets/uiclock", "UIClock", function(self, owner)    

  if self._cave then
    self._rim2 = self:AddChild(Image("images/hud.xml", "clock_rim.tex"))
    self._rim2:SetScale(0.5)
    self._rim2:SetClickable(false)
    self._rim:MoveToBack()
    self._hands:MoveToFront()
    self._text:MoveToFront()
    
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
  if ThePlayer.map_level_current and ThePlayer.map_level_current < TUNING.MS_CAVES_START then   
    self.is_in_level = true
    self._caveopen = nil 
    self._rim:GetAnimState():SetBuild("clock_transitions")
    self._rim:MoveToBack()
    self:OnCavePhaseChanged(TheWorld.state.cavephase)
  else
    self.is_in_level = false
    self._phase = nil -- So cavephase sees that animation play is needed
    self._rim:GetAnimState():SetBuild("cave_clock")
    self._rim:MoveToFront()
    old_update(self, owner, ...)
  end
end
