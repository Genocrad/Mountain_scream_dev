local assets =
{
	Asset("ANIM", "anim/ms_arenateleporter.zip"),
}

local exit_assets =
{
	Asset("ANIM", "anim/ms_arenateleporter_exit.zip"),
}

local fx_assets =
{
	Asset("ANIM", "anim/ms_teleport_snow_fx.zip"),
	Asset("ANIM", "anim/ms_snow_splash_fx.zip"),
}

local prefabs =
{
	"ms_teleportsnowcoffin_fx",
}

local function OnActivate(inst, doer)
	if doer:HasTag("player") then
		if doer.components.talker ~= nil then
			doer.components.talker:ShutUp()
		end
	end
end

local function SetExitTarget(inst, targetinst)
	local oldtarget = inst.components.teleporter:GetTarget()
	if oldtarget then
		inst:RemoveEventCallback("onremove", inst._exittarget_onremove, targetinst)
	end

	inst.components.teleporter:Target(targetinst)
	if not targetinst then
		inst.components.teleporter:SetEnabled(false)
		return
	end
	inst.components.teleporter:SetEnabled(true)
	inst:ListenForEvent("onremove", inst._exittarget_onremove, targetinst)
end

local function OnSave(inst, data)
	if inst.components.teleporter.targetTeleporter then
		data.target_x, data.target_y, data.target_z = inst.components.teleporter.targetTeleporter.Transform:GetWorldPosition()
	end
end

local function OnLoad(inst, data)
	if data ~= nil and data.target_x then
		local exit = SpawnPrefab("ms_arenateleporter_exit")
		exit.Transform:SetPosition(data.target_x, data.target_y, data.target_z)
		exit:SetExitTarget(inst)
		inst:SetExitTarget(exit)
	end
end

local function MakeTeleporter(name, common_postinitfn, master_postinitfn, prefab_assets)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		inst:AddTag("groundhole")
		inst:AddTag("blocker")
		inst:AddTag("vault_teleporter")
		-- 走自定义 ms_entertownportal / ms_exittownportal_pre（雪特效）
		inst:AddTag("ms_snow_teleport")

		inst.AnimState:SetBank("ms_arenateleporter")
		inst.AnimState:SetBuild("ms_arenateleporter")
		inst.AnimState:PlayAnimation("idle")

		inst.MiniMapEntity:SetIcon("minimap_ms_arenateleporter.tex")

		MakeObstaclePhysics(inst, 1)

		inst:SetDeploySmartRadius(3)

		if common_postinitfn ~= nil then
			common_postinitfn(inst)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		local teleporter = inst:AddComponent("teleporter")
		teleporter.onActivate = OnActivate
		teleporter.offset = 3
		teleporter.saveenabled = true
		-- 与懒人塔一致：进出走 townportal 节奏（落地播 ms_exittownportal_pre）
		teleporter.travelcameratime = 2.9
		teleporter.travelarrivetime = 2.8
		teleporter:SetEnabled(false)

		inst.SetExitTarget = SetExitTarget

		inst._exittarget_onremove = function()
			inst:SetExitTarget(nil)
		end
		if master_postinitfn ~= nil then
			master_postinitfn(inst)
		end
		return inst
	end
	return Prefab(name, fn, prefab_assets or assets, prefabs)
end

--------------------------------------------------------------------------
-- 雪版 townportalsandcoffin_fx（音效沿用官方）
--------------------------------------------------------------------------

local function KillFX(inst)
	if inst.killtask ~= nil then
		inst.killtask:Cancel()
		inst.killtask = nil
		inst.Physics:SetActive(false)
		inst.SoundEmitter:PlaySound("dontstarve/common/together/teleport_sand/out")
		inst.AnimState:PlayAnimation("portal_out")
		inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + .5, inst.Remove)
	end
end

local function fx_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .5)

	inst.AnimState:SetBank("ms_teleport_snow_fx")
	inst.AnimState:SetBuild("ms_teleport_snow_fx")
	inst.AnimState:OverrideSymbol("sand_splash", "ms_snow_splash_fx", "sand_splash")
	inst.AnimState:PlayAnimation("portal_in")
	inst.AnimState:SetFinalOffset(7)

	inst:AddTag("NOCLICK")
	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.SoundEmitter:PlaySound("dontstarve/common/together/teleport_sand/in")

	inst.persists = false
	inst.KillFX = KillFX
	inst.killtask = inst:DoTaskInTime(35 * FRAMES, KillFX)

	return inst
end

return MakeTeleporter("ms_arenateleporter", nil, function(inst)
		inst.OnSave = OnSave
		inst.OnLoad = OnLoad
	end),
	MakeTeleporter("ms_arenateleporter_exit", function(inst)
		inst.AnimState:SetBank("ms_arenateleporter_exit")
		inst.AnimState:SetBuild("ms_arenateleporter_exit")
		inst.AnimState:PlayAnimation("idle")
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_BACKGROUND)
		inst.AnimState:SetSortOrder(3)
		inst.MiniMapEntity:SetIcon("ms_arenateleporter_exit.tex")
		RemovePhysicsColliders(inst)
		inst:RemoveTag("blocker")
		inst.persists = false
	end, nil, exit_assets),
	Prefab("ms_teleportsnowcoffin_fx", fx_fn, fx_assets)
