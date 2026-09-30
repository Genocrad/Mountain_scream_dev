local assets = {
    Asset("ANIM", "anim/ms_mountain_wall.zip"),

    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_high_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_snow_mountain_build.zip"),

    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_corner_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_slope_high_mountain_left_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_corner_high_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_slope_snow_mountain_left_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_corner_snow_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_slope_left_build.zip"),

    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_right_corner_snow_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_slope_snow_mountain_right_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_right_corner_high_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_slope_high_mountain_right_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_right_corner_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_slope_right_build.zip"),
}

local function MakeWall(name, animation, overrides, customfn)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        inst:AddTag("FX")
        inst:AddTag("DECOR")
        inst:AddTag("NOCLICK")
        inst:AddTag("ms_wall")

        inst.Transform:SetScale(1.00, 4, 1.00)
        inst.AnimState:SetBuild(overrides[1].build)
        inst.AnimState:SetBank("ms_mountain_wall")

        for i = 2, #overrides do
            local override = overrides[i]
            inst.AnimState:OverrideSymbol(override.symbol, override.build, override.symbol)
        end

        inst.AnimState:PlayAnimation(animation)
        inst.AnimState:SetSymbolAddColour("filler", 1, 1, 1, 1)
        inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/mountain_vertical_shader.ksh"))

        inst.AnimState:SetDepthTestEnabled(true)
        inst.AnimState:SetDepthWriteEnabled(true)

        if customfn then
            customfn(inst)
        end

        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("savedrotation")
        return inst
    end

    return Prefab(name, fn, assets)
end

local function Wall(inst)
    inst.AnimState:SetSymbolAddColour("wall", 0, 0, 1, 1)
end

local function Right(inst)
    inst.AnimState:SetSymbolAddColour("wall_half_right", 0, 0, 1, 1)
end

local function Left(inst)
    inst.AnimState:SetSymbolAddColour("wall_half_left", 0, 0, 1, 1)
end

local function Slope(inst)
    inst.AnimState:SetSymbolAddColour("wall_half_right", 0.01, 0.07, 0, 1)
    inst.AnimState:SetSymbolAddColour("wall_half_left", 0.01, 0.07, 0, 1)
    inst.AnimState:SetSymbolLightOverride("wall_half_right", 1)
end

return MakeWall("ms_mountain_wall", "idle", {
        { symbol = "wall", build = "ms_mountain_wall_idle_build" },
    }, Wall),
    MakeWall("ms_mountain_corner_wall_right", "idle_right_corner", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_right_corner_build" },
    }, Right),
    MakeWall("ms_mountain_corner_wall_left", "idle_left_corner", {
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_corner_build" },
    }, Left),
    MakeWall("ms_mountain_slope", "idle_left_slope", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_left_slope_right_build" },
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_slope_left_build" },
    }, Slope),
    MakeWall("ms_mountain_wall_snow", "idle_snow_mountain", {
        { symbol = "wall", build = "ms_mountain_wall_idle_snow_mountain_build" },
    }, Wall),
    MakeWall("ms_mountain_corner_wall_right_snow", "idle_right_corner_snow_mountain", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_right_corner_snow_mountain_build" },
    }, Right),
    MakeWall("ms_mountain_corner_wall_left_snow", "idle_left_corner_snow_mountain", {
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_corner_snow_mountain_build" },
    }, Left),
    MakeWall("ms_mountain_slope_snow", "idle_left_slope_snow_mountain", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_left_slope_snow_mountain_right_build" },
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_slope_snow_mountain_left_build" },
    }, Slope),
    MakeWall("ms_mountain_wall_high", "idle_high_mountain", {
        { symbol = "wall", build = "ms_mountain_wall_idle_high_mountain_build" },
    }, Wall),
    MakeWall("ms_mountain_corner_wall_right_high", "idle_right_corner_high_mountain", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_right_corner_high_mountain_build" },
    }, Right),
    MakeWall("ms_mountain_corner_wall_left_high", "idle_left_corner_high_mountain", {
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_corner_high_mountain_build" },
    }, Left),
    MakeWall("ms_mountain_slope_high", "idle_left_slope_high_mountain", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_left_slope_high_mountain_right_build" },
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_slope_high_mountain_left_build" },
    }, Slope)
