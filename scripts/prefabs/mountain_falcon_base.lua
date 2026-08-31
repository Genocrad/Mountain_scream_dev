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

local function SpawnAllGuards(inst, attacker)
	if inst.components.health:IsDead() or inst.components.childspawner == nil then
		return
	end

	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("idle", false)

	local spawner = inst.components.childspawner
	local num_to_release = spawner.childreninside
	if num_to_release <= 0 then
		return
	end

	WithSpawningEnabled(spawner, function()
		for _ = 1, num_to_release do
			local defender = spawner:SpawnChild(attacker, "mountain_falcon")
			if defender ~= nil and attacker ~= nil and defender.components.combat ~= nil then
				if defender.RememberPursuitTarget ~= nil then
					defender:RememberPursuitTarget(attacker)
				end
				defender.components.combat:SetTarget(attacker)
				defender.components.combat:BlankOutAttacks(1.5 + math.random() * 2)
			end
		end
	end)
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
