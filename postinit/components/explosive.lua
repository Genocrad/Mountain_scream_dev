local Explosive = require("components/explosive")
local old_OnBurnt =  Explosive.OnBurnt


local ENV = env
GLOBAL.setfenv(1, GLOBAL)

function Explosive:OnBurnt(target, ...)
  if TheWorld.components.avalanchecontroller then
    if IsInstInMSOverWorld(self.inst) then
      TheWorld.components.avalanchecontroller:DoDelta(1000)
    end
  end
  old_OnBurnt(self, target, ...)
end