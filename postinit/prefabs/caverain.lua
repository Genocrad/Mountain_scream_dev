
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
        local x,y,z = ThePlayer.Transform:GetWorldPosition()
        local level = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z)
        if level then
          if level <= 10 then
            return
          end
        end
      end
      old_updatefn(fastforward, ...)
    end
    EmitterManager:AddEmitter(inst, nil, updateFunc)
  end
  end
end)
