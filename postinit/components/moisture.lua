local Moisture = require("components/moisture")
local old_GetMoistureRateAssumingRain =  Moisture._GetMoistureRateAssumingRain

local ENV = env
GLOBAL.setfenv(1, GLOBAL)


Moisture._GetMoistureRateAssumingRain = function(self)
	local x,y,z = self.inst.Transform:GetWorldPosition() 
  if TheWorld.net.components.dungeonmapoverwatch then
    local level = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z)
    if level and (level <= TUNING.MS_CAVES_START and level > 6) then
      return 0
    end
  end
  return old_GetMoistureRateAssumingRain(self)
end