
local UpvalueHacker = require("tools/upvaluehacker")
local AddPrefabPostInit = AddPrefabPostInit

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

-- This is blocking the sound of earthquakes only.
AddPrefabPostInit("cave_network", function(inst)
  if not TheNet:IsDedicated() then
    local old_CanHearQuaker = UpvalueHacker.GetUpvalue(inst.event_listeners["miniquakesoundintensitydirty"][inst][1], "CanHearQuaker")
   
    local function MS_CanHearQuaker()
      local player = ThePlayer
      if player then
        if IsInstInMSLevel(player) then
          return false
        else
          return old_CanHearQuaker()
        end
      end
      return true
    end
    
    UpvalueHacker.SetUpvalue(inst.event_listeners["miniquakesoundintensitydirty"][inst][1], MS_CanHearQuaker, "CanHearQuaker")
  end 
end)