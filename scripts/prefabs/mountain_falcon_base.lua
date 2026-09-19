local assets =
{
	Asset("ANIM", "anim/mountain_falcon_base.zip"),
}

local prefabs =
{
	"mountain_falcon",
}

SetSharedLootTable("mountain_falcon_base",
{
	{ "houndstooth", 1.00 },
	{ "houndstooth", 1.00 },
	{ "boneshard", 1.00 },
})

-- Manual SpawnChild works without spawning==true; this only restores the prior
-- auto-roam flag after a night hit/death release (when StopSpawning is active).
local function WithSpawningEnabled(spawner, fn)
	local was_spawning = spawner.spawning
	if not was_spawning then
		spawner:StartSpawning()
	end
	fn()
	if not was_spawning then
		spawner:StopSpawning()
	end
end

local function StartSpawning(inst)
	if inst.components.childspawner ~= nil then
		inst.components.childspawner:StartSpawning()
	end
end

local function StopSpawning(inst)
	if inst.components.childspawner ~= nil then
		inst.components.childspawner:StopSpawning()
	end
end

local function ReturnChildren(inst)
	if inst.components.childspawner == nil then
		return
	end
	for child in pairs(inst.components.childspawner.childrenoutside) do
		if child:IsValid() and child.RequestReturnHome ~= nil then
			child:RequestReturnHome()
		end
	end
end

-- Mountain floors live on the cave shard; use cave clock, not surface isday/isnight.
local function OnIsCaveDay(inst, iscaveday)
	if iscaveday then
		StartSpawning(inst)
	else
		StopSpawning(inst)
	end
end

local function OnIsCaveNight(inst, iscavenight)
	if iscavenight then
		ReturnChildren(inst)
	end
end

-- Flying birds don't need walkable ground; official SpawnChild otherwise
-- bails when FindWalkableOffset fails around the mound.
local function GetGuardSpawnOffset(inst)
	local theta = math.random() * TWOPI
	local r = 1 + math.random()
	return Vector3(r * math.cos(theta), 0, r * math.sin(theta))
end

local function RallyChild(child, attacker)
	if child == nil or not child:IsValid() then
		return
	end
	if child.components.health ~= nil and child.components.health:IsDead() then
		return
	end

	child._returning_home = false
	child._deaggro_pending = nil

	if child.sg ~= nil and not child.sg:HasStateTag("dead") then
		if child.sg:HasStateTag("flight") then
			child.DynamicShadow:Enable(true)
			if child.components.health ~= nil then
				child.components.health:SetInvincible(false)
			end
			child.Physics:Stop()
			local x, y, z = child.Transform:GetWorldPosition()
			if y > 1 then
				child.Transform:SetPosition(x, 0, z)
			end
			child.sg:GoToState("taunt")
		end
	end

	if attacker ~= nil and attacker:IsValid() then
		if child.RememberPursuitTarget ~= nil then
			child:RememberPursuitTarget(attacker)
		end
		if child.components.combat ~= nil then
			child.components.combat:SetTarget(attacker)
			child.components.combat:BlankOutAttacks(0.75 + math.random())
		end
	end
end

local function SpawnAllGuards(inst, attacker)
	if inst.components.health:IsDead() or inst.components.childspawner == nil then
		return
	end

	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle", false)

	local spawner = inst.components.childspawner

	-- SpawnChild refuses invincible attackers (including brief i-frames).
	-- Still spawn, then assign the real target afterwards.
	local spawn_target = attacker
	if spawn_target ~= nil
		and spawn_target.components.health ~= nil
		and spawn_target.components.health:IsInvincible() then
		spawn_target = nil
	end

	-- Daytime auto-roam empties childreninside. Hitting must still pull
	-- remaining inside birds AND aggro anyone already outside.
	if not spawner:CanSpawn() and spawner:CountChildrenOutside() == 0 and not spawner:IsFull() then
		spawner:AddChildrenInside(1)
	end

	local failures = 0
	while spawner:CanSpawn() and failures < 6 do
		local defender = spawner:SpawnChild(spawn_target, "mountain_falcon")
		if defender == nil then
			failures = failures + 1
		else
			failures = 0
			RallyChild(defender, attacker)
		end
	end

	if attacker ~= nil and attacker:IsValid() then
		for child in pairs(spawner.childrenoutside) do
			RallyChild(child, attacker)
		end
	end
end

local function OnKilled(inst)
	if inst.components.childspawner ~= nil then
		local spawner = inst.components.childspawner
		WithSpawningEnabled(spawner, function()
			spawner:ReleaseAllChildren()
		end)
	end

	RemovePhysicsColliders(inst)

	inst.AnimState:PlayAnimation("death", false)
	inst.SoundEmitter:KillSound("loop")
	inst.components.lootdropper:DropLoot(inst:GetPosition())
end

local function OnEntityWake(inst)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/mound_LP", "loop")
end

local function OnEntitySleep(inst)
	inst.SoundEmitter:KillSound("loop")
end

local function OnLoad(inst)
	if TheWorld.state.iscaveday then
		StartSpawning(inst)
	else
		StopSpawning(inst)
		if TheWorld.state.iscavenight then
			ReturnChildren(inst)
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	MakeObstaclePhysics(inst, .5)

	inst.AnimState:SetBank("mountain_falcon_base")
	inst.AnimState:SetBuild("mountain_falcon_base")
	inst.AnimState:PlayAnimation("idle")

	inst.MiniMapEntity:SetIcon("mountain_falcon_base.tex")

	inst:AddTag("structure")
	inst:AddTag("mountain_falcon_base")
	inst:AddTag("cavedweller")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.MOUNTAIN_FALCON_BASE.HEALTH)
	inst:ListenForEvent("death", OnKilled)

	local childspawner = inst:AddComponent("childspawner")
	childspawner.childname = "mountain_falcon"
	childspawner:SetRegenPeriod(TUNING.MOUNTAIN_FALCON_BASE.REGEN_PERIOD)
	childspawner:SetSpawnPeriod(TUNING.MOUNTAIN_FALCON_BASE.SPAWN_PERIOD)
	childspawner:SetMaxChildren(
		math.random(TUNING.MOUNTAIN_FALCON_BASE.CHILDREN_MIN, TUNING.MOUNTAIN_FALCON_BASE.CHILDREN_MAX)
	)
	local to_fill = childspawner.maxchildren - (childspawner.childreninside or 0)
	if to_fill > 0 then
		childspawner:AddChildrenInside(to_fill)
	end
	childspawner.overridespawnlocation = GetGuardSpawnOffset
	childspawner.spawnradius = { min = 1, max = 2 }
	childspawner:StartRegen()

	inst:WatchWorldState("iscaveday", OnIsCaveDay)
	inst:WatchWorldState("iscavenight", OnIsCaveNight)
	if TheWorld.state.iscaveday then
		StartSpawning(inst)
	else
		StopSpawning(inst)
	end

	inst:AddComponent("combat")
	inst.components.combat:SetOnHit(SpawnAllGuards)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_falcon_base")

	inst:AddComponent("inspectable")

	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("mountain_falcon_base", fn, assets, prefabs)
