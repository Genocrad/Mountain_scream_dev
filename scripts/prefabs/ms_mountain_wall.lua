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

local WALL_COLLISION_POINTS = {
    wall = { { -2, 0 }, { 2, 0 } },
    right = { { 0, 0 }, { 2, 0 } },
    left = { { -2, 0 }, { 0, 0 } },
    -- Slopes use the center baseline, without following the shader's deformation.
    slope = { { -2, 0 }, { 2, 0 } },
}
local WALL_COLLISION_HEIGHT = 4

local function UpdateWallPhysics(inst)
    -- Bake wall rotation into the static mesh vertices on both server and clients.
    local rotation = inst._mountain_wall_rotation:value()
    if inst._wall_mesh_rotation == rotation then
        return
    end
    local angle = rotation * DEGREES
    local cos, sin = math.cos(angle), math.sin(angle)
    local points = WALL_COLLISION_POINTS[inst._collision_shape]
    local p0, p1 = points[1], points[2]
    local x0, z0 = p0[1] * cos + p0[2] * sin, p0[2] * cos - p0[1] * sin
    local x1, z1 = p1[1] * cos + p1[2] * sin, p1[2] * cos - p1[1] * sin
    inst.Physics:SetTriangleMesh({
        x0, 0, z0, x0, WALL_COLLISION_HEIGHT, z0, x1, 0, z1,
        x1, 0, z1, x0, WALL_COLLISION_HEIGHT, z0, x1, WALL_COLLISION_HEIGHT, z1,
    })
    inst._wall_mesh_rotation = rotation
end

local function UpdateSortWorldOffset(inst)
    inst.AnimState:SetSortWorldOffset(inst._mountain_sort_x:value(), 0, inst._mountain_sort_z:value())
    UpdateWallPhysics(inst)
end

local function UpdateWallState(inst)
    if TheWorld.ismastersim then
        inst._mountain_wall_rotation:set(inst.Transform:GetRotation())
    end
    UpdateSortWorldOffset(inst)
end

local function SetMountainSortDirection(inst, dx, dz)
    local length = math.sqrt(dx * dx + dz * dz)
    if length == 0 then
        return
    end
    dx, dz = dx * HALF_TILE_SCALE / length, dz * HALF_TILE_SCALE / length
    if inst._sort_half ~= nil then
        -- Each corner entity contains only one half of a tile-wide wall.
        local angle = inst.Transform:GetRotation() * DEGREES
        local midpoint = inst._sort_half * HALF_TILE_SCALE * 0.5
        dx, dz = dx + midpoint * math.cos(angle), dz - midpoint * math.sin(angle)
    end
    inst._mountain_sort_x:set(dx)
    inst._mountain_sort_z:set(dz)
    inst._mountain_wall_rotation:set(inst.Transform:GetRotation())
    UpdateSortWorldOffset(inst)
end

local function OnSave(inst, data)
    data.mountain_sort_offset = { x = inst._mountain_sort_x:value(), z = inst._mountain_sort_z:value() }
end

local function OnLoad(inst, data)
    if data ~= nil and data.mountain_sort_offset ~= nil then
        inst._mountain_sort_x:set(data.mountain_sort_offset.x)
        inst._mountain_sort_z:set(data.mountain_sort_offset.z)
    end
    UpdateSortWorldOffset(inst)
end

local function MakeWall(name, animation, overrides, customfn)
    local function fn()
        local inst = CreateEntity()

        -- The engine requires this to be the first tag, before adding AnimState.
        inst:AddTag("can_offset_sort_pos")

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddPhysics()
        inst.entity:AddNetwork()

        inst.Physics:SetMass(0)
        inst.Physics:SetFriction(0)
        inst.Physics:SetRestitution(0)
        inst.Physics:SetCollisionGroup(COLLISION.WORLD)
        inst.Physics:SetCollisionMask(COLLISION.CHARACTERS, COLLISION.GIANTS, COLLISION.ITEMS, COLLISION.FLYERS)

        inst._mountain_sort_x = net_float(inst.GUID, "ms_mountain_wall.sort_x", "mountainsortdirty")
        inst._mountain_sort_z = net_float(inst.GUID, "ms_mountain_wall.sort_z", "mountainsortdirty")
        inst._mountain_wall_rotation = net_float(inst.GUID, "ms_mountain_wall.rotation", "mountainsortdirty")

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

        UpdateWallPhysics(inst)
        inst.entity:SetPristine()

        -- Wait for spawn/load rotation, and reapply client-side sorting on wake.
        inst:DoTaskInTime(0, UpdateWallState)
        inst:ListenForEvent("mountainsortdirty", UpdateSortWorldOffset)
        inst.OnEntityWake = function(inst)
            inst:DoTaskInTime(0, UpdateWallState)
        end

        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("savedrotation")
        inst.SetMountainSortDirection = SetMountainSortDirection
        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        inst.OnLoadPostPass = UpdateWallState
        return inst
    end

    return Prefab(name, fn, assets)
end

local function Wall(inst)
    inst._collision_shape = "wall"
    inst.AnimState:SetSymbolAddColour("wall", 0, 0, 1, 1)
end

local function Right(inst)
    inst._collision_shape = "right"
    inst._sort_half = 1
    inst.AnimState:SetSymbolAddColour("wall_half_right", 0, 0, 1, 1)
end

local function Left(inst)
    inst._collision_shape = "left"
    inst._sort_half = -1
    inst.AnimState:SetSymbolAddColour("wall_half_left", 0, 0, 1, 1)
end

local function Slope(inst)
    inst._collision_shape = "slope"
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
