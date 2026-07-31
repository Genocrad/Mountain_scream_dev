local GoatCommon = {}

function GoatCommon.CaptureState(inst)
	return {
		rotation = inst.Transform:GetRotation(),
		health_percent = inst.components.health ~= nil and inst.components.health:GetPercent() or 1,
		target = inst.components.combat ~= nil and inst.components.combat.target or nil,
		spawnpoint = inst.components.knownlocations ~= nil and inst.components.knownlocations:GetLocation("spawnpoint") or nil,
		herd = inst.components.herdmember ~= nil and inst.components.herdmember:GetHerd() or nil,
	}
end

function GoatCommon.ApplyState(inst, data)
	if data == nil then
		return
	end
	if data.rotation ~= nil then
		inst.Transform:SetRotation(data.rotation)
	end
	if data.health_percent ~= nil and inst.components.health ~= nil then
		inst.components.health:SetPercent(data.health_percent)
	end
	if data.spawnpoint ~= nil and inst.components.knownlocations ~= nil then
		inst.components.knownlocations:RememberLocation("spawnpoint", data.spawnpoint, false)
	end
	if data.target ~= nil and data.target:IsValid() and inst.components.combat ~= nil then
		inst.components.combat:SetTarget(data.target)
	end
	if data.herd ~= nil and data.herd:IsValid() and data.herd.components.herd ~= nil then
		data.herd.components.herd:AddMember(inst)
	end
end

function GoatCommon.PlayTransformFX(inst)
	if inst.components.freezable ~= nil then
		inst.components.freezable:SpawnShatterFX()
	else
		local x, y, z = inst.Transform:GetWorldPosition()
		local fx = SpawnPrefab("splash_snow_fx")
		if fx ~= nil then
			fx.Transform:SetPosition(x, y, z)
		end
	end
end

-- opts.seasonal: winter-driven ice form (no 3-day thaw)
-- opts.thaw_time: remaining temporary ice duration (seconds)
function GoatCommon.Transform(inst, newprefab, opts)
	if inst._goat_transforming
			or not inst:IsValid()
			or (inst.components.health ~= nil and inst.components.health:IsDead())
			or inst.prefab == newprefab then
		return inst
	end

	inst._goat_transforming = true
	opts = opts or {}

	local state = GoatCommon.CaptureState(inst)

	-- Prevent herd OnEmpty→Remove while this member is mid-replace.
	local herd = state.herd
	local onempty
	if herd ~= nil and herd:IsValid() and herd.components.herd ~= nil then
		onempty = herd.components.herd.onempty
		herd.components.herd.onempty = nil
	end

	GoatCommon.PlayTransformFX(inst)

	local new = ReplacePrefab(inst, newprefab)
	if new == nil then
		if herd ~= nil and herd:IsValid() and herd.components.herd ~= nil then
			herd.components.herd.onempty = onempty
			if herd.components.herd.membercount == 0 and onempty ~= nil then
				onempty(herd)
			end
		end
		return nil
	end

	GoatCommon.ApplyState(new, state)

	if herd ~= nil and herd:IsValid() and herd.components.herd ~= nil then
		herd.components.herd.onempty = onempty
	end

	if new.OnTransformed ~= nil then
		new:OnTransformed(opts)
	end

	if new.sg ~= nil and not new.sg:HasStateTag("busy") then
		new.sg:GoToState("taunt")
	end

	return new
end

function GoatCommon.KeepTargetFn(inst, target)
	local herd = inst.components.herdmember ~= nil and inst.components.herdmember:GetHerd() or nil
	if herd ~= nil then
		return inst:IsNear(herd, TUNING.MOUNTAIN_GOAT.CHASE_DIST)
	end
	local spawnpoint = inst.components.knownlocations ~= nil and inst.components.knownlocations:GetLocation("spawnpoint") or nil
	if spawnpoint == nil then
		return true
	end
	local dist = TUNING.MOUNTAIN_GOAT.CHASE_DIST
	return inst:GetDistanceSqToPoint(spawnpoint:Get()) < dist * dist
end

function GoatCommon.KnockbackPlayer(inst, target)
	if target == nil or not target:IsValid() or not target:HasTag("player") then
		return
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return
	end
	target:PushEvent("knockback", {
		knocker = inst,
		radius = TUNING.MOUNTAIN_GOAT.KNOCKBACK_RADIUS,
		strengthmult = TUNING.MOUNTAIN_GOAT.KNOCKBACK_STRENGTH,
		forcelanded = false,
	})
end

function GoatCommon.FullyFreeze(target)
	if target == nil or not target:IsValid() then
		return
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return
	end
	if target.components.freezable == nil then
		return
	end
	local freezetime = TUNING.MOUNTAIN_ICEGOAT.FREEZE_TIME
	local resistance = target.components.freezable:ResolveResistance()
	target.components.freezable:AddColdness(resistance, freezetime)
	target.components.freezable:SpawnShatterFX()
end

function GoatCommon.PartialFreeze(target, percent)
	if target == nil or not target:IsValid() then
		return
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return
	end
	if target.components.freezable == nil then
		return
	end
	local resistance = target.components.freezable:ResolveResistance()
	local coldness = math.max(0.1, resistance * (percent or TUNING.MOUNTAIN_ICEGOAT.PARTIAL_FREEZE_PERCENT))
	target.components.freezable:AddColdness(coldness)
	target.components.freezable:SpawnShatterFX()
end

function GoatCommon.TryFreezeOnHit(target)
	if target == nil or not target:IsValid() or target.components.freezable == nil then
		return
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return
	end
	if math.random() < TUNING.MOUNTAIN_ICEGOAT.FULL_FREEZE_CHANCE then
		GoatCommon.FullyFreeze(target)
	else
		GoatCommon.PartialFreeze(target, TUNING.MOUNTAIN_ICEGOAT.PARTIAL_FREEZE_PERCENT)
	end
end

return GoatCommon
