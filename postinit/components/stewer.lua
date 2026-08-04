-- Custom logic for forge smelting
local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local Stewer = require("components/stewer")

local function dostew(inst, self)
    self.task = nil
    self.targettime = nil
    self.spoiltime = nil

    if self.ondonecooking ~= nil then
        self.ondonecooking(inst)
    end

    self.done = true
end

-- save the product, everything else is the same.
function Stewer:StopSmeltingemperatureLow()
  if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
  end
  self.product_spoilage = nil
  self.spoiltime = nil
  self.targettime = nil
  self.done = nil
end

function Stewer:RestartSmelting()
  local cooktime = TUNING.MS_SMELT_TIME[self.product] * TUNING.BASE_COOK_TIME
  print(cooktime)
  self.task = self.inst:DoTaskInTime(cooktime, dostew, self)
end


