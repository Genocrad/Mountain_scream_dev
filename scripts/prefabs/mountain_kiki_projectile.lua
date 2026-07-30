local assets =
{
	Asset("ANIM", "anim/mountain_kiki_projectile.zip"),
}

local prefabs =
{
	"splash_snow_fx",
	"shatter",
}

local function ResolveAttacker(attacker)
	if attacker ~= nil and attacker:IsValid() then
		if attacker.components.combat == nil
				and attacker.components.weapon ~= nil
				and attacker.components.inventoryitem ~= nil then
			return attacker.components.inventoryitem.owner
		end
		return attacker
	end
	return nil
end

local function IsSoakingKiki(target)
	return target ~= nil and target:IsValid()
		and target:HasTag("mountain_kiki")
		and target.sg ~= nil
		and target.sg:HasStateTag("soakin")
end

-- 与官方 deerclops / mutateddeerclops 的 OnHitOther 一致：AddColdness + 降温 + 碎冰 FX
local function ApplyFreezeEffect(target, freezetime, freezepower)
	if target == nil or not target:IsValid() then
		return
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return
	end
	if target.components.freezable ~= nil then
		target.components.freezable:AddColdness(freezepower, freezetime)
		target.components.freezable:SpawnShatterFX()
	end
	if target.components.temperature ~= nil then
		local mintemp = math.max(target.components.temperature.mintemp, 0)
		local curtemp = target.components.temperature:GetCurrent()
		if mintemp < curtemp then
			target.components.temperature:DoDelta(math.max(-5, mintemp - curtemp))
		end
	end
end

local function MaybeFreezeTarget(target)
	if target == nil or not target:IsValid() then
		return
	end
	if math.random() >= TUNING.MOUNTAIN_KIKI_PROJECTILE.FREEZE_CHANCE then
		return
	end
	-- 延后一帧，避免同一次命中里 attacked / knockback 把 frozen 状态graph 顶掉
	local freezetime = TUNING.MOUNTAIN_KIKI_PROJECTILE.FREEZE_TIME
	local freezepower = TUNING.MOUNTAIN_KIKI_PROJECTILE.FREEZE_POWER
	target:DoTaskInTime(0, function()
		ApplyFreezeEffect(target, freezetime, freezepower)
	end)
end

local function OnHitIceSpike(inst, attacker, target)
	if IsSoakingKiki(target) then
		inst:Remove()
		return
	end
	attacker = ResolveAttacker(attacker)
	if target ~= nil and target:IsValid() then
		if target.components.combat ~= nil and attacker ~= nil then
			target.components.combat:GetAttacked(attacker, TUNING.MOUNTAIN_KIKI_PROJECTILE.ICE_SPIKE_DAMAGE)
		end
		target:PushEvent("knockback", {
			knocker = attacker or inst,
			radius = TUNING.MOUNTAIN_KIKI_PROJECTILE.KNOCKBACK_RADIUS,
			strengthmult = TUNING.MOUNTAIN_KIKI_PROJECTILE.KNOCKBACK_STRENGTH,
			forcelanded = true,
		})
		target:PushEvent("attacked", { attacker = attacker, damage = TUNING.MOUNTAIN_KIKI_PROJECTILE.ICE_SPIKE_DAMAGE })
		MaybeFreezeTarget(target)
	end
	inst:Remove()
end

local function OnHitSnowball(inst, attacker, target)
	if IsSoakingKiki(target) then
		inst:Remove()
		return
	end
	attacker = ResolveAttacker(attacker)
	if target ~= nil and target:IsValid() then
		MaybeFreezeTarget(target)
		target:PushEvent("attacked", { attacker = attacker, damage = 0 })
	end
	SpawnPrefab("splash_snow_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst:Remove()
end

local function OnHitSanitySnowball(inst, attacker, target)
	if IsSoakingKiki(target) then
		inst:Remove()
		return
	end
	attacker = ResolveAttacker(attacker)
	if target ~= nil and target:IsValid() and target:HasTag("player") then
		MaybeFreezeTarget(target)
		if target.components.sanity ~= nil then
			target.components.sanity:DoDelta(-TUNING.MOUNTAIN_KIKI_PROJECTILE.SANITY_SNOWBALL_SANITY_DAMAGE)
		end
		target:PushEvent("attacked", { attacker = attacker, damage = 0 })
	end
	SpawnPrefab("splash_snow_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst:Remove()
end

local function OnMissSnowball(inst, attacker, target)
	SpawnPrefab("splash_snow_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst:Remove()
end

local function OnMiss(inst, attacker, target)
	inst:Remove()
end

local function MakeProjectile(name, anim, onhit_fn, onmiss_fn)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		inst.Transform:SetFourFaced()

		MakeInventoryPhysics(inst)
		RemovePhysicsColliders(inst)

		inst.AnimState:SetBank("mountain_kiki_projectile")
		inst.AnimState:SetBuild("mountain_kiki_projectile")
		inst.AnimState:PlayAnimation(anim, true)

		inst:AddTag("projectile")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst.persists = false

		inst:AddComponent("projectile")
		inst.components.projectile:SetSpeed(TUNING.MOUNTAIN_KIKI_PROJECTILE.SPEED)
		inst.components.projectile:SetHoming(false)
		inst.components.projectile:SetHitDist(TUNING.MOUNTAIN_KIKI_PROJECTILE.HIT_DIST)
		inst.components.projectile:SetOnHitFn(onhit_fn)
		inst.components.projectile:SetOnMissFn(onmiss_fn or OnMiss)
		inst.components.projectile.range = TUNING.MOUNTAIN_KIKI_PROJECTILE.RANGE

		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

return MakeProjectile("mountain_kiki_projectile1", "idle1", OnHitIceSpike),
	MakeProjectile("mountain_kiki_projectile2", "idle2", OnHitSnowball, OnMissSnowball),
	MakeProjectile("mountain_kiki_projectile3", "idle3", OnHitSanitySnowball, OnMissSnowball)
