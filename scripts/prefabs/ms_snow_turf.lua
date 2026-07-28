local assets =
{
    Asset("ANIM", "anim/ms_hello_turf.zip"),
    Asset("INV_IMAGE", "dock_kit"),
}

local prefabs =
{
    "gridplacer",
    "dock_damage",
}

local function IsPermanentFn(tileid)
    return IsLandTile(tileid) and not TileGroupManager:IsTemporaryTile(tileid)
end

local function CLIENT_CanDeploy(inst, pt, mouseover, deployer, rotation)
    local x, y, z = pt:Get()
    local tile = TheWorld.Map:GetTileAtPoint(x, 0, z)
    local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x,y,z)
    if not IsPermanentFn(tile) then
        print(tile)
        return false
        
    end

    return true
end

local function on_deploy(inst, pt, deployer)
    local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(pt.x, pt.y, pt.z)
    local current = TheWorld.Map:GetTile(tx, ty)
    TheWorld.Map:SetTile(tx, ty, WORLD_TILES.MS_SNOW)
      
    if TheWorld.components.undertile ~= nil then
      TheWorld.components.undertile:SetTileUnderneath(tx, ty, current)
    end
    

    inst.components.stackable:Get():Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ms_turf")
    inst.AnimState:SetBuild("ms_turf")
    inst.AnimState:PlayAnimation("ms_snow")

    inst.pickupsound = "wood"

    MakeInventoryFloatable(inst, "med", 0.2, 0.75)

    inst:AddTag("groundtile")
	inst:AddTag("deploykititem")
    inst:AddTag("usedeployspacingasoffset")

    inst._custom_candeploy_fn = CLIENT_CanDeploy -- for DEPLOYMODE.CUSTOM
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -------------------------------------------------------
    inst:AddComponent("inspectable")

    -------------------------------------------------------
    inst:AddComponent("inventoryitem")

    -------------------------------------------------------
    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable:SetUseGridPlacer(true)
    inst.components.deployable.ondeploy = on_deploy

    -------------------------------------------------------
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    return inst
end

-----------------------------------------------------------------------------
local function on_registrator_loaded(inst, data, newents)
    if data ~= nil and data.undertile ~= nil then
        inst._loaded_undertile = WORLD_TILES[data.undertile]
    end
end

local function on_registrator_postpass(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    TheWorld.Map:SetTile(tx, ty, WORLD_TILES.MS_SNOW)

    if TheWorld.components.undertile ~= nil then
        local tx, ty = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
        TheWorld.components.undertile:SetTileUnderneath(tx, ty, inst._loaded_undertile)
    end

    inst.persists = false
end

local function registrator_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("CLASSIFIED")

    inst._loaded_undertile = nil
    inst.OnLoad = on_registrator_loaded

    inst:DoTaskInTime(1*FRAMES, on_registrator_postpass)

    return inst
end

return Prefab("turf_ms_snow", fn, assets, prefabs),
    Prefab("turf_ms_snow_registrator", registrator_fn)