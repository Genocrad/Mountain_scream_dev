GLOBAL.setfenv(1, GLOBAL)

local MountainLighting = require("mountainlighting")

local old_GetLightAtPoint = Sim.GetLightAtPoint
function Sim:GetLightAtPoint(x, y, z, light_threshold, ...)
    local light_value = old_GetLightAtPoint(self, x, y, z, light_threshold, ...)
    if MountainLighting.IsMountainWorld(TheWorld) then
        light_value = light_value + MountainLighting.GetAmbientValueAtPoint(TheWorld, x, y, z)
    end
    return light_value
end
