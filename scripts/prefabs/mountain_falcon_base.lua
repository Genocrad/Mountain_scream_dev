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

local function SpawnGuardFalcon(inst, attacker)
	local defender = inst.components.childspawner:SpawnChild(attacker, "mountain_falcon")
	if defender ~= nil and attacker ~= nil and defender.components.combat ~= nil then
		defender.components.combat:SetTarget(attacker)
		defender.components.combat:BlankOutAttacks(1.5 + math.random() * 2)
	end
end

local function SpawnAllGuards(inst, attacker)
	if not inst.components.health:IsDead() and inst.components.childspawner ~= nil then
		inst.AnimState:PlayAnimation("hit")
		inst.AnimState:PushAnimation("idle", false)
		local num_to_release = inst.components.childspawner.childreninside
		for k = 1, num_to_release do
			SpawnGuardFalcon(inst, attacker)
		end
	end
end

local function OnKilled(inst)
	if inst.components.childspawner ~= nil then
		inst.components.childspawner:ReleaseAllChildren()
	end

	RemovePhysicsColliders(inst)

	inst.AnimState:PlayAnimation("death", false)
	inst.SoundEmitter:KillSound("loop")
	inst.components.lootdropper:DropLoot(inst:GetPosition())
end

local function OnEntityWake(inst)
	if inst.components.childspawner ~= nil then
		inst.components.childspawner:StartSpawning()
	end
	inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/mound_LP", "loop")
end

local function OnEntitySleep(inst)
	inst.SoundEmitter:KillSound("loop")
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

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.MOUNTAIN_FALCON_BASE.HEALTH)
	inst:ListenForEvent("death", OnKilled)

	inst:AddComponent("childspawner")
	inst.components.childspawner.childname = "mountain_falcon"
	inst.components.childspawner:SetRegenPeriod(TUNING.MOUNTAIN_FALCON_BASE.REGEN_PERIOD)
	inst.components.childspawner:SetSpawnPeriod(TUNING.MOUNTAIN_FALCON_BASE.SPAWN_PERIOD)
	inst.components.childspawner:SetMaxChildren(
		math.random(TUNING.MOUNTAIN_FALCON_BASE.CHILDREN_MIN, TUNING.MOUNTAIN_FALCON_BASE.CHILDREN_MAX)
	)
	inst.components.childspawner:StartRegen()

	inst:AddComponent("combat")
	inst.components.combat:SetOnHit(SpawnAllGuards)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_falcon_base")

	inst:AddComponent("inspectable")

	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake

	return inst
end

return Prefab("mountain_falcon_base", fn, assets, prefabs)
