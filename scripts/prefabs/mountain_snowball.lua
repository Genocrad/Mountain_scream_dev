local assets =
{
	Asset("ANIM", "anim/mountain_snowball.zip"),
}

local prefabs =
{
	"splash_snow_fx",
}

------------------------------------------------------------------------------------------------------------------------

local function OnEquip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "mountain_snowball", "swap_object")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function OnUnequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

------------------------------------------------------------------------------------------------------------------------

local function SpreadEffects(inst, target)
	if inst.components.wateryprotection ~= nil then
		if target ~= nil and target:IsValid() then
			inst.components.wateryprotection:SpreadProtection(target)
		else
			inst.components.wateryprotection:SpreadProtection(inst)
		end
	end

	local x, y, z
	if target ~= nil and target:IsValid() then
		x, y, z = target.Transform:GetWorldPosition()
	else
		x, y, z = inst.Transform:GetWorldPosition()
	end
	SpawnPrefab("splash_snow_fx").Transform:SetPosition(x, y, z)
end

local function OnHit(inst, attacker, target)
	if target ~= nil and target:IsValid() then
		if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
			target.components.sleeper:WakeUp()
		end

		if target.sg ~= nil and not target.sg:HasStateTag("frozen") then
			target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
		end
	end

	SpreadEffects(inst, target)
	inst:Remove()
end

local function OnMiss(inst, attacker, target)
	SpreadEffects(inst, nil)
	inst:Remove()
end

local function OnThrown(inst, owner, target)
	inst:AddTag("NOCLICK")
	inst.persists = false

	inst.AnimState:PlayAnimation("spin_loop", true)

	inst.Physics:SetMass(1)
	inst.Physics:SetFriction(.1)
	inst.Physics:SetDamping(0)
	inst.Physics:SetRestitution(.5)
	inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
	inst.Physics:SetCollisionMask(COLLISION.GROUND)
	inst.Physics:SetSphere(.5)

	inst.components.inventoryitem.pushlandedevents = false
	inst.components.projectile:DelayVisibility(2 * FRAMES)

	inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/firesupressor_shoot")
end

------------------------------------------------------------------------------------------------------------------------

local function OnPerish(inst)
	local owner = inst.components.inventoryitem.owner
	local stacksize = inst.components.stackable ~= nil and inst.components.stackable:StackSize() or 1

	if owner ~= nil then
		DoDeltaMoistureToEntity(owner, stacksize, TUNING.MOUNTAIN_SNOWBALL.MELT_MOISTURE_ITEMS, true)
		inst:Remove()
	else
		local x, y, z = inst.Transform:GetWorldPosition()
		TheWorld.components.farming_manager:AddSoilMoistureAtPoint(x, 0, z, stacksize * TUNING.MOUNTAIN_SNOWBALL.MELT_MOISTURE_GROUND)
		inst:Remove()
	end
end

local function OnFireMelt(inst)
	inst.components.perishable.frozenfiremult = true
end

local function OnStopFireMelt(inst)
	inst.components.perishable.frozenfiremult = false
end

local function OnUseAsWaterSource(inst)
	if inst.components.stackable ~= nil then
		inst.components.stackable:Get():Remove()
	else
		inst:Remove()
	end
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_snowball")
	inst.AnimState:SetBuild("mountain_snowball")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("frozen")
	inst:AddTag("icebox_valid")
	inst:AddTag("extinguisher")
	inst:AddTag("show_spoilage")
	inst:AddTag("watersource")
	inst:AddTag("weapon")
	inst:AddTag("projectile")

	MakeInventoryFloatable(inst, "small", 0.05, .8)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("tradable")
	inst:AddComponent("smotherer")
	inst:AddComponent("inspectable")

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.MOUNTAIN_SNOWBALL.PERISH_TIME)
	inst.components.perishable:StartPerishing()
	inst.components.perishable:SetOnPerishFn(OnPerish)

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_snowball"
	inst.components.inventoryitem:SetOnPutInInventoryFn(OnStopFireMelt)

	inst:AddComponent("watersource")
	inst.components.watersource.onusefn = OnUseAsWaterSource
	inst.components.watersource.override_fill_uses = TUNING.MOUNTAIN_SNOWBALL.WATERSOURCE_FILL_USES

	inst:AddComponent("wateryprotection")
	inst.components.wateryprotection.extinguishheatpercent = TUNING.MOUNTAIN_SNOWBALL.EXTINGUISH_HEAT_PERCENT
	inst.components.wateryprotection.temperaturereduction = TUNING.MOUNTAIN_SNOWBALL.TEMP_REDUCTION
	inst.components.wateryprotection.witherprotectiontime = TUNING.MOUNTAIN_SNOWBALL.PROTECTION_TIME
	inst.components.wateryprotection.addcoldness = TUNING.MOUNTAIN_SNOWBALL.ADD_COLDNESS
	inst.components.wateryprotection.protection_dist = TUNING.MOUNTAIN_SNOWBALL.EFFECTS_DIST
	inst.components.wateryprotection:AddIgnoreTag("player")

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(0)
	inst.components.weapon:SetRange(TUNING.MOUNTAIN_SNOWBALL.WEAPON_RANGE, TUNING.MOUNTAIN_SNOWBALL.WEAPON_HIT_RANGE)

	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(TUNING.MOUNTAIN_SNOWBALL.PROJECTILE_SPEED)
	inst.components.projectile:SetOnHitFn(OnHit)
	inst.components.projectile:SetOnThrownFn(OnThrown)
	inst.components.projectile:SetOnMissFn(OnMiss)
	inst.components.projectile:SetHitDist(TUNING.MOUNTAIN_SNOWBALL.HIT_DIST)
	inst.components.projectile:SetRange(TUNING.MOUNTAIN_SNOWBALL.PROJECTILE_RANGE)

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnequip)
	inst.components.equippable.equipstack = true

	inst:ListenForEvent("firemelt", OnFireMelt)
	inst:ListenForEvent("stopfiremelt", OnStopFireMelt)

	MakeHauntableLaunchAndSmash(inst)

	return inst
end

return Prefab("mountain_snowball", fn, assets, prefabs)
