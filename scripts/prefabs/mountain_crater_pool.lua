local assets =
{
	Asset("ANIM", "anim/mountain_crater_pool.zip"),
}

local prefabs =
{
	"crater_steam_fx1",
	"crater_steam_fx2",
	"crater_steam_fx3",
	"crater_steam_fx4",
}

local function push_steam_fx(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("crater_steam_fx"..math.random(4)).Transform:SetPosition(x, y, z)
end

local function StartFx(inst, delay)
	if inst._fx_task ~= nil then
		inst._fx_task:Cancel()
	end
	inst._fx_task = inst:DoPeriodicTask(
		TUNING.MOUNTAIN_CRATER_POOL.IDLE.BASE,
		push_steam_fx,
		delay or (math.random() * TUNING.MOUNTAIN_CRATER_POOL.IDLE.DELAY)
	)
end

local function StopFx(inst)
	if inst._fx_task ~= nil then
		inst._fx_task:Cancel()
		inst._fx_task = nil
	end
end

local function OnBathingPoolTick_PerOccupant(inst, occupant, dt)
	if occupant:HasTag("mountain_kiki") then
		return
	end
	if occupant.components.health then
		occupant.components.health:DoDelta(TUNING.MOUNTAIN_CRATER_POOL.HEALTH_PER_SECOND * dt, true, inst.prefab, true)
	end
	if occupant.components.sanity then
		local rate = TUNING.MOUNTAIN_CRATER_POOL.SANITY_PER_SECOND
		if TheWorld.Map:IsInLunacyArea(occupant.Transform:GetWorldPosition()) then
			rate = -rate
		end
		occupant.components.sanity.externalmodifiers:SetModifier(inst, rate)
	end
end

local function OnBathingPoolTick(inst)
	local bathingpool = inst.components.bathingpool
	if bathingpool then
		bathingpool:ForEachOccupant(OnBathingPoolTick_PerOccupant, TUNING.MOUNTAIN_CRATER_POOL.TICK_PERIOD)
	end
end

local function OnStartBeingOccupiedBy(inst, ent)
	if ent:HasTag("mountain_kiki") then
		inst._kiki_bather = ent
	end
	if not inst.bathingpoolents then
		inst.bathingpoolents = { [ent] = true }
		inst.bathingpooltask = inst:DoPeriodicTask(TUNING.MOUNTAIN_CRATER_POOL.TICK_PERIOD, OnBathingPoolTick)
	else
		inst.bathingpoolents[ent] = true
	end
	if ent.components.sanity then
		local rate = TUNING.MOUNTAIN_CRATER_POOL.SANITY_PER_SECOND
		if TheWorld.Map:IsInLunacyArea(ent.Transform:GetWorldPosition()) then
			rate = -rate
		end
		ent.components.sanity.externalmodifiers:SetModifier(inst, rate)
	end
end

local function OnStopBeingOccupiedBy(inst, ent)
	if inst._kiki_bather == ent then
		inst._kiki_bather = nil
	end
	if inst.bathingpoolents then
		inst.bathingpoolents[ent] = nil
		if ent.components.sanity then
			ent.components.sanity.externalmodifiers:RemoveModifier(inst)
		end
		if next(inst.bathingpoolents) == nil then
			if inst.bathingpooltask then
				inst.bathingpooltask:Cancel()
				inst.bathingpooltask = nil
			end
			inst.bathingpoolents = nil
		end
	end
end

local function GetHeat(inst)
	inst.components.heater:SetThermics(true, false)
	return TUNING.MOUNTAIN_CRATER_POOL.HEAT
end

local function OnSleep(inst)
	StopFx(inst)
end

local function OnWake(inst)
	if inst._fx_task == nil then
		StartFx(inst)
	end
end

local MOUNTAIN_KIKI_TAGS = { "mountain_kiki" }

local function IsKikiAggroPhase()
	return TheWorld.state.isday or TheWorld.state.isdusk
end

local function AlertNearbyIdleKikis(inst, player)
	if not IsKikiAggroPhase() then
		return
	end
	if player == nil or not player:IsValid() or not player:HasTag("player") then
		return
	end
	if player.components.combat == nil or player:HasTag("playerghost") then
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local kikis = TheSim:FindEntities(x, y, z, TUNING.MOUNTAIN_CRATER_POOL.ALERT_RANGE, MOUNTAIN_KIKI_TAGS)
	for _, kiki in ipairs(kikis) do
		if kiki.components.combat ~= nil
				and kiki.components.combat:CanTarget(player)
				and not (kiki.sg ~= nil and kiki.sg:HasStateTag("soakin")) then
			kiki.components.combat:SetTarget(player)
		end
	end
end

local function UpdatePoolAlert(inst)
	if not IsKikiAggroPhase() then
		return
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	for _, player in ipairs(FindPlayersInRange(x, y, z, TUNING.MOUNTAIN_CRATER_POOL.DEFEND_RANGE)) do
		AlertNearbyIdleKikis(inst, player)
	end
end

local function OnPlayerNear(inst, player)
	AlertNearbyIdleKikis(inst, player)
end

local function HasKikiBather(inst)
	return inst._kiki_bather ~= nil and inst._kiki_bather:IsValid()
end

local function WrapBathingPoolForKiki(inst)
	local bathingpool = inst.components.bathingpool
	local enter_pool = bathingpool.EnterPool
	bathingpool.EnterPool = function(self, ent, ...)
		if ent:HasTag("mountain_kiki") and HasKikiBather(inst) and inst._kiki_bather ~= ent then
			return false, "NOSPACE"
		end
		return enter_pool(self, ent, ...)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddLight()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	MakePondPhysics(inst, 1)

	inst.AnimState:SetBank("mountain_crater_pool")
	inst.AnimState:SetBuild("mountain_crater_pool")
	inst.AnimState:PlayAnimation("glow_loop", true)

	inst.MiniMapEntity:SetIcon("mountain_crater_pool.tex")

	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(2)

	-- inst.Transform:SetScale(1.2, 1.2, 1.2)

	inst:AddTag("watersource")
	inst:AddTag("antlion_sinkhole_blocker")
	inst:AddTag("birdblocker")
	inst:AddTag("HASHEATER")
	inst:AddTag("mountain_crater_pool")

	inst.Light:Enable(true)
	inst.Light:SetRadius(TUNING.MOUNTAIN_CRATER_POOL.GLOW.RADIUS)
	inst.Light:SetIntensity(TUNING.MOUNTAIN_CRATER_POOL.GLOW.INTENSITY)
	inst.Light:SetFalloff(TUNING.MOUNTAIN_CRATER_POOL.GLOW.FALLOFF)
	inst.Light:SetColour(0.1, 1.6, 2)

	inst.no_wet_prefix = true
	inst:SetDeploySmartRadius(1.5)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("heater")
	inst.components.heater.heatfn = GetHeat

	inst:AddComponent("bathingpool")
	inst.components.bathingpool:SetRadius(1.1)
	inst.components.bathingpool:SetOnStartBeingOccupiedBy(OnStartBeingOccupiedBy)
	inst.components.bathingpool:SetOnStopBeingOccupiedBy(OnStopBeingOccupiedBy)
	WrapBathingPoolForKiki(inst)

	inst.HasKikiBather = HasKikiBather

	inst:AddComponent("watersource")
	inst.components.watersource.available = true

	local playerprox = inst:AddComponent("playerprox")
	playerprox:SetDist(
		TUNING.MOUNTAIN_CRATER_POOL.DEFEND_RANGE,
		TUNING.MOUNTAIN_CRATER_POOL.DEFEND_RANGE + 2
	)
	playerprox:SetOnPlayerNear(OnPlayerNear)

	inst:DoPeriodicTask(1, UpdatePoolAlert)

	StartFx(inst)

	inst.OnEntitySleep = OnSleep
	inst.OnEntityWake = OnWake

	return inst
end

return Prefab("mountain_crater_pool", fn, assets, prefabs)
