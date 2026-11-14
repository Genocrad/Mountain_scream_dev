local MountainLighting = {}

local REGION_REFRESH_INTERVAL = 1

local PHASE_COLOUR_SETS =
{
    default =
    {
        day = { colour = Point(255 / 255, 255 / 255, 230 / 255), time = 10 },
        dusk = { colour = Point(155 / 255, 120 / 255, 80 / 255), time = 4 },
        night = { colour = Point(0, 0, 0), time = 6 },
        fullmoon = { colour = Point(84 / 255, 122 / 255, 156 / 255), time = 4 },
    },
    highmountain =
    {
        day = { colour = Point(244 / 255, 248 / 255, 255 / 255), time = 10 },
        dusk = { colour = Point(145 / 255, 158 / 255, 180 / 255), time = 4 },
        night = { colour = Point(0, 0, 0), time = 6 },
        fullmoon = { colour = Point(84 / 255, 122 / 255, 156 / 255), time = 4 },
    },
}

function MountainLighting.GetPhaseColours(level)
    return (level == 4 or level == 5) and PHASE_COLOUR_SETS.highmountain or PHASE_COLOUR_SETS.default
end

function MountainLighting.IsMountainWorld(world)
    return world ~= nil and world:HasTag("mountain_scream_dungeons")
end

function MountainLighting.GetPhase(world)
    local state = world ~= nil and world.state or nil
    local phase = state ~= nil and state.cavephase or nil
    if phase == "night" and state.iscavefullmoon then
        return "fullmoon"
    end
    return PHASE_COLOUR_SETS.default[phase] ~= nil and phase or nil
end

function MountainLighting.GetLocalMountainPlayer(world)
    local player = ThePlayer
    if not MountainLighting.IsMountainWorld(world) or player == nil or not player:IsValid() then
        return nil
    end
    local tracker = player.components.dungeonplayertracker
    local environment = player.components.dungeonplayerenvironment
    return tracker ~= nil and tracker:IsInMsOverWorld()
        and (environment == nil or not environment._clientinactive) and player or nil
end

local function GetPhaseLightValue(colours, phase)
    local params = colours[phase]
    if params == nil then
        return 0
    end
    local colour = params.colour
    return 0.2126 * colour.x + 0.7152 * colour.y + 0.0722 * colour.z
end

local function GetCurrentLightValue(state, now)
    local k = state.duration > 0 and math.min((now - state.starttime) / state.duration, 1) or 1
    return state.from + (state.target - state.from) * k
end

local function OnPhaseChanged(world)
    local state = world._ms_ambientlight
    local phase = MountainLighting.GetPhase(world)
    if phase ~= state.phase then
        local now = GetTime()
        for colours, light in pairs(state.lights) do
            light.from = state.phase ~= nil and GetCurrentLightValue(light, now) or GetPhaseLightValue(colours, phase)
            light.target = GetPhaseLightValue(colours, phase)
            light.starttime = now
            light.duration = phase ~= nil and colours[phase].time or 0
        end
        state.phase = phase
    end
end

function MountainLighting.Initialize(world)
    if world._ms_ambientlight == nil then
        local phase = MountainLighting.GetPhase(world)
        local now = GetTime()
        local lights = {}
        for _, colours in pairs(PHASE_COLOUR_SETS) do
            local value = GetPhaseLightValue(colours, phase)
            lights[colours] =
            {
                from = value,
                target = value,
                starttime = now,
                duration = 0,
            }
        end
        world._ms_ambientlight =
        {
            phase = phase,
            lights = lights,
            regions = {},
            regioncount = 0,
        }
        world:WatchWorldState("cavephase", OnPhaseChanged)
        world:WatchWorldState("iscavefullmoon", OnPhaseChanged)
    end
    return world._ms_ambientlight
end

local function GetAmbientValue(world, level)
    if not MountainLighting.IsMountainWorld(world) or level == nil or level > TUNING.MS_CAVES_START then
        return 0
    end
    local state = MountainLighting.Initialize(world)
    return GetCurrentLightValue(state.lights[MountainLighting.GetPhaseColours(level)], GetTime())
end

local function RefreshRegions(state, overwatch)
    local now = GetTime()
    -- Share the floor bounds between all light queries.
    if state.overwatch ~= overwatch or state.boundstime == nil
        or now - state.boundstime >= REGION_REFRESH_INTERVAL then
        state.overwatch = overwatch
        state.boundstime = now
        state.regioncount = 0
        if overwatch:IsLevelDataReady() then
            state.regioncount = #overwatch._map_points_level_x:value()
            for level = 1, state.regioncount do
                local region = state.regions[level]
                if region == nil then
                    region = {}
                    state.regions[level] = region
                end
                region.x, region.z = overwatch:GetPointForLevel(level)
                region.minx, region.maxx, region.minz, region.maxz = overwatch:GetBoundsForLevel(level)
            end
        end
    end
end

local function GetMountainLevelAtPoint(world, x, z)
    local state = world._ms_ambientlight
    local overwatch = world.net ~= nil and world.net.components.dungeonmapoverwatch or nil
    if overwatch == nil then
        return nil
    end
    RefreshRegions(state, overwatch)

    -- Match GetNearestLevel: select the nearest floor first, then its bounds.
    local nearest, best = nil, math.huge
    for level = 1, state.regioncount do
        local region = state.regions[level]
        if region.x ~= nil and region.z ~= nil then
            local dx, dz = x - region.x, z - region.z
            local distance = dx * dx + dz * dz
            if distance < best then
                nearest, best = level, distance
            end
        end
    end
    if nearest ~= nil and nearest <= TUNING.MS_CAVES_START then
        local region = state.regions[nearest]
        if region.minx ~= nil and x > region.minx and x < region.maxx
            and z > region.minz and z < region.maxz then
            return nearest
        end
    end
    return nil
end

function MountainLighting.GetAmbientValueAtPoint(world, x, y, z)
    if not MountainLighting.IsMountainWorld(world) then
        return 0
    end
    local state = MountainLighting.Initialize(world)
    local now = GetTime()
    -- Skip region queries while every lighting profile is dark.
    for _, light in pairs(state.lights) do
        if GetCurrentLightValue(light, now) > 0 then
            local level = GetMountainLevelAtPoint(world, x, z)
            return level ~= nil
                and GetCurrentLightValue(state.lights[MountainLighting.GetPhaseColours(level)], now) or 0
        end
    end
    return 0
end

function MountainLighting.GetAmbientValueForEntity(inst)
    local tracker = inst.components.dungeonplayertracker
    if tracker ~= nil then
        return tracker:IsInMsOverWorld() and GetAmbientValue(TheWorld, tracker:GetLevel()) or 0
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    return MountainLighting.GetAmbientValueAtPoint(TheWorld, x, y, z)
end

MountainLighting.PHASE_COLOURS = PHASE_COLOUR_SETS.default
MountainLighting.PHASE_COLOUR_SETS = PHASE_COLOUR_SETS

return MountainLighting
