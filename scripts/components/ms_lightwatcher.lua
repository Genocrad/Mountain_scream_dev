local MountainLighting = require("mountainlighting")

local DEFAULT_DARK_THRESHOLD = 0.05
local DEFAULT_LIGHT_THRESHOLD = 0.1

local LightWatcherProxy = Class(function(self, inst)
    self.inst = inst
    self.darkthresh = DEFAULT_DARK_THRESHOLD
    self.lightthresh = DEFAULT_LIGHT_THRESHOLD
end)

function LightWatcherProxy:IsActive()
    return self.watcher ~= nil and self.world == TheWorld
        and MountainLighting.IsMountainWorld(TheWorld)
end

function LightWatcherProxy:Configure(watcher, native, release)
    self.world = TheWorld
    self.watcher = watcher
    self.native = native
    self.release = release
    self.inlight = native.IsInLight(watcher)
    local elapsed = self.inlight and native.GetTimeInLight(watcher) or native.GetTimeInDark(watcher)
    self.changetime = GetTime() - elapsed

    -- Preserve any existing per-entity PushEvent override.
    self._rawpushevent = rawget(self.inst, "PushEvent")
    self._pushevent = self.inst.PushEvent
    self._eventwrapper = function(inst, event, ...)
        if self:IsActive() and (event == "enterlight" or event == "enterdark") then
            -- Native events only account for the cave's light.
            self:Refresh()
            return
        end
        return self._pushevent(inst, event, ...)
    end
    self.inst.PushEvent = self._eventwrapper
    self.inst:StartUpdatingComponent(self)
end

function LightWatcherProxy:GetLightValue()
    return self.native.GetLightValue(self.watcher)
        + MountainLighting.GetAmbientValueForEntity(self.inst)
end

function LightWatcherProxy:Refresh()
    if not self:IsActive() then
        return
    end
    local light_value = self:GetLightValue()
    local inlight = self.inlight
    if inlight then
        if light_value < self.darkthresh then
            inlight = false
        end
    elseif light_value > self.lightthresh then
        inlight = true
    end
    if inlight ~= self.inlight then
        -- Grue checks IsInLight from its event handler.
        self.inlight = inlight
        self.changetime = GetTime()
        self._pushevent(self.inst, inlight and "enterlight" or "enterdark")
    end
end

function LightWatcherProxy:IsInLight()
    self:Refresh()
    return self.inlight
end

function LightWatcherProxy:GetTimeInLight()
    self:Refresh()
    return self.inlight and GetTime() - self.changetime or 0
end

function LightWatcherProxy:GetTimeInDark()
    self:Refresh()
    return not self.inlight and GetTime() - self.changetime or 0
end

LightWatcherProxy.OnUpdate = LightWatcherProxy.Refresh

function LightWatcherProxy:Cleanup(restore_state)
    if self.watcher == nil then
        return
    end
    local native_inlight = restore_state and self:IsActive() and self.native.IsInLight(self.watcher)
    local notify = restore_state and self:IsActive() and native_inlight ~= self.inlight
    self.inst:StopUpdatingComponent(self)
    self.release(self.watcher, self)
    self.watcher = nil
    if self.inst.PushEvent == self._eventwrapper then
        self.inst.PushEvent = self._rawpushevent
    end
    if notify then
        -- Restore consumers when removing the component, but not on entity removal.
        self._pushevent(self.inst, native_inlight and "enterlight" or "enterdark")
    end
end

function LightWatcherProxy:OnRemoveFromEntity()
    self:Cleanup(true)
end

function LightWatcherProxy:OnRemoveEntity()
    self:Cleanup(false)
end

return LightWatcherProxy
