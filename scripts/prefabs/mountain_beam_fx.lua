local easing = require("easing")

local assets =
{
	Asset("ANIM", "anim/wagboss_beam.zip"),
}

local function CreateRing()
	local ring = CreateEntity()

	--[[Non-networked entity]]
	ring.persists = false

	ring.entity:AddTransform()
	ring.entity:AddAnimState()

	ring:AddTag("FX")
	ring:AddTag("NOCLICK")

	ring.AnimState:SetBank("wagboss_beam")
	ring.AnimState:SetBuild("wagboss_beam")
	ring.AnimState:PlayAnimation("ground_marker_pre")
	ring.AnimState:PushAnimation("ground_marker_loop")
	ring.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	ring.AnimState:SetLightOverride(0.3)
	ring.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	ring.AnimState:SetLayer(LAYER_BACKGROUND)
	ring.AnimState:SetSortOrder(3)

	return ring
end

--------------------------------------------------------------------------

local function DoAnimSync_Client(inst)
	if inst.AnimState:IsCurrentAnimation("beam_pre") then
		local t = inst.AnimState:GetCurrentAnimationTime()
		local len = inst.ring.AnimState:GetCurrentAnimationLength()
		if t < len then
			inst.ring.AnimState:SetTime(t)
		else
			inst.ring.AnimState:PlayAnimation("ground_marker_loop", true)
			inst.ring.AnimState:SetTime(t - len)
		end
	elseif inst.AnimState:IsCurrentAnimation("beam_pst") then
		inst.ring.AnimState:PlayAnimation("ground_marker_pst")
		inst.ring.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
	else
		inst.ring.AnimState:PlayAnimation("ground_marker_loop", true)
		inst.ring.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
	end
end

local function PostUpdate_Client(inst)
	DoAnimSync_Client(inst)
	inst._postupdating = nil
	inst.components.updatelooper:RemovePostUpdateFn(PostUpdate_Client)
end

local function OnAnimSync_Client(inst)
	if not inst._postupdating then
		inst._postupdating = true
		inst.components.updatelooper:AddPostUpdateFn(PostUpdate_Client)
	end
end

--------------------------------------------------------------------------

local function StartPreSound(inst)
	inst._initsoundtask = nil
	inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_up")
end

local function UpdateTracking(inst, dt)
	if inst.target == nil or not inst.target:IsValid() then
		inst.target = nil
		inst.components.updatelooper:RemoveOnWallUpdateFn(UpdateTracking)
		return
	end
	dt = dt * TheSim:GetTimeScale()
	if dt > 0 then
		local t = inst.trackingt + dt
		if t >= inst.trackinglen then
			inst.target = nil
			inst.components.updatelooper:RemoveOnWallUpdateFn(UpdateTracking)
		else
			local x, y, z = inst.Transform:GetWorldPosition()
			local x1, y1, z1 = inst.target.Transform:GetWorldPosition()
			local k = easing.outQuad(t, 0.8, 0.2, inst.trackinglen)
			local k1 = 1 - k
			inst.Transform:SetPosition(x * k + x1 * k1, 0, z * k + z1 * k1)
			inst.trackingt = t
		end
	end
end

local function UpdateTrackingPoint(inst, dt)
	if inst.trackpos == nil then
		inst.components.updatelooper:RemoveOnWallUpdateFn(UpdateTrackingPoint)
		return
	end
	dt = dt * TheSim:GetTimeScale()
	if dt > 0 then
		local t = inst.trackingt + dt
		if t >= inst.trackinglen then
			inst.trackpos = nil
			inst.components.updatelooper:RemoveOnWallUpdateFn(UpdateTrackingPoint)
		else
			local x, y, z = inst.Transform:GetWorldPosition()
			local x1, z1 = inst.trackpos.x, inst.trackpos.z
			local k = easing.outQuad(t, 0.8, 0.2, inst.trackinglen)
			local k1 = 1 - k
			inst.Transform:SetPosition(x * k + x1 * k1, 0, z * k + z1 * k1)
			inst.trackingt = t
		end
	end
end

local function TrackPoint(inst, x, z, x0, z0)
	if inst.targets == nil and inst.AnimState:IsCurrentAnimation("beam_pre") then
		if inst.trackpos == nil then
			local dx = x - x0
			local dz = z - z0
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist > 0 then
				local k = math.min(dist / 2, 1) / dist
				inst.Transform:SetPosition(x - k * dx, 0, z - k * dz)
			else
				inst.Transform:SetPosition(x, 0, z)
			end
			inst.trackpos = Vector3(x, 0, z)
			inst.components.updatelooper:AddOnWallUpdateFn(UpdateTrackingPoint)
			inst.trackingt = inst.AnimState:GetCurrentAnimationTime()
			inst.trackinglen = inst.AnimState:GetCurrentAnimationLength()
		end

		if inst._initsoundtask then
			inst._initsoundtask:Cancel()
			StartPreSound(inst)
		end
	end
end

--------------------------------------------------------------------------

local function TrackTarget(inst, target, x0, z0)
	if inst.targets == nil and inst.AnimState:IsCurrentAnimation("beam_pre") then
		if inst.target == nil then
			local x, y, z = target.Transform:GetWorldPosition()
			local dx = x - x0
			local dz = z - z0
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist > 0 then
				local k = math.min(dist / 2, 1) / dist
				inst.Transform:SetPosition(x - k * dx, 0, z - k * dz)
			else
				inst.Transform:SetPosition(x, 0, z)
			end
			inst.components.updatelooper:AddOnWallUpdateFn(UpdateTracking)
			inst.trackingt = inst.AnimState:GetCurrentAnimationTime()
			inst.trackinglen = inst.AnimState:GetCurrentAnimationLength()
		end
		inst.target = target

		if inst._initsoundtask then
			inst._initsoundtask:Cancel()
			StartPreSound(inst)
		end
	end
end

--------------------------------------------------------------------------

local REGISTERED_AOE_TAGS
local BEAM_WORK_ACTIONS =
{
	CHOP = true,
	DIG = true,
	HAMMER = true,
	MINE = true,
}
local BEAM_RADIUS = 3
local BEAM_RANGE_PADDING = 3

local function CanBeamTarget(inst, v)
	if inst.caster and inst.caster:IsValid() then
		return inst.caster.components.combat:CanTarget(v)
	end
	return inst.components.combat:CanTarget(v)
end

local function TossLaunch(inst, launcher, basespeed, startheight)
	local x0, y0, z0 = launcher.Transform:GetWorldPosition()
	local x1, y1, z1 = inst.Transform:GetWorldPosition()
	local dx, dz = x1 - x0, z1 - z0
	local dsq = dx * dx + dz * dz
	local angle
	if dsq > 0 then
		local dist = math.sqrt(dsq)
		angle = math.atan2(dz / dist, dx / dist) + (math.random() * 20 - 10) * DEGREES
	else
		angle = TWOPI * math.random()
	end
	local sina, cosa = math.sin(angle), math.cos(angle)
	local speed = basespeed + math.random()
	inst.Physics:Teleport(x1, startheight, z1)
	inst.Physics:SetVel(cosa * speed, speed * 5 + math.random() * 2, sina * speed)
end

local function ApplyBeamDotDamage(inst, target, attacker, dt)
	local dmg = TUNING.MOUNTAIN_GOLEM.LASER_DOT_DPS * dt
	if dmg <= 0 then
		return
	end

	target.components.health:DoDelta(-dmg, false, inst.nameoverride, nil, attacker)

	inst.dotacc[target] = (inst.dotacc[target] or 0) + dmg
	local now = GetTime()
	local last = inst.dot_lastfeedback[target] or 0
	if now - last >= TUNING.MOUNTAIN_GOLEM.LASER_DOT_HIT_INTERVAL then
		target:PushEvent("attacked", { attacker = attacker, damage = inst.dotacc[target] })
		inst.dotacc[target] = 0
		inst.dot_lastfeedback[target] = now
	end
end

local function UpdateBeamAOE(inst, dt)
	if REGISTERED_AOE_TAGS == nil then
		local tags = { "_combat", "_inventoryitem", "pickable", "NPC_workable" }
		for k in pairs(BEAM_WORK_ACTIONS) do
			table.insert(tags, k.."_workable")
		end
		REGISTERED_AOE_TAGS = TheSim:RegisterFindTags(
			nil,
			{ "FX", "DECOR", "INLIMBO", "flight", "invisible" },
			tags
		)
	end
	local tick = GetTick()
	local prevcoloured = inst.coloured2
	local attacker = inst.caster and inst.caster:IsValid() and inst.caster or inst
	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities_Registered(x, 0, z, BEAM_RADIUS + BEAM_RANGE_PADDING, REGISTERED_AOE_TAGS)) do
		if v ~= inst and v ~= inst.caster and v:IsValid() and not v:IsInLimbo() then
			local physrad = v:GetPhysicsRadius(0)
			local range = BEAM_RADIUS + physrad
			local dsq = v:GetDistanceSqToPoint(x, y, z)
			if dsq < range * range then
				if inst.targets[v] == nil then
					local isworkable = false
					if v.components.workable then
						local work_action = v.components.workable:GetWorkAction()
						isworkable =
							(	work_action == nil and v:HasTag("NPC_workable")	) or
							(	v.components.workable:CanBeWorked() and
								work_action and
								BEAM_WORK_ACTIONS[work_action.id] and
								not (	work_action == ACTIONS.DIG and
										(	v.components.spawner or
											v.components.childspawner
										)
									)
							)
					end
					if isworkable then
						v.components.workable:Destroy(attacker)
						if v:IsValid() then
							if v:HasTag("stump") then
								v:Remove()
							else
								inst.targets[v] = tick
							end
						end
					elseif v.components.pickable and v.components.pickable:CanBePicked() and not v:HasTag("intense") then
						v.components.pickable:Pick(attacker)
						inst.targets[v] = tick
					elseif CanBeamTarget(inst, v) and v.components.health and not v.components.health:IsDead() then
						if inst.firsthit then
							inst.components.combat:DoAttack(v)
						else
							ApplyBeamDotDamage(inst, v, attacker, dt)
						end
						inst.targets[v] = tick
					elseif v.components.inventoryitem and v.components.locomotor == nil then
						DeactivateInventoryItemBeforeLaunch(v)
						if not v.components.inventoryitem.nobounce then
							TossLaunch(v, inst, 1.2, 0.1)
						end
						inst.targets[v] = tick
					end
				elseif CanBeamTarget(inst, v) and v.components.health and not v.components.health:IsDead() then
					ApplyBeamDotDamage(inst, v, attacker, dt)
					inst.targets[v] = tick
				end
				if v:IsValid() then
					local c = Remap(math.sqrt(dsq), BEAM_RADIUS - physrad, BEAM_RADIUS + physrad, 0, 1)
					if c < 1 then
						c = math.max(0, c)
						c = 1 - c * c
						if v:HasTag("epic") then
							c = c * 0.4
						elseif v:HasTag("largecreature") then
							c = c * 0.6
						end
						if c ~= prevcoloured[v] then
							if v.components.colouradder == nil then
								v:AddComponent("colouradder")
							end
							v.components.colouradder:PushColour(inst, c, c, c, 0)
						end
						prevcoloured[v] = nil
						inst.coloured1[v] = c
					end
				end
			end
		end
	end
	for k, v in pairs(inst.targets) do
		if not k:IsValid() or (k.components.health and k.components.health:IsDead()) then
			inst.targets[k] = nil
			if inst.dotacc ~= nil then
				inst.dotacc[k] = nil
			end
			if inst.dot_lastfeedback ~= nil then
				inst.dot_lastfeedback[k] = nil
			end
		elseif v < tick then
			inst.targets[k] = nil
			if inst.dotacc ~= nil then
				inst.dotacc[k] = nil
			end
			if inst.dot_lastfeedback ~= nil then
				inst.dot_lastfeedback[k] = nil
			end
		end
	end
	for k in pairs(prevcoloured) do
		if k:IsValid() and k.components.colouradder then
			k.components.colouradder:PopColour(inst)
		end
		prevcoloured[k] = nil
	end
	inst.coloured2 = inst.coloured1
	inst.coloured1 = prevcoloured
	inst.firsthit = nil
end

local FADE_TIME = 0.75
local function UpdateColouredFade(inst, dt)
	local prevcoloured = inst.coloured2
	local t = inst.fadet + dt
	inst.fadet = t

	if t < FADE_TIME then
		local c = easing.inQuad(t, 1, -1, FADE_TIME)
		for k, v in pairs(prevcoloured) do
			if k:IsValid() and k.components.colouradder then
				v = v * c
				k.components.colouradder:PushColour(inst, v, v, v, 0)
			else
				prevcoloured[k] = nil
				if next(prevcoloured) == nil then
					inst.components.updatelooper:RemoveOnUpdateFn(UpdateColouredFade)
				end
			end
		end
	else
		for k in pairs(prevcoloured) do
			if k:IsValid() and k.components.colouradder then
				k.components.colouradder:PopColour(inst)
			end
			prevcoloured[k] = nil
		end
		inst.components.updatelooper:RemoveOnUpdateFn(UpdateColouredFade)
	end
end

local function StartBeamAOE(inst)
	if inst.target then
		inst.target = nil
		inst.components.updatelooper:RemoveOnWallUpdateFn(UpdateTracking)
	end
	if inst.trackpos then
		inst.trackpos = nil
		inst.components.updatelooper:RemoveOnWallUpdateFn(UpdateTrackingPoint)
	end
	inst.targets = {}
	inst.dotacc = {}
	inst.dot_lastfeedback = {}
	inst.coloured1 = {}
	inst.coloured2 = {}
	inst.firsthit = true
	inst.components.updatelooper:AddOnUpdateFn(UpdateBeamAOE)

	inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_down_LP", "loop")
end

local function UpdateBeamLightPre(inst)
	if inst.AnimState:IsCurrentAnimation("beam_pre") then
		local frame = inst.AnimState:GetCurrentAnimationFrame()
		if frame > 28 then
			local len = inst.AnimState:GetCurrentAnimationNumFrames()
			local r = easing.outQuad(frame - 28, 0, 3, len - 28)
			inst.Light:SetRadius(r)
			inst.Light:Enable(true)
		end
	else
		inst.Light:SetRadius(3)
		inst.Light:Enable(true)
		inst.components.updatelooper:RemoveOnUpdateFn(UpdateBeamLightPre)
	end
end

local function UpdateBeamLightPst(inst)
	if inst.AnimState:IsCurrentAnimation("beam_pst") then
		local frame = inst.AnimState:GetCurrentAnimationFrame()
		if frame < 5 then
			inst.Light:SetRadius(3)
			inst.Light:Enable(true)
		elseif frame < 10 then
			local r = easing.inQuad(frame - 4, 3, -3, 10 - 4)
			inst.Light:SetRadius(r)
			inst.Light:Enable(true)
		else
			inst.Light:Enable(false)
			inst.components.updatelooper:RemoveOnUpdateFn(UpdateBeamLightPst)
		end
	else
		inst.Light:Enable(false)
		inst.components.updatelooper:RemoveOnUpdateFn(UpdateBeamLightPst)
	end
end

local function KillFx(inst)
	if inst:IsAsleep() then
		inst:Remove()
		return
	elseif inst.ring then
		inst.ring.AnimState:PlayAnimation("ground_marker_pst")
	end
	inst.AnimState:PlayAnimation("beam_pst")
	inst:ListenForEvent("animover", inst.Remove)
	inst.OnEntitySleep = inst.Remove
	inst.animsync:set_local(true)
	inst.animsync:set(true)
	inst.components.updatelooper:RemoveOnUpdateFn(UpdateBeamAOE)
	inst.components.updatelooper:AddOnUpdateFn(UpdateBeamLightPst)
	if next(inst.coloured2) then
		inst.components.updatelooper:AddOnUpdateFn(UpdateColouredFade)
		inst.fadet = 0
	end

	inst.SoundEmitter:KillSound("loop")
	inst.SoundEmitter:PlaySound("rifts5/wagstaff_boss/beam_down_pst")
end

--------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.Light:SetIntensity(0.5)
	inst.Light:SetFalloff(0.95)
	inst.Light:SetColour(0.01, 0.35, 1)
	inst.Light:Enable(false)

	inst.AnimState:SetBank("wagboss_beam")
	inst.AnimState:SetBuild("wagboss_beam")
	inst.AnimState:PlayAnimation("beam_pre")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(0.3)

	inst.animsync = net_bool(inst.GUID, "mountain_beam_fx.animsync", "animsyncdirty")
	inst.animsync:set(true)

	inst:SetPrefabNameOverride("mountain_golem")

	inst:AddComponent("updatelooper")

	if not TheNet:IsDedicated() then
		inst.ring = CreateRing()
		inst.ring.entity:SetParent(inst.entity)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("animsyncdirty", OnAnimSync_Client)
		OnAnimSync_Client(inst)

		return inst
	end

	inst.components.updatelooper:AddOnUpdateFn(UpdateBeamLightPre)

	inst.AnimState:PushAnimation("beam_loop")

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(0)
	inst.components.combat.ignorehitrange = true

	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.MOUNTAIN_GOLEM.LASER_PLANAR_DAMAGE)

	inst._initsoundtask = inst:DoTaskInTime(0, StartPreSound)
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), StartBeamAOE)
	inst:DoTaskInTime(6, KillFx)

	inst.TrackTarget = TrackTarget
	inst.TrackPoint = TrackPoint

	inst.persists = false

	return inst
end

return Prefab("mountain_beam_fx", fn, assets)
