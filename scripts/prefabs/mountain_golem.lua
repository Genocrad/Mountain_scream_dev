require("prefabutil")

local assets =
{
	Asset("ANIM", "anim/mountain_golem.zip"),
	Asset("ANIM", "anim/mountain_golem_actions.zip"),
	Asset("ANIM", "anim/mountain_golem_actions2.zip"),
	Asset("ANIM", "anim/mountain_golem_basic.zip"),
	Asset("ANIM", "anim/mountain_golem_speed.zip"),
}

local prefabs =
{
	"vault_pillar_guard_swipe_fx",
	"vault_pillar_guard_smash_fx",
	"mountain_sandspike_tall",
	"mountain_sandspike_charged_tall",
	"mountain_beam_fx",

	"mountain_sandblock",
	"mountain_sandblock_charged",
	"mountain_golem_ring",
	"mountain_golem_platform",
	--loot
	"thulecite",
	"thulecite_pieces",
	"rocks",
	"moonrocknugget",
	"mountain_transformation_cube",
}

local brain = require("brains/mountain_golembrain")

SetSharedLootTable("mountain_golem",
{
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				1 },
	{ "rocks",				1 },
	--
	{ "cutstone",		1 },
	{ "cutstone",		1 },
	{ "cutstone",		1 },
	{ "cutstone",		1 },
	--
	{ "mountain_transformation_cube", 1 },
})

--------------------------------------------------------------------------

local function RecycleDebris(fx)
	local inst = fx.owner
	if inst and inst:IsValid() then
		if inst.debrisfx == fx then
			inst.debrisfx = nil
		end
		table.removearrayvalue(inst.highlightchildren, fx)
		table.insert(inst.debrisfxpool, fx)
		fx:RemoveFromScene()
		fx.entity:SetParent(inst.entity)
		fx.Transform:SetPosition(0, 0, 0)
		fx.Transform:SetRotation(0)
	else
		fx:Remove()
	end
end

local function CreateDebris()
	local fx = CreateEntity()

	fx:AddTag("NOCLICK")
	fx:AddTag("decor")
	--[[Non-networked entity]]
	fx.entity:SetCanSleep(TheWorld.ismastersim)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()

	fx.AnimState:SetBank("mountain_golem")
	fx.AnimState:SetBuild("mountain_golem_basic") --this build only has debris symbols
	fx.AnimState:SetFinalOffset(1)

	fx:ListenForEvent("animover", RecycleDebris)

	return fx
end

local function DetachDebris(inst, recycle) --recycle nil when triggered via parent "onremove"
	if inst.debrisfx then
		if inst.debrisfx:IsValid() then
			inst.debrisfx:RemoveEventCallback("onremove", DetachDebris, inst)

			local t = inst.debrisfx.AnimState:GetCurrentAnimationTime()
			local len = inst.debrisfx.AnimState:GetCurrentAnimationLength()
			if t == 0 or --state changed b4 even started?
				len - t > 1 or --too much time remaining, long state (activate?) interrupted?
				t + FRAMES * 1.5 >= len --close enough to end
			then
				--just stop the fx immediately
				if recycle then
					RecycleDebris(inst.debrisfx)
				else
					table.removearrayvalue(inst.highlightchildren, inst.debrisfx)
					inst.debrisfx:Remove()
					inst.debrisfx = nil
				end
				return
			end
			--detach finish playing the fx
			inst.debrisfx.entity:SetParent(nil)
			inst.debrisfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.debrisfx.Transform:SetRotation(inst.Transform:GetRotation())
		end
		inst.debrisfx = nil
	end
end

local function DoDebris(inst)
	if inst.debrisanim:value() == inst.AnimState:GetCurrentAnimationHash() and not inst.AnimState:AnimDone() then
		if inst.debrisfxpool and #inst.debrisfxpool > 0 then
			inst.debrisfx = table.remove(inst.debrisfxpool)
			inst.debrisfx:ReturnToScene()
		else
			inst.debrisfx = CreateDebris()
			inst.debrisfx.owner = inst
			inst.debrisfx.entity:SetParent(inst.entity)
		end

		table.insert(inst.highlightchildren, inst.debrisfx)

		if inst.debrisnofaced:value() then
			inst.debrisfx.Transform:SetNoFaced()
		end
		inst.debrisfx.AnimState:PlayAnimation(inst.debrisanim:value())
		inst.debrisfx.AnimState:SetTime(inst.AnimState:GetCurrentAnimationTime())
		inst.debrisfx:ListenForEvent("onremove", DetachDebris, inst)
	end
end

local function PostUpdateDebris_Client(inst)
	inst._deferreddebris = false
	inst.components.updatelooper:RemovePostUpdateFn(PostUpdateDebris_Client)

	DoDebris(inst)
end

local function OnDebrisDirty_Client(inst)
	DetachDebris(inst, true)

	if not inst._deferreddebris then
		inst._deferreddebris = true
		inst.components.updatelooper:AddPostUpdateFn(PostUpdateDebris_Client)
	end
end

local function TriggerDebris(inst, show)
	if show then
		inst.debrisanim:set_local(0)
		inst.debrisanim:set(inst.AnimState:GetCurrentAnimationHash())
		inst.debrisnofaced:set(inst.sg.mem.nofaced or false)
	else
		inst.debrisanim:set(0)
	end

	if not TheNet:IsDedicated() then
		DetachDebris(inst, true)
		DoDebris(inst)
	end
end

local TARGET_MUST_TAGS = { "_combat" }
local TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "playerghost" }

local function RetargetFn(inst)
	return FindEntity(inst, TUNING.MOUNTAIN_GOLEM.DEAGGRO_DIST, function(guy)
		return inst.components.combat:CanTarget(guy)
	end, TARGET_MUST_TAGS, TARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target)
		and inst:IsNear(target, TUNING.MOUNTAIN_GOLEM.DEAGGRO_DIST)
end

local function OnAttacked(inst, data)
	if data and data.attacker and data.attacker:IsValid() then
		local target = inst.components.combat.target
		if target and (target.isplayer or target:HasTag("epic")) then
			local x, y, z = inst.Transform:GetWorldPosition()
			local range = TUNING.MOUNTAIN_GOLEM.ATTACK_RANGE + target:GetPhysicsRadius(0)
			if target:GetDistanceSqToPoint(x, y, z) < range * range then
				return
			end
		end

		inst.components.combat:SetTarget(data.attacker)
	end
end

--------------------------------------------------------------------------

local SYMBOL_LIGHT =
{
	normal =
	{
		fx_blue_part = 0.5,
		pg_eye_parts = 0.14,
		pg_top = 0.12,
		pg_shoulder = 0.09,
		pg_chest = 0.08,
		pg_pelvis = 0.05,
	},
	enraged =
	{
		fx_blue_part = 1,
		pg_eye_parts = 0.5,
		pg_top = 0.4,
		pg_shoulder = 0.3,
		pg_chest = 0.25,
		pg_pelvis = 0.18,
	},
}

local function ApplyEnrageGlow(inst, enraged)
	local t = enraged and SYMBOL_LIGHT.enraged or SYMBOL_LIGHT.normal
	for sym, val in pairs(t) do
		inst.AnimState:SetSymbolLightOverride(sym, val)
	end
	inst.AnimState:SetLightOverride(enraged and 0.25 or 0)
end

local function SetEnrageGlow(inst, enraged)
	if inst.enraged ~= nil then
		inst.enraged:set(enraged)
	end
	if not TheNet:IsDedicated() then
		ApplyEnrageGlow(inst, enraged)
	end
end

local function GetSpeedBoost(healthpct)
	local boost = TUNING.MOUNTAIN_GOLEM.SPEED_BOOST_PHASES[1].BOOST
	for i = #TUNING.MOUNTAIN_GOLEM.SPEED_BOOST_PHASES, 1, -1 do
		local v = TUNING.MOUNTAIN_GOLEM.SPEED_BOOST_PHASES[i]
		if healthpct <= v.HP then
			boost = v.BOOST
			break
		end
	end
	return boost
end

local function ApplySpeedBoost(inst, boost)
	if boost == nil then
		boost = GetSpeedBoost(inst.components.health:GetPercent())
	end
	local speed = TUNING.MOUNTAIN_GOLEM.SPEED * (1 + boost)
	inst.components.locomotor.walkspeed = speed
	inst.components.locomotor.runspeed = speed
end

local PHASES =
{
	{
		hp = 1,
		fn = function(inst)
			inst.canspin = false
			inst.canquickjump = false
			inst.fastattack = false
			SetEnrageGlow(inst, false)
		end,
	},
	{
		hp = 0.75,
		fn = function(inst)
			inst.canspin = true
			inst.canquickjump = false
			inst.fastattack = false
			SetEnrageGlow(inst, false)
		end,
	},
	{
		hp = 0.5,
		fn = function(inst)
			inst.canspin = true
			inst.canquickjump = true
			inst.fastattack = true
			SetEnrageGlow(inst, true)

			if not (POPULATING or inst.components.timer:TimerExists("stunned")) then
				inst.components.timer:StartTimer("stunned", TUNING.MOUNTAIN_GOLEM.MAX_STAGGER_TIME, true)
			end
		end,
	},
	{
		hp = 1 / 3,
		fn = function(inst)
			inst.canspin = true
			inst.canquickjump = true
			inst.fastattack = true

			if not POPULATING then
				local elapsed = inst.components.timer:GetTimeElapsed("stunned")
				if elapsed then
					if elapsed >= TUNING.MOUNTAIN_GOLEM.MIN_STAGGER_TIME or inst.components.timer:IsPaused("stunned") then
						inst.components.timer:StopTimer("stunned")
					else
						inst.components.timer:SetTimeLeft("stunned", TUNING.MOUNTAIN_GOLEM.MIN_STAGGER_TIME - elapsed)
					end
				end
			end
		end,
	},
}

local function OnNewTarget(inst, data)
	if data and data.oldtarget == nil then
		if inst.canspin then
			local cd = inst.components.timer:GetTimeLeft("spin_cd") or 0
			inst.components.timer:StopTimer("spin_cd")
			inst.components.timer:StartTimer("spin_cd", math.max(cd, (1 + math.random()) / 4 * TUNING.MOUNTAIN_GOLEM.SPIN_CD))
		end
		if inst.canquickjump then
			local cd = inst.components.timer:GetTimeLeft("quickjump_cd") or 0
			inst.components.timer:StopTimer("quickjump_cd")
			inst.components.timer:StartTimer("quickjump_cd", math.max(cd, (1 + math.random()) / 8 * TUNING.MOUNTAIN_GOLEM.QUICKJUMP_CD))
		end
	end
end

local function OnLoad(inst, data)--, ents)
	if inst.components.healthtrigger then
		local healthpct = inst.components.health:GetPercent()
		for i = #PHASES, 2, -1 do
			local v = PHASES[i]
			if healthpct <= v.hp then
				v.fn(inst)
				break
			end
		end
	end
	if inst.components.timer:TimerExists("stunned") and not inst.components.timer:IsPaused("stunned") then
		inst.sg:GoToState("stun_idle")
	end
	ApplySpeedBoost(inst)
end

--------------------------------------------------------------------------

local function RemoveProtectionRing(inst)
	if inst._ring ~= nil then
		if inst._ring:IsValid() then
			inst._ring:Remove()
		end
		inst._ring = nil
	end
end

local function UpdateProtectionRingLevel(inst)
	if inst._ring ~= nil and inst._ring:IsValid() then
		local level = math.min(inst._numtowers, TUNING.MOUNTAIN_GOLEM.RING_MAX_LEVEL)
		inst._ring:SetProtectionLevel(level)
	end
end

local function SpawnProtectionRing(inst)
	if inst._ring ~= nil then
		return
	end

	local ring = SpawnPrefab("mountain_golem_ring")
	if ring == nil then
		return
	end

	ring.entity:SetParent(inst.entity)
	ring.Transform:SetPosition(0, 0, 0)
	inst._ring = ring
	UpdateProtectionRingLevel(inst)
end

local function OnLoadPostPass(inst)
	if inst._ring == nil then
		SpawnProtectionRing(inst)
	else
		UpdateProtectionRingLevel(inst)
	end
end

local function UpdateTowerBonuses(inst)
	local n = inst._numtowers
	if n > 0 then
		local tower_absorb = math.min(TUNING.MOUNTAIN_GOLEM.TOWER_ABSORB_MAX, TUNING.MOUNTAIN_GOLEM.TOWER_ABSORB * n)
		inst.components.health:SetAbsorptionAmount(inst._tower_base_absorb + tower_absorb)
		if inst._towerhealtask == nil then
			inst._towerhealtask = inst:DoPeriodicTask(TUNING.MOUNTAIN_GOLEM.TOWER_HEAL_PERIOD, function()
				if inst.components.health ~= nil and not inst.components.health:IsDead() and inst._numtowers > 0 then
					inst.components.health:DoDelta(TUNING.MOUNTAIN_GOLEM.TOWER_HEAL * inst._numtowers, true, "mountain_sandblock_charged")
				end
			end)
		end
	else
		inst.components.health:SetAbsorptionAmount(inst._tower_base_absorb)
		if inst._towerhealtask ~= nil then
			inst._towerhealtask:Cancel()
			inst._towerhealtask = nil
		end
	end
	UpdateProtectionRingLevel(inst)
end

local function OnUnlinkMountainTower(inst, tower)
	if tower ~= nil and inst._towerlinks[tower] ~= nil then
		inst:RemoveEventCallback("onremove", inst._towerlinks[tower], tower)
		inst._towerlinks[tower] = nil
		inst._numtowers = inst._numtowers - 1
		UpdateTowerBonuses(inst)
	end
end

local function OnLinkMountainTower(inst, tower)
	if tower ~= nil and inst._towerlinks[tower] == nil then
		inst._numtowers = inst._numtowers + 1
		inst._towerlinks[tower] = function() OnUnlinkMountainTower(inst, tower) end
		inst:ListenForEvent("onremove", inst._towerlinks[tower], tower)
		UpdateTowerBonuses(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst:AddTag("monster")
	inst:AddTag("largecreature")
	inst:AddTag("hostile")
	inst:AddTag("soulless")
	inst:AddTag("mech")
	inst:AddTag("electricdamageimmune")
	inst:AddTag("epic")
	inst:AddTag("scarytoprey")
	inst:AddTag("crazy") -- so they can attack shadow creatures
	inst:AddTag("mountain_golem")

	inst.DynamicShadow:SetSize(6, 3.5)

	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("mountain_golem")
	inst.AnimState:SetBuild("mountain_golem")
	inst.AnimState:PlayAnimation("idle", true)

	inst.enraged = net_bool(inst.GUID, "mountain_golem.enraged", "enrageddirty")

	ApplyEnrageGlow(inst, false)

	inst:SetPhysicsRadiusOverride(1.6)
	MakeGiantCharacterPhysics(inst, 1000, inst.physicsradiusoverride)

	inst.debrisanim = net_hash(inst.GUID, "mountain_golem.debrisanim", "debrisdirty")
	inst.debrisnofaced = net_bool(inst.GUID, "mountain_golem.debrisnofaced")

	if not TheNet:IsDedicated() then
		inst.debrisfxpool = {}
		inst.highlightchildren = {}
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:AddComponent("updatelooper")
		inst:ListenForEvent("debrisdirty", OnDebrisDirty_Client)
		inst:ListenForEvent("enrageddirty", function()
			ApplyEnrageGlow(inst, inst.enraged:value())
		end)

		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.MOUNTAIN_GOLEM.SPEED
	inst.components.locomotor.runspeed = TUNING.MOUNTAIN_GOLEM.SPEED
	inst.components.locomotor.pathcaps = { ignorebridges = true }

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.MOUNTAIN_GOLEM.HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("drownable")

	inst:AddComponent("damagetypebonus")
	inst:AddComponent("damagetyperesist")

	inst:AddComponent("combat")
	inst.components.combat.playerdamagepercent = 0.25
	inst.components.combat.hiteffectsymbol = "pg_pelvis"
	inst.components.combat.forcefacing = false
	inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_GOLEM.DAMAGE)
	inst.components.combat:SetRange(TUNING.MOUNTAIN_GOLEM.ATTACK_RANGE)
	inst.components.combat:SetAttackPeriod(TUNING.MOUNTAIN_GOLEM.ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

	inst:AddComponent("healthtrigger")
	for i, v in ipairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end
	for i, v in ipairs(TUNING.MOUNTAIN_GOLEM.SPEED_BOOST_PHASES) do
		if v.HP < 1 then
			inst.components.healthtrigger:AddTrigger(v.HP, function(inst)
				ApplySpeedBoost(inst, v.BOOST)
			end)
		end
	end
	PHASES[1].fn(inst)
	ApplySpeedBoost(inst, TUNING.MOUNTAIN_GOLEM.SPEED_BOOST_PHASES[1].BOOST)

	inst:AddComponent("timer")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_golem")
	inst.components.lootdropper.min_speed = 2
	inst.components.lootdropper.max_speed = 4
	inst.components.lootdropper.y_speed = 4
	inst.components.lootdropper.y_speed_variance = 3
	inst.components.lootdropper.spawn_loot_inside_prefab = true

	inst:AddComponent("explosiveresist")

	inst:AddComponent("knownlocations")

	--MakeHugeFreezableCharacter(inst, "pg_pelvis")
	MakeHauntable(inst)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("linkmountaintower", OnLinkMountainTower)
	inst:ListenForEvent("unlinkmountaintower", OnUnlinkMountainTower)
	inst:ListenForEvent("death", RemoveProtectionRing)
	inst:ListenForEvent("onremove", function(inst)
		RemoveProtectionRing(inst)
		local ctrl = TheWorld.components.mountain_golem_platformctrl
		if ctrl ~= nil then
			ctrl:NotifySummonRemoved()
		end
	end)

	inst._towerlinks = {}
	inst._numtowers = 0
	inst._tower_base_absorb = inst.components.health.absorb or 0

	inst.SpawnProtectionRing = SpawnProtectionRing
	inst.TriggerDebris = TriggerDebris

	inst:SetStateGraph("SGmountain_golem")
	inst:SetBrain(brain)

	inst.OnLoad = OnLoad
	inst.OnLoadPostPass = OnLoadPostPass

	local ctrl = TheWorld.components.mountain_golem_platformctrl
	if ctrl ~= nil then
		ctrl:NotifySummonSpawned()
	end

	return inst
end

return Prefab("mountain_golem", fn, assets, prefabs)
