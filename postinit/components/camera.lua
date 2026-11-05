local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local FollowCamera = require("cameras/followcamera")
local old_ContinuousZoomDelta = FollowCamera.ContinuousZoomDelta
local old_ZoomIn = FollowCamera.ZoomIn
local old_ZoomOut = FollowCamera.ZoomOut

ENV.AddSimPostInit(function()
    if TheNet:IsDedicated() then
        return
    end
    -- Constructor hooks can wrap SetDefault on the instance and overwrite a class hook's result.
    local camera = TheCamera
    local old_SetDefault = camera.SetDefault
    camera.SetDefault = function(self, ...)
        old_SetDefault(self, ...)
        if self == TheCamera and ThePlayer ~= nil then
            local environment = ThePlayer.components.dungeonplayerenvironment
            if environment ~= nil then
                environment:OnCameraReset()
            end
        end
    end
end)

function FollowCamera:ContinuousZoomDelta(delta, ...)
	if self.controllable then
    old_ContinuousZoomDelta(self, delta, ...)
  end
end

function FollowCamera:ZoomIn(step, ...)
	if self.controllable then
    old_ZoomIn(self, step, ...)
  end
end

function FollowCamera:ZoomOut(step, ...)
	if self.controllable then
    old_ZoomOut(self, step, ...)
  end
end
