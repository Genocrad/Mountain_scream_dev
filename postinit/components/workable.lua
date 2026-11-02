local Workable = require("components/workable")
local old_WorkedBy_Internal =  Workable.WorkedBy_Internal


local ENV = env
GLOBAL.setfenv(1, GLOBAL)

function Workable:WorkedBy_Internal(worker, numworks, ...)
  if TheWorld.components.avalanchecontroller then
    
    if self.inst:HasTag("ms_native") then -- Tau: Assing this tag to any non-movable objects that can be worked. 
      TheWorld.components.avalanchecontroller:DoDelta(100)
    elseif IsInstInMSOverWorld(self.inst) then
      TheWorld.components.avalanchecontroller:DoDelta(100)
    end
  end
  old_WorkedBy_Internal(self, worker, numworks, ...)
end