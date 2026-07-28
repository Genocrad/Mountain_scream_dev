-- Custom logic for forge smelting
local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local Temperature = require("components/temperature")


local old_getinsulation = Temperature.GetInsulation
-- save the product, everything else is the same.
function Temperature:GetInsulation()
  if self.inst:HasTag("ms_ignorenormalinsulation") then
    return -TUNING.SEG_TIME * 0.9, -TUNING.SEG_TIME * 0.9
  else
    return old_getinsulation(self)
  end
end



