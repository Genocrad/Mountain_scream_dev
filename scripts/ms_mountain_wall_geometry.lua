-- Local XZ footprint used by collision and the bases of the rendered faces.
local POINTS = {
    wall = { { -2, 0 }, { 2, 0 } },
    right = { { 0, 0 }, { 2, 0 } },
    left = { { -2, 0 }, { 0, 0 } },
    slope = { { -2, 4 }, { 0, 0 }, { 2, 4 } },
}

local HEIGHT = 1536 * 0.0033 * 4
local SLOPE_APEX = { 0, HEIGHT, 4 }
local SLOPE_TRIANGLES = {}
for i = 1, #POINTS.slope - 1 do
    local a, b = POINTS.slope[i], POINTS.slope[i + 1]
    SLOPE_TRIANGLES[i] = { { a[1], 0, a[2] }, { b[1], 0, b[2] }, SLOPE_APEX }
end

local RADII = {}
for shape, points in pairs(POINTS) do
    local radius_squared = 0
    for _, point in ipairs(points) do
        radius_squared = math.max(radius_squared, point[1] * point[1] + point[2] * point[2])
    end
    RADII[shape] = math.sqrt(radius_squared)
end

local function RotatePoint(x, z, angle)
    local cos, sin = math.cos(angle), math.sin(angle)
    return x * cos + z * sin, z * cos - x * sin
end

return {
    POINTS = POINTS,
    RADII = RADII,
    RotatePoint = RotatePoint,
    HEIGHT = HEIGHT,
    SLOPE_APEX = SLOPE_APEX,
    SLOPE_TRIANGLES = SLOPE_TRIANGLES,
    -- Sort each slope face at a separate point on the rear base.
    SLOPE_SORT_POINTS = { { -0.1, 4 }, { 0.1, 4 } },
}
