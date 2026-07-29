local assets =
{
	Asset("ANIM", "anim/mountain_falcon.zip"),
	Asset("SOUND", "sound/bat.fsb"),
}

local prefabs =
{
	"mountain_monster_drumstick",
	"houndstooth",
}

local brain = require("brains/mountain_falconbrain")

SetSharedLootTable("mountain_falcon",
{
	{ "mountain_monster_drumstick", 1.000 },
	{ "mountain_monster_drumstick", 1.000 },
	{ "houndstooth", 0.125 },
})

local SHARE_TARGET_DIST = 30
local MAX_TARGET_SHARES = 5

local RETARGET_CANT_TAGS = { "wall", "mountain_falcon_base", "mountain_falcon" }
local RETARGET_ONEOF_TAGS = { "character", "monster" }

local function IsValidTarget(guy, inst)
	return inst.components.combat:CanTarget(guy)
end

local function Retarget(inst)
	return FindEntity(inst, TUNING.HOUND_TARGET_DIST, IsValidTarget, nil, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target)
end

local function IsFalcon(dude)
	return dude:HasTag("mountain_falcon")
end

local function OnAttacked(inst, data)
	local attacker = data and data.attacker or nil
	if attacker == nil then
		return
	end

	inst.components.combat:SetTarget(attacker)
	inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsFalcon, MAX_TARGET_SHARES)
end

local function OnAttackOther(inst, data)
	inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, IsFalcon, MAX_TARGET_SHARES)
end

local function DoReturn(inst)
	if inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome() then
		local home = inst.components.homeseeker.home
		if home ~= nil and home:IsValid() and home.components.childspawner ~= nil then
			home.components.childspawner:GoHome(inst)
		end
	end
end

local function OnEntitySleep(inst)
	if not TheWorld.state.isday then
		DoReturn(inst)
	end
end

local function OnStopDay(inst)
	if inst:IsAsleep() then
		DoReturn(inst)
	end
end

local function OnPreLoad(inst, data)
	local x, y, z = inst.Transform:GetWorldPosition()
	if y > 0 then
		inst.Transform:SetPosition(x, 0, z)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	MakeGhostPhysics(inst, 1, .5)

	inst.DynamicShadow:SetSize(1.5, .75)

	inst.Transform:SetFourFaced()
	inst.Transform:SetScale(.75, .75, .75)

	inst.AnimState:SetBank("mountain_falcon")
	inst.AnimState:SetBuild("mountain_falcon")

	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("mountain_falcon")
	inst:AddTag("scarytoprey")
	inst:AddTag("flying")
	inst:AddTag("ignorewalkableplatformdrowning")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.scrapbook_scale = 0.75

	local locomotor = inst:AddComponent("locomotor")
	locomotor:EnableGroundSpeedMultiplier(false)
	locomotor:SetTriggersCreep(false)
	locomotor.walkspeed = TUNING.HOUND_SPEED
	locomotor.runspeed = TUNING.HOUND_SPEED
	locomotor.pathcaps = { allowocean = true }

	inst:SetStateGraph("SGmountain_falcon")
	inst:SetBrain(brain)

	local eater = inst:AddComponent("eater")
	eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
	eater:SetStrongStomach(true)

	-- 支持排箫等催眠；不设自然入睡（夜间走回巢逻辑）
	local sleeper = inst:AddComponent("sleeper")
	sleeper:SetResistance(3)
	sleeper.sleeptestfn = nil

	local combat = inst:AddComponent("combat")
	combat.hiteffectsymbol = "bat_body"
	combat:SetDefaultDamage(TUNING.HOUND_DAMAGE)
	combat:SetAttackPeriod(TUNING.HOUND_ATTACK_PERIOD)
	combat:SetRetargetFunction(3, Retarget)
	combat:SetKeepTargetFunction(KeepTarget)
	combat:SetHurtSound("dontstarve/creatures/bat/hurt")
	combat.lastwasattackedtime = -math.huge

	local health = inst:AddComponent("health")
	health:SetMaxHealth(TUNING.HOUND_HEALTH)

	local lootdropper = inst:AddComponent("lootdropper")
	lootdropper:SetChanceLootTable("mountain_falcon")

	inst:AddComponent("inspectable")
	inst:AddComponent("knownlocations")

	MakeMediumBurnableCharacter(inst, "bat_body")
	MakeMediumFreezableCharacter(inst, "bat_body")

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)

	inst:WatchWorldState("stopday", OnStopDay)
	inst.OnEntitySleep = OnEntitySleep
	inst.OnPreLoad = OnPreLoad

	return inst
end

return Prefab("mountain_falcon", fn, assets, prefabs)
