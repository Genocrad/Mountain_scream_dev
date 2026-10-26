
local AddPrefabPostInit = AddPrefabPostInit
local UpvalueHacker = require("tools/upvaluehacker")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

-- This one switches rain off visually. For visual effect of normal rain, go to ms_fake_rain
-- For snow ms_fake_snow
-- And for Moisture-related stuff to postinit/moisture

AddPrefabPostInit("caverain", function(inst)
 
  if not TheNet:IsDedicated() then
  local old_updatefn
  if Prefabs["caverain"] and Prefabs["caverain"].fn then
    old_updatefn = UpvalueHacker.GetUpvalue(inst.PostInit, "updateFunc")
  end
  if old_updatefn then
    local function updateFunc(fastforward, ...)
      if ThePlayer then  
        if IsInstInMSCaves(ThePlayer) then
          return
        end
      end
      old_updatefn(fastforward, ...)
    end
    EmitterManager:AddEmitter(inst, nil, updateFunc)
  end
  end
end)
