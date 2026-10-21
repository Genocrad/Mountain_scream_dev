
local SleepingBagUser = require("components/sleepingbaguser")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local old_dosleep = SleepingBagUser.DoSleep

local function WakeUpTest(inst, phase)
  local bed = inst.components.sleepingbaguser.bed
  if bed ~= nil and phase ~= ("cave" .. bed.components.sleepingbag:GetSleepPhase()) then
    bed.components.sleepingbag:DoWakeUp()
  end
end

function SleepingBagUser:DoSleep(bed)
  old_dosleep(self, bed)
  self.inst:WatchWorldState("cavephase", WakeUpTest)
end
