local Builder = require("components/builder")
local old_CheckIngredientsForMimic =  Builder.CheckIngredientsForMimic


local ENV = env
GLOBAL.setfenv(1, GLOBAL)

function Builder:CheckIngredientsForMimic(ingredients, ...)
    for _, ents in pairs(ingredients) do
        for item in pairs(ents) do
            if item.components.temperature and TUNING.MS_SMELT_TEMP[item.prefab] then
                if item.components.temperature:GetCurrent() >= TUNING.MS_SMELT_TEMP[item.prefab] / 2 then
                  self.inst:DoTaskInTime(0, function(inst) if self.inst.components.talker then
                    self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_BURNT"))
                  end end)
                  return true
                end
            end
        end
    end

    return old_CheckIngredientsForMimic(self, ingredients, ...)
end