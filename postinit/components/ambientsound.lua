local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

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
    if sounds_index == nil or position_index == nil then
        print("[Mountain Scream] Ambient sound hook unavailable: native OnUpdate upvalues not found.")
        return
    end

    local lowland = sounds[WORLD_TILES.DIRT]
    local highland = sounds[WORLD_TILES.ROCKY]
    -- No seasonal/rain alternatives: every season and weather uses winter.
    local snowland = { sound = sounds[WORLD_TILES.GRASS].wintersound }
    local current
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

    -- Install before the cave prefab adds the mountain tag. Select the local
    -- player's region at update time; other worlds retain their native sounds.
    self.OnUpdate = function(component, dt)
        local tracker = ThePlayer ~= nil and ThePlayer.components.dungeonplayertracker or nil
        local selected
        if tracker ~= nil and tracker:IsInMsOverWorld() then
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
        return onupdate(component, dt)
    end
end)
