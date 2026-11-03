local assets =
{
	Asset("ANIM", "anim/ms_blooding_fx.zip"),
}

local function ApplyHeal(inst)
	local heal = inst._heal or 0
	inst._heal = 0
	local target = inst._target
	if heal > 0
		and target ~= nil
		and target:IsValid()
		and target.components.health ~= nil
		and not target.components.health:IsDead()
	then
		target.components.health:DoDelta(heal, false, "mountain_screamer_scream")
	end
end

local function StopFlight(inst)
	if inst._flight_task ~= nil then
		inst._flight_task:Cancel()
		inst._flight_task = nil
	end
end

local function Finish(inst)
	if inst._finished then
		return
	end
	inst._finished = true
	StopFlight(inst)
	inst:Remove()
end

local function OnLandAnimOver(inst)
	if inst.AnimState:AnimDone() then
		Finish(inst)
	end
end

local function StartLand(inst)
	if inst._landing or inst._finished then
		return
	end
	inst._landing = true
	StopFlight(inst)

	local target = inst._target
	local land_y = TUNING.MOUNTAIN_SCREAMER.SCREAM_BLOODING_FX_LAND_Y or 2.5
	if target ~= nil and target:IsValid() then
		local x, y, z = target.Transform:GetWorldPosition()
		inst.Transform:SetPosition(x, land_y, z)
	else
		local x, y, z = inst.Transform:GetWorldPosition()
		inst.Transform:SetPosition(x, land_y, z)
	end

	ApplyHeal(inst)
	inst.AnimState:PlayAnimation("land")
	inst:ListenForEvent("animover", OnLandAnimOver)
end

local function GetTargetPos(inst)
	local target = inst._target
	if target == nil or not target:IsValid() then
		return nil
	end
	local x, y, z = target.Transform:GetWorldPosition()
	local land_y = TUNING.MOUNTAIN_SCREAMER.SCREAM_BLOODING_FX_LAND_Y or 2.5
	return x, land_y, z
end

local function OnFlightUpdate(inst)
	if inst._landing or inst._finished then
		return
	end

	local tx, ty, tz = GetTargetPos(inst)
	if tx == nil then
		-- Screamer 已无效：就地落地，不再回血
		inst._target = nil
		StartLand(inst)
		return
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local dx, dy, dz = tx - x, ty - y, tz - z
	local dist_sq = dx * dx + dy * dy + dz * dz
	local hit_dist = TUNING.MOUNTAIN_SCREAMER.SCREAM_BLOODING_FX_HIT_DIST or 0.75
	local step = (inst._speed or 9) * FRAMES

	if dist_sq <= hit_dist * hit_dist or dist_sq <= step * step then
		StartLand(inst)
		return
	end

	local dist = math.sqrt(dist_sq)
	inst.Transform:SetPosition(x + dx / dist * step, y + dy / dist * step, z + dz / dist * step)
end

local function StartFlight(inst)
	if inst._landing or inst._finished or inst._flying then
		return
	end
	inst._flying = true
	inst.AnimState:PlayAnimation("idle_flight_loop", true)
	inst._flight_task = inst:DoPeriodicTask(0, OnFlightUpdate)
	OnFlightUpdate(inst)
end

local function OnAppearAnimOver(inst)
	if inst._flying or inst._landing or inst._finished then
		return
	end
	if inst.AnimState:AnimDone() then
		StartFlight(inst)
	end
end

local function Launch(inst, target, heal)
	inst._target = target
	inst._heal = heal or 0
	inst._speed = GetRandomMinMax(
		TUNING.MOUNTAIN_SCREAMER.SCREAM_BLOODING_FX_SPEED_MIN or 8,
		TUNING.MOUNTAIN_SCREAMER.SCREAM_BLOODING_FX_SPEED_MAX or 10
	)
	inst.AnimState:PlayAnimation("cough_out")
	inst:ListenForEvent("animover", OnAppearAnimOver)
end

local function OnRemoveEntity(inst)
	StopFlight(inst)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("DECOR")

	inst.AnimState:SetBank("ms_blooding_fx")
	inst.AnimState:SetBuild("ms_blooding_fx")
	inst.AnimState:PlayAnimation("cough_out")
	inst.AnimState:SetFinalOffset(2)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst.entity:SetCanSleep(false)

	inst.Launch = Launch
	inst.OnRemoveEntity = OnRemoveEntity

	return inst
end

return Prefab("ms_blooding_fx", fn, assets)
