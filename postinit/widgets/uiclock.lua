local UIClock = require("widgets/uiclock")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local CAVE_LIGHT_MUST_TAGS = { "sinkhole", "lightsource" }

local old_update = UIClock.UpdateCaveClock

function UIClock:UpdateCaveClock(owner, ...)
  if ThePlayer.map_level_current and ThePlayer.map_level_current < TUNING.MS_CAVES_START then   
    self:OpenCaveClock()
  else
    old_update(self, owner, ...)
  end
end
