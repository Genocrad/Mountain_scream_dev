GLOBAL.setfenv(1, GLOBAL)

local MountainLighting = require("mountainlighting")
local light_watcher_to_proxy = {}

local function clean_up_mapping(light_watcher, proxy)
    if light_watcher_to_proxy[light_watcher] == proxy then
        light_watcher_to_proxy[light_watcher] = nil
    end
end

local function get_light_watcher_proxy(light_watcher)
    local proxy = light_watcher_to_proxy[light_watcher]
    return proxy ~= nil and proxy:IsActive() and proxy or nil
end

local get_light_value = LightWatcher.GetLightValue
function LightWatcher:GetLightValue(...)
    local proxy = get_light_watcher_proxy(self)
    if proxy ~= nil then
        return proxy:GetLightValue()
    end
    return get_light_value(self, ...)
end

local is_in_light = LightWatcher.IsInLight
function LightWatcher:IsInLight(...)
    local proxy = get_light_watcher_proxy(self)
    if proxy ~= nil then
        return proxy:IsInLight()
    end
    return is_in_light(self, ...)
end

local _GetTimeInLight = LightWatcher.GetTimeInLight
function LightWatcher:GetTimeInLight(...)
    local proxy = get_light_watcher_proxy(self)
    if proxy ~= nil then
        return proxy:GetTimeInLight()
    end
    return _GetTimeInLight(self, ...)
end

local _GetTimeInDark = LightWatcher.GetTimeInDark
function LightWatcher:GetTimeInDark(...)
    local proxy = get_light_watcher_proxy(self)
    if proxy ~= nil then
        return proxy:GetTimeInDark()
    end
    return _GetTimeInDark(self, ...)
end

local _SetDarkThresh = LightWatcher.SetDarkThresh
function LightWatcher:SetDarkThresh(value, ...)
    local proxy = light_watcher_to_proxy[self]
    if proxy ~= nil then
        proxy.darkthresh = value
    end
    return _SetDarkThresh(self, value, ...)
end

local _SetLightThresh = LightWatcher.SetLightThresh
function LightWatcher:SetLightThresh(value, ...)
    local proxy = light_watcher_to_proxy[self]
    if proxy ~= nil then
        proxy.lightthresh = value
    end
    return _SetLightThresh(self, value, ...)
end

local native_light_watcher =
{
    GetLightValue = get_light_value,
    IsInLight = is_in_light,
    GetTimeInLight = _GetTimeInLight,
    GetTimeInDark = _GetTimeInDark,
}

local add_light_watcher = Entity.AddLightWatcher
function Entity:AddLightWatcher(...)
    local light_watcher = add_light_watcher(self, ...)
    if MountainLighting.IsMountainWorld(TheWorld) then
        local inst = Ents[self:GetGUID()]
        if inst ~= nil then
            inst:AddComponent("ms_lightwatcher")
            local proxy = inst.components.ms_lightwatcher
            light_watcher_to_proxy[light_watcher] = proxy
            -- inst.LightWatcher may not have been assigned yet.
            proxy:Configure(light_watcher, native_light_watcher, clean_up_mapping)
        end
    end
    return light_watcher
end
