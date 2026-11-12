local WallOcclusion = require("ms_wall_occlusion")
local RegisterWallOcclusion = WallOcclusion.Register
local WallGeometry = require("ms_mountain_wall_geometry")

local assets = {
    Asset("ANIM", "anim/ms_mountain_wall.zip"),
    Asset("SHADER", "shaders/mountain_slope_shader.ksh"),

    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_high_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_snow_mountain_build.zip"),

    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_corner_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_corner_high_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_left_corner_snow_mountain_build.zip"),

    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_right_corner_snow_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_right_corner_high_mountain_build.zip"),
    Asset("ANIM", "anim/ms_mountain_wall_variants/ms_mountain_wall_idle_right_corner_build.zip"),
}

local WALL_COLLISION_HEIGHT = 4

local CORNER_SORT_ALONG_WALL = 2
local CORNER_SORT_INTO_MOUNTAIN = 1.9

local function UpdateWallPhysics(inst)
    -- Bake wall rotation into the static mesh vertices on both server and clients.
    local rotation = inst._mountain_wall_rotation:value()
    if inst._wall_mesh_rotation == rotation then
        return
    end
    local angle = rotation * DEGREES
    local points = WallGeometry.POINTS[inst._collision_shape]
    local mesh = {}
    for i = 1, #points - 1 do
        local p0, p1 = points[i], points[i + 1]
        local x0, z0 = WallGeometry.RotatePoint(p0[1], p0[2], angle)
        local x1, z1 = WallGeometry.RotatePoint(p1[1], p1[2], angle)
        local offset = #mesh
        mesh[offset + 1], mesh[offset + 2], mesh[offset + 3] = x0, 0, z0
        mesh[offset + 4], mesh[offset + 5], mesh[offset + 6] = x0, WALL_COLLISION_HEIGHT, z0
        mesh[offset + 7], mesh[offset + 8], mesh[offset + 9] = x1, 0, z1
        mesh[offset + 10], mesh[offset + 11], mesh[offset + 12] = x1, 0, z1
        mesh[offset + 13], mesh[offset + 14], mesh[offset + 15] = x0, WALL_COLLISION_HEIGHT, z0
        mesh[offset + 16], mesh[offset + 17], mesh[offset + 18] = x1, WALL_COLLISION_HEIGHT, z1
    end
    inst.Physics:SetTriangleMesh(mesh)
    inst._wall_mesh_rotation = rotation
end

local function UpdateSortWorldOffset(inst)
    local dx, dz = inst._mountain_sort_x:value(), inst._mountain_sort_z:value()
    if inst._collision_shape == "slope" then
        -- Both faces use the same parent origin. Only their engine sort points
        -- differ; the shared edge must go through identical vertex transforms.
        local angle = inst._mountain_wall_rotation:value() * DEGREES
        if inst._slope_faces ~= nil then
            local wx, _, wz = inst.Transform:GetWorldPosition()
            local render_angle = inst.Transform:GetRotation() * DEGREES
            for i, face in ipairs(inst._slope_faces) do
                local target = WallGeometry.SLOPE_SORT_POINTS[i]
                local x, z = WallGeometry.RotatePoint(target[1], target[2], angle)
                face.AnimState:SetSortWorldOffset(x, 0, z)
                -- Like Porkland's waterfall: pass the actual entity origin and
                -- yaw explicitly; never infer them from a native draw matrix.
                face.AnimState:SetFloatParams(wx, wz, render_angle)
            end
            WallOcclusion.Refresh(inst)
        end
        dx, dz = 0, 0
    end
    inst.AnimState:SetSortWorldOffset(dx, 0, dz)
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
    local retreat = inst._sort_half ~= nil and CORNER_SORT_INTO_MOUNTAIN or HALF_TILE_SCALE
    dx, dz = dx * retreat / length, dz * retreat / length
    if inst._sort_half ~= nil then
        -- Move into this half-wall along its length, then toward the mountain.
        local angle = inst.Transform:GetRotation() * DEGREES
        local along_wall = inst._sort_half * CORNER_SORT_ALONG_WALL
        dx, dz = dx + along_wall * math.cos(angle), dz - along_wall * math.sin(angle)
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

local function ConfigureWallAnimation(inst, animation, overrides)
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
end

local function CreateSlopeFaces(inst, animation, overrides)
    if TheNet:IsDedicated() then
        return
    end

    inst._slope_faces = {}
    for i, side in ipairs({ "left", "right" }) do
        local face = CreateEntity()
        -- Each local-only wall face needs an independent engine sort position.
        face:AddTag("can_offset_sort_pos")
        face.entity:AddTransform()
        face.entity:AddAnimState()
        face.entity:SetCanSleep(TheWorld.ismastersim)
        face:AddTag("FX")
        face:AddTag("DECOR")
        face:AddTag("NOCLICK")
        face.persists = false

        local symbol = "slope_face_" .. side
        ConfigureWallAnimation(face, animation:gsub("^idle", symbol), overrides)
        face.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/mountain_slope_shader.ksh"))

        -- B/D vertices and frame bounds match exactly in both builds. Keep
        -- the children at the same origin, with no per-face rotation or scale.
        inst:AddChild(face)
        inst._slope_faces[i] = face
    end
end

local function MakeWall(name, animation, overrides, shape)
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
        inst._collision_shape = shape
        if shape == "slope" then
            -- The networked parent owns physics/save data; only its two local
            -- children render the sloping triangles with separate sort points.
            CreateSlopeFaces(inst, animation, overrides)
        else
            ConfigureWallAnimation(inst, animation, overrides)
            inst.AnimState:SetSymbolAddColour(overrides[1].symbol, 0, 0, 1, 1)
            if shape == "right" then
                inst._sort_half = 1
            elseif shape == "left" then
                inst._sort_half = -1
            end
        end
        -- Register only the logical wall; its view parameters reach both faces.
        RegisterWallOcclusion(inst)

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

return MakeWall("ms_mountain_wall", "idle", {
        { symbol = "wall", build = "ms_mountain_wall_idle_build" },
    }, "wall"),
    MakeWall("ms_mountain_corner_wall_right", "idle_right_corner", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_right_corner_build" },
    }, "right"),
    MakeWall("ms_mountain_corner_wall_left", "idle_left_corner", {
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_corner_build" },
    }, "left"),
    MakeWall("ms_mountain_slope", "idle", {
        { symbol = "wall", build = "ms_mountain_wall_idle_build" },
    }, "slope"),
    MakeWall("ms_mountain_wall_snow", "idle_snow_mountain", {
        { symbol = "wall", build = "ms_mountain_wall_idle_snow_mountain_build" },
    }, "wall"),
    MakeWall("ms_mountain_corner_wall_right_snow", "idle_right_corner_snow_mountain", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_right_corner_snow_mountain_build" },
    }, "right"),
    MakeWall("ms_mountain_corner_wall_left_snow", "idle_left_corner_snow_mountain", {
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_corner_snow_mountain_build" },
    }, "left"),
    MakeWall("ms_mountain_slope_snow", "idle_snow_mountain", {
        { symbol = "wall", build = "ms_mountain_wall_idle_snow_mountain_build" },
    }, "slope"),
    MakeWall("ms_mountain_wall_high", "idle_high_mountain", {
        { symbol = "wall", build = "ms_mountain_wall_idle_high_mountain_build" },
    }, "wall"),
    MakeWall("ms_mountain_corner_wall_right_high", "idle_right_corner_high_mountain", {
        { symbol = "wall_half_right", build = "ms_mountain_wall_idle_right_corner_high_mountain_build" },
    }, "right"),
    MakeWall("ms_mountain_corner_wall_left_high", "idle_left_corner_high_mountain", {
        { symbol = "wall_half_left", build = "ms_mountain_wall_idle_left_corner_high_mountain_build" },
    }, "left"),
    MakeWall("ms_mountain_slope_high", "idle_high_mountain", {
        { symbol = "wall", build = "ms_mountain_wall_idle_high_mountain_build" },
    }, "slope")
