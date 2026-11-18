local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local UpvalueHacker = require("tools/upvaluehacker")

AddComponentPostInit("colourcube", function(self)
    if TheNet:IsDedicated() then
        return
    end

    local OnUpdate = self.OnUpdate
    local ambient = UpvalueHacker.GetUpvalue(self.GetDebugString, "_ambientcc")
    local insanity = UpvalueHacker.GetUpvalue(self.GetDebugString, "_insanitycc")
    local lunacy = UpvalueHacker.GetUpvalue(self.GetDebugString, "_lunacycc")
    local remaining, remaining_index, remaining_scope = UpvalueHacker.GetUpvalue(OnUpdate, "_remainingblendtime")
    if ambient == nil or insanity == nil or lunacy == nil or type(remaining) ~= "number" then
        print("[Mountain Scream] Colour cube preview unavailable: native blend state not found.")
        return
    end

    local preview_cube
    local function ApplyPreview()
        -- Keep native phase, vision and sanity state updating behind the preview.
        for channel = 0, 2 do
            PostProcessor:SetColourCubeData(channel, preview_cube, preview_cube)
        end
    end

    function self:OnUpdate(dt)
        OnUpdate(self, dt)
        if preview_cube ~= nil then
            ApplyPreview()
        end
    end

    function self:MS_SetLookPreview(cube)
        preview_cube = cube
        if cube ~= nil then
            ApplyPreview()
        else
            local fixed = UpvalueHacker.GetUpvalue(OnUpdate, "_overridecc")
            debug.setupvalue(remaining_scope, remaining_index, 0)
            PostProcessor:SetColourCubeData(0, fixed or ambient[2], fixed or ambient[2])
            PostProcessor:SetColourCubeData(1, fixed or insanity[2], fixed or insanity[2])
            PostProcessor:SetColourCubeData(2, lunacy[2], lunacy[2])
            PostProcessor:SetColourCubeLerp(0, 1)
        end
    end
end)
