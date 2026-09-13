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


--------------------------------------------------------------------------


	local function GetHeatFn(inst)
    
    inst.AnimState:SetMultColour( (inst._overfueled + 0.5)/1.5, (inst._overfueled+0.5)/3, (inst._overfueled+0.5)/7.5, 1)
    inst.AnimState:SetAddColour( (inst._overfueled-1), (inst._overfueled-1)/2, (inst._overfueled-1)/5, 1)
		inst.components.temperatureoverrider:SetTemperature(heats[inst.components.firefx.level] * inst._overfueled)
    inst._overfueled = math.max(inst._overfueled - (1/(60*10)), 1)  
    return heats[inst.components.firefx.level] or 20
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
		return inst
	end

	return Prefab("ms_furnace_campfirefire", fn, assets, prefabs)