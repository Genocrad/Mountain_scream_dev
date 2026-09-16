local assets =
{
	Asset("ANIM", "anim/mountain_kiki.zip"),
	Asset("SOUND", "sound/monkey.fsb"),
}

local prefabs =
{
	"mountain_kiki_ammo1",
	"mountain_kiki_projectile1",
	"mountain_kiki_projectile2",
	"mountain_kiki_projectile3",
	"smallmeat",
	"cave_banana",
	"beardhair",
}

local brain = require("brains/mountain_kikibrain")

local LOOT = { "smallmeat", "cave_banana" }

SetSharedLootTable("mountain_kiki",
{
	{ "meat",     1.00 },
	{ "ms_apple", 0.15 },
})

local AMMO_PREFAB = "mountain_kiki_ammo1"

local function HasAmmoItem(inst)
	return inst.components.inventory ~= nil
		and inst.components.inventory:FindItem(function(item) return item.prefab == AMMO_PREFAB end) ~= nil
end

local function PickRandomProjectile()
	local weights = TUNING.MOUNTAIN_KIKI_PROJECTILE.PROJECTILE_WEIGHTS
	local r = math.random()
	local cumulative = 0
	for _, entry in ipairs(weights) do
		cumulative = cumulative + entry.weight
		if r < cumulative then
			return entry.prefab
		end
	end
	return weights[#weights].prefab
end

local function PrepareThrower(inst, projectile)
	if projectile == nil or inst.weaponitems.thrower == nil then
		return nil
	end
	local thrower = inst.weaponitems.thrower
	if thrower.components.weapon ~= nil then
		thrower.components.weapon:SetProjectile(projectile)
	end
	return thrower
end

local function hasammo(inst)
	return inst.weaponitems.thrower ~= nil and HasAmmoItem(inst)
end

local function EquipWeapon(inst, weapon)
	if weapon ~= nil and weapon.components.equippable ~= nil then
		inst.components.inventory:Equip(weapon)
	end
end

local function EquipThrower(inst)
	local projectile = inst.sg ~= nil and inst.sg.statemem.throw_projectile or PickRandomProjectile()
	if inst.sg ~= nil then
		inst.sg.statemem.throw_projectile = projectile
	end
	local thrower = PrepareThrower(inst, projectile)
	if thrower ~= nil then
		EquipWeapon(inst, thrower)
	end
end

local function ConsumeAmmo(inst)
	if inst.components.inventory == nil then
		return false
	end
	local item = inst.components.inventory:FindItem(function(it) return it.prefab == AMMO_PREFAB end)
	if item == nil then
		return false
	end
	inst.components.inventory:RemoveItem(item)
	item:Remove()
	return true
end

local function LaunchThrow(inst)
	if inst.components.combat == nil or inst.weaponitems.thrower == nil then
		return
	end
	local target = inst.components.combat.target
	if (target == nil or not target:IsValid())
			and inst.sg ~= nil and inst.sg.statemem.throw_target ~= nil
			and inst.sg.statemem.throw_target:IsValid() then
		target = inst.sg.statemem.throw_target
	end
	if target == nil or not target:IsValid() then
		return
	end
	if not HasAmmoItem(inst) then
		return
	end
	local projectile = inst.sg ~= nil and inst.sg.statemem.throw_projectile or PickRandomProjectile()
	local thrower = PrepareThrower(inst, projectile)
	if thrower == nil or thrower.components.weapon == nil
			or thrower.components.weapon.projectile == nil then
		return
	end
	EquipWeapon(inst, thrower)
	if not ConsumeAmmo(inst) then
		return
	end
	thrower.components.weapon:LaunchProjectile(inst, target)
end

local function GiveDefaultAmmo(inst)
	if inst.components.inventory == nil then
		return
	end
	for _ = 1, TUNING.MOUNTAIN_KIKI.DEFAULT_AMMO_COUNT do
		local ammo = SpawnPrefab(AMMO_PREFAB)
		if ammo ~= nil then
			inst.components.inventory:GiveItem(ammo)
		end
	end
end

local function EquipWeapons(inst)
	if inst.components.inventory == nil then
		return
	end

	if inst.weaponitems.thrower == nil then
		local thrower = CreateEntity()
		thrower.name = "Thrower"
		thrower.entity:AddTransform()
		thrower:AddComponent("weapon")
		thrower.components.weapon:SetDamage(0)
		thrower.components.weapon:SetRange(TUNING.MOUNTAIN_KIKI.RANGED_RANGE)
		thrower.components.weapon:SetProjectile(TUNING.MOUNTAIN_KIKI_PROJECTILE.PROJECTILE_WEIGHTS[1].prefab)
		thrower:AddComponent("inventoryitem")
		thrower.persists = false
		thrower.components.inventoryitem:SetOnDroppedFn(inst.Remove)
		thrower:AddComponent("equippable")
		thrower:AddTag("nosteal")
		inst.components.inventory:GiveItem(thrower)
		inst.weaponitems.thrower = thrower
	end

	if inst.weaponitems.hitter == nil then
		local hitter = CreateEntity()
		hitter.name = "Hitter"
		hitter.entity:AddTransform()
		hitter:AddComponent("weapon")
		hitter.components.weapon:SetDamage(TUNING.MOUNTAIN_KIKI.MELEE_DAMAGE)
		hitter.components.weapon:SetRange(0)
		hitter:AddComponent("inventoryitem")
		hitter.persists = false
		hitter.components.inventoryitem:SetOnDroppedFn(inst.Remove)
		hitter:AddComponent("equippable")
		hitter:AddTag("nosteal")
		inst.components.inventory:GiveItem(hitter)
		inst.weaponitems.hitter = hitter
	end
end

local function GetHomePos(inst)
	if inst.components.homeseeker ~= nil and inst.components.homeseeker.home ~= nil and inst.components.homeseeker.home:IsValid() then
		return inst.components.homeseeker.home.Transform:GetWorldPosition()
	end
	if inst.components.knownlocations ~= nil then
		local home = inst.components.knownlocations:GetLocation("home")
		if home ~= nil then
			return home:Get()
		end
	end
	return nil
end

local MOUNTAIN_KIKI_TAGS = { "mountain_kiki" }

local function IsBathing(inst)
	return inst.sg ~= nil and inst.sg:HasStateTag("soakin")
end

local function EnsureObstacleCollision(inst, force)
	if inst.Physics == nil then
		return
	end
	if not force and IsBathing(inst) then
		return
	end
	local mask = inst.Physics:GetCollisionMask()
	if not force and mask ~= nil and bit.band(mask, COLLISION.OBSTACLES) ~= 0 then
		return
	end
	if inst.sg ~= nil then
		inst.sg.statemem.isphysicstoggle = nil
	end
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
	inst.Physics:CollidesWith(COLLISION.CHARACTERS)
	inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local function OnAttacked(inst, data)
	if IsBathing(inst) then
		if data.attacker ~= nil and data.attacker:HasTag("player") then
			if inst.sg ~= nil then
				inst.sg.statemem.attacked_while_bathing = true
				inst.sg.statemem.pending_attacker = data.attacker
			end
			local pool = inst.sg.statemem.occupying_bathingpool
			if pool ~= nil and pool:IsValid() and pool.components.bathingpool ~= nil then
				pool.components.bathingpool:LeavePool(inst)
			end
			if inst.sg ~= nil and inst.sg:HasStateTag("soakin") then
				inst.sg:GoToState("soakin_exit")
			else
				EnsureObstacleCollision(inst, true)
			end

			local x, y, z = inst.Transform:GetWorldPosition()
			local allies = TheSim:FindEntities(x, y, z, 30, MOUNTAIN_KIKI_TAGS)
			for _, ally in ipairs(allies) do
				if ally ~= inst and ally.components.combat ~= nil
						and ally.components.combat.target == nil
						and not IsBathing(ally) then
					ally.components.combat:SuggestTarget(data.attacker)
				end
			end
		end
		return
	end

	inst.components.combat:SetTarget(data.attacker)

	local x, y, z = inst.Transform:GetWorldPosition()
	local allies = TheSim:FindEntities(x, y, z, 30, MOUNTAIN_KIKI_TAGS)
	for _, ally in ipairs(allies) do
		if ally ~= inst and ally.components.combat ~= nil
				and ally.components.combat.target == nil
				and not IsBathing(ally) then
			ally.components.combat:SuggestTarget(data.attacker)
		end
	end
end

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "playerghost", "INLIMBO" }
local function IsKikiAggroPhase()
	return TheWorld.state.iscaveday or TheWorld.state.iscavedusk
end

local function retargetfn(inst)
	if not IsKikiAggroPhase() or IsBathing(inst) then
		return nil
	end
	return FindEntity(
		inst,
		TUNING.MOUNTAIN_KIKI.AGGRO_RANGE,
		function(guy)
			return guy:HasTag("player") and inst.components.combat:CanTarget(guy)
		end,
		RETARGET_MUST_TAGS,
		RETARGET_CANT_TAGS,
		{ "player" }
	)
end

local function shouldKeepTarget(inst, target)
	if IsBathing(inst) then
		return false
	end
	if not inst.components.combat:CanTarget(target) then
		return false
	end
	if target:HasTag("player") then
		if not target:IsNear(inst, TUNING.MOUNTAIN_KIKI.DEAGGRO_RANGE) then
			return false
		end
		local hx, hy, hz = GetHomePos(inst)
		if hx ~= nil then
			local ix, iy, iz = inst.Transform:GetWorldPosition()
			local leash = TUNING.MOUNTAIN_KIKI.HOME_LEASH_RANGE
			if distsq(ix, iz, hx, hz) > leash * leash then
				return false
			end
		end
	end
	return true
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst.DynamicShadow:SetSize(2, 1.25)

	inst.Transform:SetSixFaced()

	MakeCharacterPhysics(inst, 10, 0.25)

	inst.AnimState:SetBank("mountain_kiki")
	inst.AnimState:SetBuild("mountain_kiki_basic")
	inst.AnimState:PlayAnimation("idle_loop", true)

	inst:AddTag("cavedweller")
	inst:AddTag("mountain_kiki")
	inst:AddTag("animal")

	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end

	inst.override_combat_fx_height = "high"
	inst.soundtype = ""

	MakeMediumBurnableCharacter(inst)
	MakeMediumFreezableCharacter(inst)

	inst:AddComponent("bloomer")

	inst:AddComponent("inventory")

	inst:AddComponent("inspectable")

	local locomotor = inst:AddComponent("locomotor")
	locomotor:SetSlowMultiplier(1)
	locomotor:SetTriggersCreep(false)
	locomotor.pathcaps = { ignorecreep = false }
	locomotor.walkspeed = TUNING.MOUNTAIN_KIKI.MOVE_SPEED

	local combat = inst:AddComponent("combat")
	combat:SetAttackPeriod(TUNING.MOUNTAIN_KIKI.ATTACK_PERIOD)
	combat:SetRange(TUNING.MOUNTAIN_KIKI.MELEE_RANGE)
	combat:SetRetargetFunction(3, retargetfn)
	combat:SetKeepTargetFunction(shouldKeepTarget)
	combat:SetDefaultDamage(0)

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.MOUNTAIN_KIKI.HEALTH)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_kiki")

	inst:AddComponent("eater")
	inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })

	inst:AddComponent("sleeper")
	inst.components.sleeper.sleeptestfn = NocturnalSleepTest
	inst.components.sleeper.waketestfn = NocturnalWakeTest

	inst:SetBrain(brain)
	inst:SetStateGraph("SGmountain_kiki")

	inst:AddComponent("timer")

	inst.HasAmmo = hasammo
	inst.PickRandomProjectile = PickRandomProjectile
	inst.EquipThrower = EquipThrower
	inst.LaunchThrow = LaunchThrow

	inst:AddComponent("knownlocations")

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("entitywake", EnsureObstacleCollision)

	MakeHauntablePanic(inst)

	inst.weaponitems = {}
	EquipWeapons(inst)
	GiveDefaultAmmo(inst)

	return inst
end

return Prefab("mountain_kiki", fn, assets, prefabs)
