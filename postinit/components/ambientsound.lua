local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local CLOUD_SOUND = "ms_mountain_wind/ambience/wind"
local CLOUD_HANDLE = "ms_mountain_clouds"
local CLOUD_PARAMETER = "cloud_proximity"
local CLOUD_HALF_TILES = 5
local CLOUD_DENSITY_SCALE = 2 / 121
local CLOUD_MAX_VOLUME = 1.5
local CLOUD_FADE_RATE = 1
local CLOUD_PROXIMITY_RATE = 1

local function GetCloudProximity(map, x, y, z)
    local tile_x, tile_y = map:GetTileCoordsAtPoint(x, y, z)
    local count = 0
    for dx = -CLOUD_HALF_TILES, CLOUD_HALF_TILES do
        for dy = -CLOUD_HALF_TILES, CLOUD_HALF_TILES do
            local tile = map:GetTile(tile_x + dx, tile_y + dy)
            -- Mountain cloud tiles use their own range, outside native
            -- ImpassableTiles. Both cloud colours border the playable land.
            if tile ~= nil and (tile == WORLD_TILES.CLOUDS_WHITE
                or tile == WORLD_TILES.CLOUDS_DARK) then
                count = count + 1
            end
        end
    end
    return math.min(count * CLOUD_DENSITY_SCALE, 1)
end

local function PushCloudMix()
    if TheMixer.mixes[CLOUD_HANDLE] == nil then
        -- The normal mix mutes the cloud bus. Copy all its levels because the
        -- mixer uses only the top mix, rather than merging individual buses.
        local normal = TheMixer.mixes.normal
        local levels = {}
        for channel, volume in pairs(normal.levels) do
            levels[channel] = volume
        end
        levels["set_ambience/cloud"] = 1
        -- Native zoom, pause, death and menu mixes retain higher priority.
        TheMixer:AddNewMix(CLOUD_HANDLE, 1, normal.priority + .1, levels)
    end
    TheMixer:PushMix(CLOUD_HANDLE)
end

local function FindUpvalue(fn, wanted)
    local index = 1
    while true do
        local name, value = debug.getupvalue(fn, index)
        if name == nil then
            return
        elseif name == wanted then
            return index, value
        end
        index = index + 1
    end
end

AddComponentPostInit("ambientsound", function(self)
    if TheNet:IsDedicated() then
        return
    end

    -- Native tile overrides only redirect tile IDs; they cannot select a
    -- region-wide sound or keep one region on a fixed seasonal recording.
    local onupdate = self.OnUpdate
    local sounds_index, sounds = FindUpvalue(onupdate, "AMBIENT_SOUNDS")
    local position_index = FindUpvalue(onupdate, "_lastplayerpos")
    local regional_available = sounds_index ~= nil and position_index ~= nil
    local lowland, highland, snowland, current
    if not regional_available then
        print("[Mountain Scream] Ambient sound hook unavailable: native OnUpdate upvalues not found.")
    else
        lowland = sounds[WORLD_TILES.DIRT]
        highland = sounds[WORLD_TILES.ROCKY]
        -- No seasonal/rain alternatives: every season and weather uses winter.
        snowland = { sound = sounds[WORLD_TILES.GRASS].wintersound }
        local regional_sounds = setmetatable({}, {
            __index = function(_, tile)
                if current ~= nil and type(tile) == "number" then
                    return current
                end
                return sounds[tile]
            end,
            __newindex = sounds,
        })
        debug.setupvalue(onupdate, sounds_index, regional_sounds)
    end

    local cloud_volume = 0
    local cloud_proximity = 0
    local cloud_target_proximity = 0
    local cloud_player
    local cloud_x, cloud_y, cloud_z
    local cloud_source
    local function SetCloudSound(volume, proximity)
        -- Own the regional loop on the local focal point with a separate handle.
        local source = volume > 0 and TheFocalPoint or nil
        if source ~= nil and not source:IsValid() then
            source = nil
        end
        if source ~= cloud_source then
            if cloud_source ~= nil and cloud_source:IsValid() then
                cloud_source.SoundEmitter:KillSound(CLOUD_HANDLE)
            end
            if source ~= nil then
                if cloud_source == nil then
                    PushCloudMix()
                end
                source.SoundEmitter:PlaySound(CLOUD_SOUND, CLOUD_HANDLE)
                source.SoundEmitter:SetParameter(CLOUD_HANDLE, CLOUD_PARAMETER, proximity)
                source.SoundEmitter:SetVolume(CLOUD_HANDLE, volume)
            elseif cloud_source ~= nil then
                TheMixer:PopMix(CLOUD_HANDLE)
            end
            cloud_source = source
        elseif source ~= nil then
            if proximity ~= cloud_proximity then
                source.SoundEmitter:SetParameter(CLOUD_HANDLE, CLOUD_PARAMETER, proximity)
            end
            if volume ~= cloud_volume then
                source.SoundEmitter:SetVolume(CLOUD_HANDLE, volume)
            end
        end
        -- Retry on subsequent updates if the focal point is not ready yet.
        cloud_volume = source ~= nil and volume or 0
        cloud_proximity = proximity
    end

    local onremove = self.OnRemoveFromEntity
    self.OnRemoveFromEntity = function(component, ...)
        SetCloudSound(0, cloud_proximity)
        if onremove ~= nil then
            return onremove(component, ...)
        end
    end
    local onremoveentity = self.OnRemoveEntity
    self.OnRemoveEntity = function(component, ...)
        SetCloudSound(0, cloud_proximity)
        if onremoveentity ~= nil then
            return onremoveentity(component, ...)
        end
    end

    -- Install before the cave prefab adds the mountain tag. Select the local
    -- player's region at update time; other worlds retain their native sounds.
    self.OnUpdate = function(component, dt)
        local player = ThePlayer
        local tracker = player ~= nil and player.components.dungeonplayertracker or nil
        local environment = player ~= nil and player.components.dungeonplayerenvironment or nil
        local in_mountain = tracker ~= nil and tracker:IsInMsOverWorld()
        local selected
        if in_mountain and regional_available then
            local level = tracker:GetLevel()
            -- Geographic floors: green foothills 2-3, rocky mountains 4-6,
            -- snow mountains 7-8, summit 9 and golem arena 10.
            if level <= 3 then
                selected = lowland
            elseif level <= 6 then
                selected = highland
            else
                selected = snowland
            end
        end
        if selected ~= current then
            current = selected
            -- Recompute immediately, even without walking a full tile.
            debug.setupvalue(onupdate, position_index, nil)
        end
        -- Match the wave scan cadence, caching scalar positions to avoid extra
        -- vectors or per-frame scans. Re-entry and player changes force a scan.
        local clouds_enabled = in_mountain and (environment == nil or not environment._clientinactive)
        if clouds_enabled then
            if cloud_player ~= player or player:GetDistanceSqToPoint(cloud_x, cloud_y, cloud_z) >= 16 then
                cloud_player = player
                cloud_x, cloud_y, cloud_z = player.Transform:GetWorldPosition()
                cloud_target_proximity = GetCloudProximity(component.inst.Map, cloud_x, cloud_y, cloud_z)
            end
        else
            cloud_player = nil
        end
        -- The event curves apply density-based gain and high-frequency filtering
        -- once. Emitter volume only fades the whole sound on region entry/exit.
        local proximity = cloud_proximity < cloud_target_proximity
            and math.min(cloud_target_proximity, cloud_proximity + dt * CLOUD_PROXIMITY_RATE)
            or math.max(cloud_target_proximity, cloud_proximity - dt * CLOUD_PROXIMITY_RATE)
        SetCloudSound(clouds_enabled
            and math.min(CLOUD_MAX_VOLUME, cloud_volume + dt * CLOUD_FADE_RATE)
            or math.max(0, cloud_volume - dt * CLOUD_FADE_RATE), proximity)
        return onupdate(component, dt)
    end
end)
