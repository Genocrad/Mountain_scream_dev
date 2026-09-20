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

-- Generate light phase ID's
-- Add tint to params
local light_phases = {}
for k, v in pairs(light_params) do
    table.insert(light_phases, k)
    v.id = #light_phases
    v.tint = { v.colour[1] * .5, v.colour[2] * .5, v.colour[3] * .5, 1 }
end

local function pushparams(inst, params)
    inst.Light:SetRadius(params.radius * inst.widthscale)
    inst.Light:SetIntensity(params.intensity)
    inst.Light:SetFalloff(params.falloff)
    inst.Light:SetColour(unpack(params.colour))
    if TheWorld.ismastersim then
        if params.intensity > 0 then
            inst.Light:Enable(true)
            inst:Show()
        else
            inst.Light:Enable(false)
            inst:Hide()
        end
    end
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


local function OnCavePhase(inst, cavephase)
    local params = light_params[cavephase == "night" and TheWorld.state.isfullmoon and "fullmoon" or cavephase]
    if params ~= nil then
        inst._lightphase:set(params.id)
        OnLightPhaseDirty(inst)
      
        
    end
end

local function OnCharlieCutscene(inst, isstart)
    if isstart then
        OnCavePhase(inst, "day")
    else
        OnCavePhase(inst, TheWorld.state.cavephase)
    end
end

local function OnInit(inst)
    if TheWorld.ismastersim then
        inst:WatchWorldState("cavephase", OnCavePhase)
        local params = light_params[TheWorld.state.iscavenight and TheWorld.state.isfullmoon and "fullmoon" or TheWorld.state.cavephase]
        if params ~= nil then
            inst._lightphase:set(params.id)
        end
    else
        inst:ListenForEvent("lightphasedirty", OnLightPhaseDirty)
    end
    
    local phase = light_phases[inst._lightphase:value()]
    if phase ~= nil then
        local params = light_params[phase]
        if params ~= nil and params ~= inst._endlight then
            copyparams(inst._currentlight, params)
            inst._endlight = params
            if inst._lighttask ~= nil then
                inst._lighttask:Cancel()
                inst._lighttask = nil
            end
            pushparams(inst, inst._currentlight)
        end
    end
end

local function onspawned(inst, child)
    child:PushEvent("fly_back")
end

local function UpdatePosition(inst)
  if inst._target == nil then
    inst:Remove()
    
  else
	local x, y, z = inst._target.Transform:GetWorldPosition()
  if x ~= nil then
    if inst._x ~= x or inst._z ~= z then
        inst._x = x
        inst._z = z
        inst.Transform:SetPosition(x, 0, z)
    end
    if TheWorld.net.components.dungeonmapoverwatch then
      
      local level = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z)
      if level and level <= TUNING.MS_CAVES_START then
        inst._lightswitch:set(true)
        inst.Light:SetIntensity(light_params[TheWorld.state.cavephase].intensity)
        inst.Light:Enable(true)
      else
        inst._lightswitch:set(false)
        inst.Light:Enable(false)
        inst.Light:SetIntensity(0)
      end
    else
      inst:Remove()
    end
  else
    inst:Remove()
  end
  end
end

local function lightswitchdirty(inst)
  if inst._lightswitch:value() then
    inst.Light:SetIntensity(light_params[TheWorld.state.cavephase].intensity)
    inst.Light:Enable(true)
  else
    inst.Light:Enable(false)
    inst.Light:SetIntensity(0)
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
    pushparams(inst, inst._currentlight)

    inst._lightphase = net_tinybyte(inst.GUID, "cavelight._lightphase", "lightphasedirty")
    inst._lightswitch = net_bool(inst.GUID, "cavelight._lightswitch", "lightswitchdirty")
    inst._lightphase:set(inst._currentlight.id)
    inst._lighttask = nil

    inst:DoTaskInTime(0, OnInit)
    inst:DoTaskInTime(0, lightswitchdirty)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst.widthscale = 500
    
    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(UpdatePosition)

    return inst
end


return Prefab("light_fake_overworld", common_fn, assets)
