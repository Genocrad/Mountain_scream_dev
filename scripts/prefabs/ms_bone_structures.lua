local DEFAULT_WORK_LEFT = TUNING.MS_BONE_STRUCTURES.WORK_LEFT
local RESTORE_TIME = TUNING.MS_BONE_STRUCTURES.RESTORE_TIME
local LOOT = TUNING.MS_BONE_STRUCTURES.LOOT
local RESTORE_TIMER = "restore"

------------------------------------------------------------------------------------------------------------------------

local function SpawnHitFx(inst)
	local fxname = inst._hit_fx
	if fxname == nil then
		return
	end
	local fx = SpawnPrefab(fxname)
	if fx ~= nil then
		fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
end

local function SetLightEnabled(inst, enabled)
	if inst.Light ~= nil then
		inst.Light:Enable(enabled)
	end
end

local function CancelRestore(inst)
	if inst.components.timer ~= nil and inst.components.timer:TimerExists(RESTORE_TIMER) then
		inst.components.timer:StopTimer(RESTORE_TIMER)
	end
end

local function SetPickableEnabled(inst, enabled)
	if inst.components.pickable ~= nil then
		inst.components.pickable.canbepicked = enabled == true
	end
end

local function SetThrowMineTarget(inst, enabled)
	if not inst._throw_only then
		return
	end
	if enabled then
		inst:AddTag("ms_aluminum_throw_mine")
	else
		inst:RemoveTag("ms_aluminum_throw_mine")
	end
end

local function SetIntactWorkable(inst)
	if inst.components.workable == nil then
		return
	end
	inst.components.workable:SetWorkLeft(inst._work_left or DEFAULT_WORK_LEFT)
	if inst._throw_only then
		inst.components.workable:SetWorkable(false)
		SetThrowMineTarget(inst, true)
	else
		inst.components.workable:SetWorkable(true)
	end
end

local function Restore(inst)
	CancelRestore(inst)

	inst.bone_state = "intact"
	SetPickableEnabled(inst, false)
	SetIntactWorkable(inst)
	inst.AnimState:PlayAnimation("idle", true)
	SetLightEnabled(inst, true)
end

local function StartRestore(inst, delay)
	CancelRestore(inst)
	local time = delay or RESTORE_TIME
	if time <= 0 then
		Restore(inst)
		return
	end
	inst.components.timer:StartTimer(RESTORE_TIMER, time)
end

local function OnTimerDone(inst, data)
	if data ~= nil and data.name == RESTORE_TIMER then
		Restore(inst)
	end
end

local function OnBrokenAnimOver(inst)
	inst:RemoveEventCallback("animover", OnBrokenAnimOver)
	if not inst:IsValid() or inst.bone_state ~= "broken" then
		return
	end
	inst.AnimState:PlayAnimation("broken_idle", true)
	SetPickableEnabled(inst, true)
end

------------------------------------------------------------------------------------------------------------------------

local function OnWork(inst, worker, workleft)
	if worker ~= nil and not worker:HasTag("playerghost") then
		local sound = inst._work_sound
		if sound ~= nil then
			inst.SoundEmitter:PlaySound(sound)
		end
	end

	if workleft > 0 then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", true)
		SpawnHitFx(inst)
	end
end

local function OnWorkFinish(inst)
	if inst.bone_state ~= "intact" then
		return
	end

	inst.bone_state = "broken"
	CancelRestore(inst)

	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkable(false)
	end
	SetThrowMineTarget(inst, false)
	SetPickableEnabled(inst, false)
	SetLightEnabled(inst, false)

	inst.AnimState:PlayAnimation("broken")
	inst:ListenForEvent("animover", OnBrokenAnimOver)
end

local function OnPicked(inst)
	if inst.bone_state ~= "broken" then
		return
	end

	inst.bone_state = "stolen"
	SetPickableEnabled(inst, false)
	inst.AnimState:PlayAnimation("broken_stolen_idle", true)
	StartRestore(inst)
end

------------------------------------------------------------------------------------------------------------------------

local function OnSave(inst, data)
	data.bone_state = inst.bone_state
end

local function OnLoad(inst, data)
	if data == nil then
		return
	end

	local state = data.bone_state
	if state == "broken" or state == "stolen" then
		inst.bone_state = state
	else
		inst.bone_state = "intact"
	end
	-- 兼容旧存档：曾用手写 DoTaskInTime 存 restore_left
	inst._pending_restore_left = data.restore_left
end

local function OnLoadPostPass(inst)
	inst:RemoveEventCallback("animover", OnBrokenAnimOver)

	if inst.bone_state == "broken" then
		CancelRestore(inst)
		if inst.components.workable ~= nil then
			inst.components.workable:SetWorkable(false)
		end
		SetThrowMineTarget(inst, false)
		SetLightEnabled(inst, false)
		inst.AnimState:PlayAnimation("broken_idle", true)
		SetPickableEnabled(inst, true)
	elseif inst.bone_state == "stolen" then
		if inst.components.workable ~= nil then
			inst.components.workable:SetWorkable(false)
		end
		SetThrowMineTarget(inst, false)
		SetLightEnabled(inst, false)
		SetPickableEnabled(inst, false)
		inst.AnimState:PlayAnimation("broken_stolen_idle", true)
		-- timer 组件会自行读档；仅当缺失时（含旧存档）补开
		if not inst.components.timer:TimerExists(RESTORE_TIMER) then
			StartRestore(inst, inst._pending_restore_left or RESTORE_TIME)
		end
	else
		inst.bone_state = "intact"
		CancelRestore(inst)
		SetPickableEnabled(inst, false)
		SetIntactWorkable(inst)
		inst.AnimState:PlayAnimation("idle", true)
		SetLightEnabled(inst, true)
	end

	inst._pending_restore_left = nil
end

------------------------------------------------------------------------------------------------------------------------

local function MakeBoneStructure(def)
	local assets =
	{
		Asset("ANIM", "anim/"..def.build..".zip"),
	}

	local prefabs =
	{
		LOOT,
		def.hit_fx,
	}

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddNetwork()

		if def.obstacle_radius ~= nil then
			MakeObstaclePhysics(inst, def.obstacle_radius)
		end

		if def.has_light then
			inst.entity:AddLight()
			inst.Light:SetFalloff(0.9)
			inst.Light:SetIntensity(0.6)
			inst.Light:SetRadius(2.5)
			inst.Light:SetColour(1, 0.65, 0.35)
			inst.Light:Enable(true)
		end

		inst.AnimState:SetBank(def.bank)
		inst.AnimState:SetBuild(def.build)
		inst.AnimState:PlayAnimation("idle", true)

		inst:AddTag("structure")

		if def.throw_only then
			inst:AddTag("ms_aluminum_throw_mine")
		end

		inst.scrapbook_anim = "idle"

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst.bone_state = "intact"
		inst._hit_fx = def.hit_fx
		inst._work_sound = def.work_sound
		inst._throw_only = def.throw_only == true
		inst._work_left = def.work_left or DEFAULT_WORK_LEFT

		inst:AddComponent("inspectable")
		inst:AddComponent("lootdropper")
		inst:AddComponent("timer")
		inst:ListenForEvent("timerdone", OnTimerDone)

		inst:AddComponent("pickable")
		inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
		inst.components.pickable:SetUp(LOOT, nil, 1)
		inst.components.pickable.remove_when_picked = false
		inst.components.pickable.canbepicked = false
		inst.components.pickable.onpickedfn = OnPicked

		inst:AddComponent("workable")
		inst.components.workable:SetWorkAction(def.work_action)
		inst.components.workable:SetWorkLeft(inst._work_left)
		inst.components.workable.savestate = true
		inst.components.workable:SetOnWorkCallback(OnWork)
		inst.components.workable:SetOnFinishCallback(OnWorkFinish)
		if def.throw_only then
			inst.components.workable:SetWorkable(false)
		end

		MakeHauntableWork(inst)

		inst.OnSave = OnSave
		inst.OnLoad = OnLoad
		inst.OnLoadPostPass = OnLoadPostPass

		return inst
	end

	return Prefab(def.name, fn, assets, prefabs)
end

------------------------------------------------------------------------------------------------------------------------

return MakeBoneStructure({
		name = "ms_bone_pile",
		bank = "ms_bone_pile",
		build = "ms_bone_pile",
		work_action = ACTIONS.DIG,
		work_sound = "dontstarve/wilson/dig",
		hit_fx = "ms_bone_pile_hit_fx",
		obstacle_radius = 1.2,
	}),
	MakeBoneStructure({
		name = "ms_bone_throne",
		bank = "ms_bone_throne",
		build = "ms_bone_throne",
		work_action = ACTIONS.HAMMER,
		work_sound = "dontstarve/common/destroy_stone",
		hit_fx = "ms_bone_throne_hit_fx",
		obstacle_radius = 1,
	}),
	MakeBoneStructure({
		name = "ms_bone_chandelier",
		bank = "ms_bone_chandelier",
		build = "ms_bone_chandelier",
		work_action = ACTIONS.MINE,
		work_sound = "dontstarve/wilson/use_pickaxe",
		hit_fx = "ms_bone_chandelier_hit_fx",
		work_left = TUNING.MS_BONE_STRUCTURES.CHANDELIER_WORK_LEFT,
		throw_only = true,
		has_light = true,
	})
