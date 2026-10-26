local Moisture = require("components/moisture")
local old_GetMoistureRateAssumingRain =  Moisture._GetMoistureRateAssumingRain

local ENV = env
GLOBAL.setfenv(1, GLOBAL)


Moisture._GetMoistureRateAssumingRain = function(self)
	if self.inst.components.dungeonplayertracker then
    local level = self.inst.components.dungeonplayertracker:GetLevel()
    if level and level > TUNING.MS_RAIN_MAX_LEVEL and level <= TUNING.MS_CAVES_START then
      return 0
    end
  end
  return old_GetMoistureRateAssumingRain(self)
end