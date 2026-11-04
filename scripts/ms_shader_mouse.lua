-- Simplified picking for clickable_vertical_shader and rotation_vertical_shader.
-- Keep these two column replacements in sync with their .vs files.
local registered = setmetatable({}, { __mode = "k" })
local active = {}
local installed = false
local EPSILON = 1e-6
local PROBE = 150

local function Length(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

local function Depth(x, y, z, camera)
    local pos, dir = camera.camera_pos, camera.camera_dir
    return (x - pos.x) * dir.x + (y - pos.y) * dir.y + (z - pos.z) * dir.z
end

local function Project(point, x, y, z, camera, sim)
    local depth = Depth(x, y, z, camera)
    if depth <= EPSILON then
        return false
    end
    point.x, point.y = sim:GetScreenPos(x, y, z)
    point.depth = depth
    return point.x ~= nil and point.y ~= nil
end

local function TriangleDepth(x, y, a, b, c)
    local denominator = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
    if math.abs(denominator) <= EPSILON then
        return
    end
    local u = ((b.y - c.y) * (x - c.x) + (c.x - b.x) * (y - c.y)) / denominator
    local v = ((c.y - a.y) * (x - c.x) + (a.x - c.x) * (y - c.y)) / denominator
    local w = 1 - u - v
    if u >= -EPSILON and v >= -EPSILON and w >= -EPSILON then
        -- Perspective-correct depth at the mouse, rather than entity-center depth.
        return 1 / (u / a.depth + v / b.depth + w / c.depth)
    end
end

local function HitDepth(inst, entry, mouse_x, mouse_y, camera, sim)
    local anim = inst.AnimState
    local x1, y1, x2, y2 = anim:GetVisualBB()
    if x1 == nil or y1 == nil or x2 == nil or y2 == nil
        or math.abs(x2 - x1) <= EPSILON or math.abs(y2 - y1) <= EPSILON then
        return
    end

    -- Empty-symbol offsets expose the native animation's model matrix, including
    -- its orientation, facing and scales, before our vertex shader replaces columns.
    -- Large probes avoid subtracting nearly identical floats far from world origin.
    local ox, oy, oz = anim:GetSymbolPosition("", 0, 0, 0)
    local xx, xy, xz = anim:GetSymbolPosition("", PROBE, 0, 0)
    local yx, yy, yz = anim:GetSymbolPosition("", 0, PROBE, 0)
    xx, xy, xz = (xx - ox) / PROBE, (xy - oy) / PROBE, (xz - oz) / PROBE
    yx, yy, yz = (yx - ox) / PROBE, (yy - oy) / PROBE, (yz - oz) / PROBE

    local tx, ty, tz = inst.Transform:GetWorldPosition()
    local sx, sy, sz = inst.entity:LocalToWorldSpace(1, 0, 0)
    sx = Length(sx - tx, sy - ty, sz - tz)
    local ux, uy, uz = inst.entity:LocalToWorldSpace(0, 1, 0)
    sy = Length(ux - tx, uy - ty, uz - tz)
    if sx <= EPSILON or sy <= EPSILON then
        return
    end

    -- GetVisualBB already includes AnimState:SetScale (and the pixel/world ratio),
    -- but not Transform:SetScale. Recover raw vertex bounds before applying the
    -- shader matrix, so neither scale is accidentally applied twice. Reversed
    -- bounds retain the sign of an AnimState mirror.
    local anim_sx = Length(xx, xy, xz) / sx * (x2 < x1 and -1 or 1)
    local anim_sy = Length(yx, yy, yz) / sy * (y2 < y1 and -1 or 1)
    if math.abs(anim_sx) <= EPSILON or math.abs(anim_sy) <= EPSILON then
        return
    end
    x1, x2 = x1 / anim_sx, x2 / anim_sx
    y1, y2 = y1 / anim_sy, y2 / anim_sy

    if entry.kind == "clickable" then
        local zx, zy, zz = anim:GetSymbolPosition("", 0, 0, PROBE)
        yx = (zx - ox) / PROBE
        yy = (zy - oy) / PROBE * -0.0033
        yz = (zz - oz) / PROBE
    else
        yx, yy, yz = yx >= 0.2 and 1 or 0, -0.005, yz >= 0.2 and 1 or 0
    end

    local a, b, c, d = entry[1], entry[2], entry[3], entry[4]
    if not Project(a, ox + xx * x1 + yx * y1, oy + xy * x1 + yy * y1, oz + xz * x1 + yz * y1, camera, sim)
        or not Project(b, ox + xx * x2 + yx * y1, oy + xy * x2 + yy * y1, oz + xz * x2 + yz * y1, camera, sim)
        or not Project(c, ox + xx * x2 + yx * y2, oy + xy * x2 + yy * y2, oz + xz * x2 + yz * y2, camera, sim)
        or not Project(d, ox + xx * x1 + yx * y2, oy + xy * x1 + yy * y2, oz + xz * x1 + yz * y2, camera, sim) then
        return
    end
    if mouse_x < math.min(a.x, b.x, c.x, d.x) or mouse_x > math.max(a.x, b.x, c.x, d.x)
        or mouse_y < math.min(a.y, b.y, c.y, d.y) or mouse_y > math.max(a.y, b.y, c.y, d.y) then
        return
    end
    return TriangleDepth(mouse_x, mouse_y, a, b, c) or TriangleDepth(mouse_x, mouse_y, a, c, d)
end

local function OnWake(inst)
    active[inst] = registered[inst]
end

local function OnSleep(inst)
    active[inst] = nil
end

local function OnRemove(inst)
    active[inst], registered[inst] = nil, nil
end

local function Install()
    if installed then
        return
    end
    installed = true
    local original = Sim.GetEntitiesAtScreenPoint
    Sim.GetEntitiesAtScreenPoint = function(sim, mouse_x, mouse_y, ...)
        -- Exactly one native picking query; never query again for individual entities.
        local entities = original(sim, mouse_x, mouse_y, ...)
        local camera = TheCamera
        if next(active) == nil or camera == nil or camera.camera_pos == nil or camera.camera_dir == nil
            or (entities[1] ~= nil and entities[1].UITransform ~= nil) then
            return entities
        end

        for i = #entities, 1, -1 do
            if registered[entities[i]] ~= nil then
                table.remove(entities, i)
            end
        end

        local hits = {}
        for inst, entry in pairs(active) do
            if not inst:IsValid() then
                OnRemove(inst)
            elseif inst.entity:IsVisible() and not inst:HasAnyTag("NOCLICK", "INLIMBO") then
                local _, _, _, alpha = inst.AnimState:GetMultColour()
                if alpha > 0 then
                    local depth = HitDepth(inst, entry, mouse_x, mouse_y, camera, sim)
                    if depth ~= nil then
                        hits[#hits + 1] = { inst = inst, depth = depth }
                    end
                end
            end
        end
        table.sort(hits, function(a, b)
            return a.depth < b.depth or (a.depth == b.depth and a.inst.GUID < b.inst.GUID)
        end)
        -- Preserve the native ordering of ordinary entities and all UI priorities.
        local start = 1
        for _, hit in ipairs(hits) do
            local index = #entities + 1
            for i = start, #entities do
                local other = entities[i]
                if other.UITransform == nil and other.Transform ~= nil then
                    local x, y, z = other.Transform:GetWorldPosition()
                    if Depth(x, y, z, camera) > hit.depth then
                        index = i
                        break
                    end
                end
            end
            table.insert(entities, index, hit.inst)
            start = index + 1
        end
        return entities
    end
end

local function Register(inst, kind)
    if TheNet:IsDedicated() or registered[inst] ~= nil then
        return
    end
    Install()
    registered[inst] = { kind = kind, {}, {}, {}, {} }
    if not inst:IsAsleep() then
        OnWake(inst)
    end
    inst:ListenForEvent("entitywake", OnWake)
    inst:ListenForEvent("entitysleep", OnSleep)
    inst:ListenForEvent("onremove", OnRemove)
end

return { Register = Register }
