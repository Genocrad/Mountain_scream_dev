local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local function RemoveDaySpawnLight(inst)
    local overwatch = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch or nil
    if overwatch ~= nil and TheWorld.state.cavephase == "day" then
        local level = overwatch:GetNearestLevel(inst.Transform:GetWorldPosition())
        if level ~= nil and level <= TUNING.MS_CAVES_START then
            inst:Remove()
        end
    end
end

AddPrefabPostInit("spawnlight_multiplayer", function(inst)
    if not TheWorld.ismastersim or not TheWorld:HasTag("mountain_scream_dungeons") then
        return
    end

    if TheWorld.state.cavephase == "day" then
        -- The spawner sets the position after construction. Check it before
        -- the first native light pulse, without relying on the player's tracker.
        inst:DoTaskInTime(0, RemoveDaySpawnLight)
    end
end)
