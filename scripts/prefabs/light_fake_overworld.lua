local assets =
{
    Asset("ANIM", "anim/cave_exit_lightsource.zip"),
}

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/AMB/caves/forest_spot", "loop")
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("loop")
end

local light_params =
{
    day =
    {
        radius = 50,
        intensity = 0.99,
        falloff = 0.8,
        colour = { 255 / 255, 230 / 255, 158 / 255 },
        time = 10,
    },

    dusk =
    {
        radius = 50,
        intensity = .99,
        falloff = 0.8,
        colour = { 150 / 255, 150 / 255, 150 / 255 },
        time = 4,
    },

    night =
    {
        radius = 50,
        intensity = 0,
        falloff = 0.3,
        colour = { 0, 0, 0 },
        time = 6,
    },

    fullmoon =
    {
        radius = 50,
        intensity = .99,
        falloff = 0.8,
        colour = { 84 / 255, 122 / 255, 156 / 255},
        time = 4,
    },
}

-- Network phase IDs must have the same order on server and clients.
local light_phases = { "day", "dusk", "night", "fullmoon" }
for i, phase in ipairs(light_phases) do
    light_params[phase].id = i
end

local function pushparams(inst, params)
    local enabled = inst._lightswitch:value() and params.intensity > 0
    inst.Light:SetRadius(params.radius * inst.widthscale)
    inst.Light:SetIntensity(enabled and params.intensity or 0)
    inst.Light:SetFalloff(params.falloff)
    inst.Light:SetColour(unpack(params.colour))
    inst.Light:Enable(enabled)
end

-- Not using deepcopy because we want to copy in place
local function copyparams(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = dest[k] or {}
            copyparams(dest[k], v)
        else
            dest[k] = v
        end
    end
end

local function lerpparams(pout, pstart, pend, lerpk)
    for k, v in pairs(pend) do
        if type(v) == "table" then
            lerpparams(pout[k], pstart[k], v, lerpk)
        else
            pout[k] = pstart[k] * (1 - lerpk) + v * lerpk
        end
    end
end

local function OnUpdateLight(inst, dt)
    inst._currentlight.time = inst._currentlight.time + dt
    if inst._currentlight.time >= inst._endlight.time then
        inst._currentlight.time = inst._endlight.time
        inst._lighttask:Cancel()
        inst._lighttask = nil
    end
    
    lerpparams(inst._currentlight, inst._startlight, inst._endlight, inst._endlight.time > 0 and inst._currentlight.time / inst._endlight.time or 1)
    pushparams(inst, inst._currentlight)
end

local function OnLightPhaseDirty(inst)
    local phase = light_phases[inst._lightphase:value()]
    if phase ~= nil then
        local params = light_params[phase]
        if params ~= nil and params ~= inst._endlight then
            copyparams(inst._startlight, inst._currentlight)
            inst._currentlight.time = 0
            inst._startlight.time = 0
            inst._endlight = params
            if inst._lighttask == nil then
                inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, FRAMES)
            end
        end
    end
end


local function CurrentPhase()
    local state = TheWorld.state
    return state.cavephase == "night" and state.iscavefullmoon and "fullmoon" or state.cavephase
end

local function OnPhaseChanged(inst)
    inst._lightphase:set(light_params[CurrentPhase()].id)
    OnLightPhaseDirty(inst)
end

local function ApplyCurrentPhase(inst)
    local params = light_params[light_phases[inst._lightphase:value()]]
    if params ~= nil then
        if inst._lighttask ~= nil then
            inst._lighttask:Cancel()
            inst._lighttask = nil
        end
        copyparams(inst._currentlight, params)
        inst._endlight = params
    end
    pushparams(inst, inst._currentlight)
end

local function OnLightSwitchDirty(inst)
    if inst._lightswitch:value() then
        ApplyCurrentPhase(inst)
    else
        pushparams(inst, inst._currentlight)
    end
end

local function UpdateLevel(inst, level)
    local enabled = level ~= nil and level <= TUNING.MS_CAVES_START
    if inst._lightswitch:value() ~= enabled then
        inst._lightswitch:set(enabled)
        OnLightSwitchDirty(inst)
    end
end

local function OnInit(inst)
    if TheWorld.ismastersim then
        inst:WatchWorldState("cavephase", OnPhaseChanged)
        inst:WatchWorldState("iscavefullmoon", OnPhaseChanged)
        inst._lightphase:set(light_params[CurrentPhase()].id)
        local tracker = inst._target ~= nil and inst._target.components.dungeonplayertracker or nil
        UpdateLevel(inst, tracker ~= nil and tracker:GetLevel() or nil)
    end
    ApplyCurrentPhase(inst)
end

local function UpdatePosition(inst)
    if inst._target == nil or not inst._target:IsValid() then
        inst:Remove()
        return
    end
    local x, _, z = inst._target.Transform:GetWorldPosition()
    if inst._x ~= x or inst._z ~= z then
        inst._x = x
        inst._z = z
        inst.Transform:SetPosition(x, 0, z)
    end
end

local function common_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:EnableClientModulation(true)
    
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst:AddTag("daylight")
    inst:AddTag("sinkhole")
    inst:AddTag("batdestination")

    inst.persists = false
      
    inst.widthscale = 3
    inst._endlight = light_params.night
    inst._startlight = {}
    inst._currentlight = {}
    copyparams(inst._startlight, inst._endlight)
    copyparams(inst._currentlight, inst._endlight)
    inst._lightphase = net_tinybyte(inst.GUID, "cavelight._lightphase", "lightphasedirty")
    inst._lightswitch = net_bool(inst.GUID, "cavelight._lightswitch", "lightswitchdirty")
    inst._lightphase:set(inst._currentlight.id)
    inst._lighttask = nil
    inst:ListenForEvent("lightphasedirty", OnLightPhaseDirty)
    inst:ListenForEvent("lightswitchdirty", OnLightSwitchDirty)
    pushparams(inst, inst._currentlight)

    inst:DoTaskInTime(0, OnInit)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst.widthscale = 500
    
    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(UpdatePosition)
    
    inst.UpdateLevel = UpdateLevel
        
    return inst
end


return Prefab("light_fake_overworld", common_fn, assets)
