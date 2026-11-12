-- Client-side see-through for mountain walls, in two levels
-- (mountain_vertical_shader.ps). Level 1 is always on: walls too near the
-- camera fade out completely. Level 2 runs while a wall hides the
-- local player: walls open in a camera-facing ellipse centred on the player.
-- Project that screen ellipse onto a camera-facing vertical plane at the player.
-- Its depth extends behind that plane most at the centre and tapers at the edge.
-- Props mounted on walls fade the same way. Lua decides whether the
-- player is hidden and where they stand.
local WALL_GEOMETRY = require("ms_mountain_wall_geometry")
local SetSlopeView = require("ms_slope_shader").SetView
local WALL_HEIGHT = WALL_GEOMETRY.HEIGHT
local BODY_HEIGHT = 1.5 -- hiding is tested from mid-body
local BODY_HALF_WIDTH = 0.45
-- Keep the ellipse height in sync with the .vs, and its shape with the .ps.
local REVEAL_HEIGHT, REVEAL_CORE = 1.5, 0.5
local REVEAL_RADIUS_X, REVEAL_RADIUS_Y = 18, 12
-- Rounded extension behind the projected vertical plane, measured in view depth.
-- Keep a soft transition on either side of this boundary (world units).
local REVEAL_DEPTH, REVEAL_DEPTH_SOFT = 4, 1
local NEAR_CENTRE_START, NEAR_EDGE_START, NEAR_SOFT = 4, 4, 0.3
-- Opacity left on a fully faded prop, for level 1 and level 2.
local NEAR_PROP_KEEP, PROP_KEEP = 0, 0.5
local FADE_IN, FADE_OUT = 0.15, 0.4
-- Keep the view open briefly, so walking past a corner does not flicker.
local HOLD = 0.3

-- Precompute triangle edges once. Slope sight tests allocate no per-frame data.
local slope_triangles = {}
for i, triangle in ipairs(WALL_GEOMETRY.SLOPE_TRIANGLES) do
    local a, b, c = triangle[1], triangle[2], triangle[3]
    slope_triangles[i] = {
        a[1], a[2], a[3],
        b[1] - a[1], b[2] - a[2], b[3] - a[3],
        c[1] - a[1], c[2] - a[2], c[3] - a[3],
    }
end

local walls = {}
local props = {}
local task
local last_time
local hidden_until = 0
local player
local x, z
local strength = 0

local function SmoothStep(edge0, edge1, value)
    local t = math.clamp((value - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)
end

local function SegmentsCross(ax, az, bx, bz, cx, cz, dx, dz)
    local rx, rz, sx, sz = bx - ax, bz - az, dx - cx, dz - cz
    local denominator = rx * sz - rz * sx
    if math.abs(denominator) < 1e-6 then
        return false
    end
    local qx, qz = cx - ax, cz - az
    local t = (qx * sz - qz * sx) / denominator
    local u = (qx * rz - qz * rx) / denominator
    return t >= 0 and t <= 1 and u >= 0 and u <= 1
end

local function SegmentHitsTriangle(ax, ay, az, bx, by, bz, triangle)
    local dx, dy, dz = bx - ax, by - ay, bz - az
    local e1x, e1y, e1z = triangle[4], triangle[5], triangle[6]
    local e2x, e2y, e2z = triangle[7], triangle[8], triangle[9]
    local px, py, pz = dy * e2z - dz * e2y, dz * e2x - dx * e2z, dx * e2y - dy * e2x
    local determinant = e1x * px + e1y * py + e1z * pz
    if math.abs(determinant) < 1e-6 then
        return false
    end
    local tx, ty, tz = ax - triangle[1], ay - triangle[2], az - triangle[3]
    local u = (tx * px + ty * py + tz * pz) / determinant
    if u < 0 or u > 1 then
        return false
    end
    local qx, qy, qz = ty * e1z - tz * e1y, tz * e1x - tx * e1z, tx * e1y - ty * e1x
    local v = (dx * qx + dy * qy + dz * qz) / determinant
    if v < 0 or u + v > 1 then
        return false
    end
    local t = (e2x * qx + e2y * qy + e2z * qz) / determinant
    return t >= 0 and t <= 1
end

local function SlopeHidesPlayer(inst, eye, px, py, pz, dx, dz, wx, wy, wz)
    local inverse_angle = -inst.Transform:GetRotation() * DEGREES
    local ex, ez = WALL_GEOMETRY.RotatePoint(eye.x - wx, eye.z - wz, inverse_angle)
    local ey = eye.y - wy
    for side = -1, 1 do
        local ox, oz = WALL_GEOMETRY.RotatePoint(
            px - dz * side * BODY_HALF_WIDTH - wx,
            pz + dx * side * BODY_HALF_WIDTH - wz, inverse_angle)
        for _, triangle in ipairs(slope_triangles) do
            if SegmentHitsTriangle(ox, py + BODY_HEIGHT - wy, oz, ex, ey, ez, triangle) then
                return true
            end
        end
    end
    return false
end

-- Straight walls use their vertical footprint. Slopes use their actual tilted
-- triangles: a sight line can pass above the narrowing sides without hiding.
local function IsHidden(eye, px, py, pz)
    local dx, dz = eye.x - px, eye.z - pz
    local distance = math.sqrt(dx * dx + dz * dz)
    local clearance = WALL_HEIGHT - py - BODY_HEIGHT
    if distance >= 0.01 then
        dx, dz = dx / distance, dz / distance
    else
        dx, dz = 0, 1
    end
    local rise = eye.y - py - BODY_HEIGHT
    local reach = rise > clearance and distance * clearance / rise or distance
    for inst in pairs(walls) do
        local shape = inst._collision_shape
        local points = WALL_GEOMETRY.POINTS[shape]
        local wx, wy, wz = inst.Transform:GetWorldPosition()
        local radius = WALL_GEOMETRY.RADII[shape]
        if shape == "slope" then
            if (wx - px) ^ 2 + (wz - pz) ^ 2 <= (distance + radius + BODY_HALF_WIDTH) ^ 2
                and SlopeHidesPlayer(inst, eye, px, py, pz, dx, dz, wx, wy, wz) then
                return true
            end
        elseif points ~= nil and distance >= 0.01 and clearance > 0
            and (wx - px) ^ 2 + (wz - pz) ^ 2 <= (reach + radius + BODY_HALF_WIDTH) ^ 2 then
            local angle = inst.Transform:GetRotation() * DEGREES
            local ax, az = WALL_GEOMETRY.RotatePoint(points[1][1], points[1][2], angle)
            ax, az = wx + ax, wz + az
            for i = 2, #points do
                local bx, bz = WALL_GEOMETRY.RotatePoint(points[i][1], points[i][2], angle)
                bx, bz = wx + bx, wz + bz
                for side = -1, 1 do
                    local ox, oz = px - dz * side * BODY_HALF_WIDTH, pz + dx * side * BODY_HALF_WIDTH
                    if SegmentsCross(ax, az, bx, bz, ox, oz, ox + dx * reach, oz + dz * reach) then
                        return true
                    end
                end
                ax, az = bx, bz
            end
        end
    end
    return false
end

local function ApplyView(inst)
    -- FLOAT_PARAMS = player ground XZ, 1 + player-hidden strength. 1 keeps
    -- level 1 on; other users of the shader leave 0 and stay untouched.
    -- Mountain levels all use ground Y=0; view/projection matrices supply the
    -- screen position and view depth in the shader.
    -- SetErosionParams is NOT a data channel: it enables native erosion and
    -- overrides the custom effect, potentially hiding the entire wall.
    inst.AnimState:SetFloatParams(x or 0, z or 0, 1 + strength)
    if inst._slope_faces ~= nil then
        local wx, _, wz = inst.Transform:GetWorldPosition()
        for _, face in ipairs(inst._slope_faces) do
            SetSlopeView(face, (x or 0) - wx, (z or 0) - wz, strength)
        end
    end
end

local function Project(camera, px, py, pz)
    local sx, sy = TheSim:GetScreenPos(px, py, pz)
    local eye, dir = camera.camera_pos, camera.camera_dir
    return sx, sy, (px - eye.x) * dir.x + (py - eye.y) * dir.y + (pz - eye.z) * dir.z
end

local function SetPropAlpha(inst, alpha)
    if props[inst] ~= alpha then
        props[inst] = alpha
        inst.AnimState:OverrideMultColour(1, 1, 1, alpha)
    end
end

-- The shader's two levels, evaluated once per prop at its origin.
local function UpdateProps(camera)
    local screen_width, screen_height = TheSim:GetScreenSize()
    local half_height = screen_height * 0.5
    local eye, dir = camera.camera_pos, camera.camera_dir
    local centre_x, centre_y, centre_depth, world_per_pixel
    local plane_distance
    if strength > 0 then
        centre_x, centre_y, centre_depth = Project(camera, x, REVEAL_HEIGHT, z)
        -- The plane is vertical in world space, with the camera's horizontal
        -- forward direction as its normal. Its XZ position follows the player.
        plane_distance = (x - eye.x) * dir.x + (z - eye.z) * dir.z
        if centre_x ~= nil and centre_depth > 0.001 and plane_distance > 0.001 then
            world_per_pixel = 2 * math.tan(camera.fov * 0.5 * DEGREES) * centre_depth / screen_height
        end
    end
    for inst in pairs(props) do
        local px, py, pz = inst.Transform:GetWorldPosition()
        local sx, sy, depth = Project(camera, px, py, pz)
        local alpha = 1
        if sx ~= nil then
            local from_centre = math.sqrt((sx - screen_width * 0.5) ^ 2 + (sy - half_height) ^ 2) / half_height
            local fade_start = Lerp(NEAR_CENTRE_START, NEAR_EDGE_START, SmoothStep(0, 1, from_centre))
            -- The configured distance is where fading starts, not its midpoint.
            local limit = fade_start / (1 + NEAR_SOFT)
            local near = 1 - SmoothStep(limit * (1 - NEAR_SOFT), fade_start, depth)
            alpha = 1 - near * (1 - NEAR_PROP_KEEP)
            if world_per_pixel ~= nil and depth > 0 then
                -- Intersect this prop's camera ray with the player's vertical
                -- plane. Normalize by view depth to match the shader's ray.
                local plane_ray = ((px - eye.x) * dir.x + (pz - eye.z) * dir.z) / depth
                if plane_ray > 0.001 then
                    local plane_depth = plane_distance / plane_ray
                    local offset_x = (sx - centre_x) * world_per_pixel / REVEAL_RADIUS_X
                    local offset_y = (sy - centre_y) * world_per_pixel / REVEAL_RADIUS_Y
                    local spread = math.sqrt(offset_x * offset_x + offset_y * offset_y)
                    local reveal = 1 - SmoothStep(REVEAL_CORE, 1, spread)
                    local radial = math.min(spread, 1)
                    local depth_limit = plane_depth + REVEAL_DEPTH * math.sqrt(math.max(0, 1 - radial * radial))
                    local depth_fade = 1 - SmoothStep(depth_limit - REVEAL_DEPTH_SOFT, depth_limit + REVEAL_DEPTH_SOFT, depth)
                    local see = strength * reveal * depth_fade
                    alpha = math.min(alpha, 1 - see * (1 - PROP_KEEP))
                end
            end
        end
        SetPropAlpha(inst, alpha)
    end
end

local function Update()
    local now = GetTime()
    local dt = last_time ~= nil and math.max(0, now - last_time) or 0
    last_time = now
    local old_x, old_z, old_strength = x, z, strength
    local camera = TheCamera
    local ready = camera ~= nil and camera.camera_pos ~= nil and camera.camera_dir ~= nil
    local target = 0
    if ready and ThePlayer ~= nil and ThePlayer:IsValid() then
        local px, py, pz = ThePlayer.Transform:GetWorldPosition()
        if player ~= ThePlayer or x == nil or (px - x) ^ 2 + (pz - z) ^ 2 > 8 ^ 2 then
            -- Never carry an open view across a teleport or load.
            strength, hidden_until = 0, 0
        end
        player = ThePlayer
        x, z = px, pz
        if IsHidden(camera.camera_pos, px, py, pz) then
            hidden_until = now + HOLD
        end
        target = now < hidden_until and 1 or 0
    else
        player = nil
    end
    if strength < target then
        strength = math.min(target, strength + dt / FADE_IN)
    else
        strength = math.max(target, strength - dt / FADE_OUT)
    end

    if strength ~= old_strength or (strength > 0 and (x ~= old_x or z ~= old_z)) then
        for inst in pairs(walls) do
            ApplyView(inst)
        end
    end
    if ready and next(props) ~= nil then
        UpdateProps(camera)
    end
end

local function Start()
    if task == nil then
        task = TheWorld:DoPeriodicTask(0, Update)
    end
end

local function StopIfIdle()
    if task ~= nil and next(walls) == nil and next(props) == nil then
        task:Cancel()
        task = nil
        last_time, player = nil, nil
        x, z = nil, nil
        strength, hidden_until = 0, 0
    end
end

local function OnWake(inst)
    walls[inst] = true
    ApplyView(inst)
    Start()
end

local function OnSleep(inst)
    walls[inst] = nil
    StopIfIdle()
end

local function OnPropWake(inst)
    if props[inst] == nil then
        props[inst] = 1
    end
    Start()
end

local function OnPropSleep(inst)
    if props[inst] ~= nil then
        SetPropAlpha(inst, 1)
        props[inst] = nil
    end
    StopIfIdle()
end

local function Register(inst)
    if TheNet:IsDedicated() then
        return
    end
    ApplyView(inst)
    inst:ListenForEvent("entitywake", OnWake)
    inst:ListenForEvent("entitysleep", OnSleep)
    inst:ListenForEvent("onremove", OnSleep)
    if not inst:IsAsleep() then
        OnWake(inst)
    end
end

-- Props mounted on wall faces. Their shader must apply the mult colour.
local function RegisterProp(inst)
    if TheNet:IsDedicated() then
        return
    end
    inst:ListenForEvent("entitywake", OnPropWake)
    inst:ListenForEvent("entitysleep", OnPropSleep)
    inst:ListenForEvent("onremove", OnPropSleep)
    if not inst:IsAsleep() then
        OnPropWake(inst)
    end
end

return { Register = Register, RegisterProp = RegisterProp, Refresh = ApplyView }
