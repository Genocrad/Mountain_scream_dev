local assets =
{
    Asset("ANIM", "anim/campfire_fire.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "firefx_light",
}

local LIGHT_COLOUR = RGB(255, 255, 192)

--------------------------------------------------------------------------
local heats = { 250, 500, 700 }

local firelevels =
{
	{anim="level1", sound="dontstarve/common/campfire", radius=2, intensity=.8, falloff=.33, colour=LIGHT_COLOUR, soundintensity=.1},
	{anim="level2", sound="dontstarve/common/campfire", radius=3, intensity=.8, falloff=.33, colour=LIGHT_COLOUR, soundintensity=.3},
	{anim="level3", sound="dontstarve/common/campfire", radius=4, intensity=.8, falloff=.33, colour=LIGHT_COLOUR, soundintensity=.6},
}

for i = 3, 20 do
  table.insert(heats, 1000)
  table.insert(firelevels, {anim="level4", sound="dontstarve/common/campfire", radius=4, intensity=.8, falloff=.33, colour=LIGHT_COLOUR, soundintensity=.6})
end
--------------------------------------------------------------------------

local OVERFUEL_DURATION = 10 -- seconds to decay from 2 back to 1

local function GetHeatFn(inst)
	return heats[inst.components.firefx.level] or 20
end

local function ApplyOverfuel(inst)
	local over = inst._overfueled
	inst.AnimState:SetMultColour((over + 0.5) / 1.5, (over + 0.5) / 3, (over + 0.5) / 7.5, 1)
	inst.AnimState:SetAddColour(over - 1, (over - 1) / 2, (over - 1) / 5, 1)
	if inst.components.temperatureoverrider ~= nil then
		inst.components.temperatureoverrider:SetTemperature(GetHeatFn(inst) * over)
	end
end

local function StopOverfuelTask(inst)
	if inst._overfueltask ~= nil then
		inst._overfueltask:Cancel()
		inst._overfueltask = nil
	end
end

local function OnOverfuelTick(inst, dt)
	inst._overfueled = math.max(inst._overfueled - dt / OVERFUEL_DURATION, 1)
	ApplyOverfuel(inst)
	if inst._overfueled <= 1 then
		StopOverfuelTask(inst)
	end
end

local function SetOverfueled(inst, value)
	inst._overfueled = value or 1
	ApplyOverfuel(inst)
	if inst._overfueled > 1 then
		if inst._overfueltask == nil then
			inst._overfueltask = inst:DoPeriodicTask(FRAMES, OnOverfuelTick, nil, FRAMES)
		end
	else
		StopOverfuelTask(inst)
	end
end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank("campfire_fire")
		inst.AnimState:SetBuild("campfire_fire")
		inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		--inst.AnimState:SetRayTestOnBB(true)
		inst.AnimState:SetFinalOffset(-1)
    inst.AnimState:SetScale(1,0.5)
    
		inst:AddTag("FX")
    inst:AddTag("NOCLICK")
		--HASHEATER (from heater component) added to pristine state for optimization
		inst:AddTag("HASHEATER")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("heater")
		inst.components.heater.heatfn = GetHeatFn
    inst.components.heater:SetShouldFalloff(false)
    inst.components.heater:SetHeatRadiusCutoff(0.2)
    --inst.components.heater.heatrate = 200
    inst:AddComponent("temperatureoverrider")
    inst.components.temperatureoverrider:SetRadius(1)
    inst.components.temperatureoverrider:SetTemperature(450)
    inst.components.temperatureoverrider:Enable()
    
		inst:AddComponent("firefx")
		inst.components.firefx.levels = firelevels
		inst.components.firefx:SetLevel(1)
		inst.components.firefx.usedayparamforsound = true

    inst._overfueled = 1
    inst.ApplyOverfuel = ApplyOverfuel
    inst.SetOverfueled = SetOverfueled
    inst:ListenForEvent("onremove", StopOverfuelTask)
    ApplyOverfuel(inst)
		return inst
	end

	return Prefab("ms_furnace_campfirefire", fn, assets, prefabs)
