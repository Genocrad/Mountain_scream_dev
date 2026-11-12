-- Geometry uses FLOAT_PARAMS exclusively: entity X, Z and rotation in radians.
-- Keep player reveal data separate using the unused colour channels of this
-- custom shader. Alpha remains ordinary opaque alpha; no extra render pass.
local function EncodeOffset(value)
    -- Signed 16.8 fixed point, stored in three UNORM8 colour channels.
    local packed = math.floor((value + 32768) * 256 + 0.5)
    packed = math.max(0, math.min(16777215, packed))
    return math.floor(packed / 65536) / 255,
        math.floor(packed / 256) % 256 / 255,
        packed % 256 / 255
end

local function SetView(face, dx, dz, strength)
    local r, g, b = EncodeOffset(dx)
    face.AnimState:SetAddColour(r, g, b, 0)
    r, g, b = EncodeOffset(dz)
    face.AnimState:SetMultColour(r, g, b, 1)
    -- The slope shader reads this as view strength, with ocean tint disabled.
    face.AnimState:SetOceanBlendParams(1 + strength)
end

return { SetView = SetView }
