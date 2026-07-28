local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local FollowCamera = require("cameras/followcamera")
local old_ContinuousZoomDelta = FollowCamera.ContinuousZoomDelta
local old_ZoomIn = FollowCamera.ZoomIn
local old_ZoomOut = FollowCamera.ZoomOut

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
