local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPlayerPostInit(function(inst)
    if not enable_collision_for_player then
        inst.Physics:SetCollisionMask(
            COLLISION.WORLD,
            COLLISION.OBSTACLES,
            COLLISION.SMALLOBSTACLES,
            COLLISION.CHARACTERS,
            COLLISION.GIANTS
        )
    end

    inst._isusingmsdoor = net_ushortint(inst.GUID, "inst._isusingmsdoor", "isusingmsdoordirty")
    inst._isusingmsdoor:set(2)

    inst:AddComponent("dungeonplayertracker")
    if TheWorld:HasTag("mountain_scream_dungeons") then
        inst:AddComponent("dungeonplayerenvironment")
    end
end)
