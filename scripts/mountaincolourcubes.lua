local function CustomColours(region)
    return
    {
        day = resolvefilepath("images/colour_cubes/ms_" .. region .. "_day_cc.tex"),
        dusk = resolvefilepath("images/colour_cubes/ms_" .. region .. "_dusk_cc.tex"),
        night = resolvefilepath("images/colour_cubes/ms_" .. region .. "_night_cc.tex"),
        full_moon = region == "snowmountain"
            and resolvefilepath("images/colour_cubes/ms_snowmountain_fullmoon_cc.tex")
            or "images/colour_cubes/purple_moon_cc.tex",
    }
end

local low = CustomColours("lowmountain")
local high = CustomColours("highmountain")
local snow = CustomColours("snowmountain")

return { low, low, low, high, high, high, snow, snow, snow, snow }
