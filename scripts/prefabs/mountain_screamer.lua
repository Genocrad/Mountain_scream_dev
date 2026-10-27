local assets =
{
	Asset("ANIM", "anim/mountain_screamer.zip"),
}

local prefabs =
{
	"boneshard",
	"rocks",
	"warningshadow",
}

local brain = require("brains/mountain_screamerbrain")

SetSharedLootTable("mountain_screamer",
{
	{ "rocks", 1 },
	{ "rocks", 1 },
	{ "rocks", 1 },
	{ "boneshard", 1 },
	{ "boneshard", 0.5 },
})

--------------------------------------------------------------------------

local TARGET_MUST_TAGS = { "_combat" }
local TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "playerghost", "mountain_screamer" }

local SKELETON_MUST_TAGS = { "skeleton" }
local SKELETON_CANT_TAGS = { "INLIMBO", "NOCLICK" }

local function RetargetFn(inst)
	if inst._stalking then
		return nil
	end
	return FindEntity(inst, TUNING.MOUNTAIN_SCREAMER.DEAGGRO_DIST, function(guy)
		return inst.components.combat:CanTarget(guy)
	end, TARGET_MUST_TAGS, TARGET_CANT_TAGS)
end

local function KeepTargetFn(inst, target)
	if inst._stalking then
		return false
	end
	return inst.components.combat:CanTarget(target)
		and inst:IsNear(target, TUNING.MOUNTAIN_SCREAMER.DEAGGRO_DIST)
end

local function IsValidStalkTarget(target)
	return target ~= nil
		and target:IsValid()
		and target:HasTag("player")
		and not target:HasTag("playerghost")
		and IsInstInMSOverWorld(target)
end

local function GetStalkRelocatePos(inst, target)
	if target == nil or not target:IsValid() then
		return nil
	end
	local x, y, z = target.Transform:GetWorldPosition()
	local min = TUNING.MOUNTAIN_SCREAMER.STALK_SPAWN_DIST_MIN
	local max = TUNING.MOUNTAIN_SCREAMER.STALK_SPAWN_DIST_MAX
	local dist = GetRandomMinMax(min, max)
	local offset = FindWalkableOffset(
		Vector3(x, 0, z),
		math.random() * TWOPI,
		dist,
		12,
		false,
		true
	)
	if offset ~= nil then
		return Vector3(x + offset.x, 0, z + offset.z)
	end
	local theta = math.random() * TWOPI
	return Vector3(x + dist * math.cos(theta), 0, z + dist * math.sin(theta))
end

local function LeaveNow(inst)
	if inst.components.health:IsDead() then
		return
	end
	inst:PushEvent("ms_screamer_leave")
end

local function EngageFromStalk(inst, attacker)
	if not inst._stalking or inst.components.health:IsDead() then
		return
	end

	inst._stalking = false
	inst._stalk_target = nil
	inst._engaged = true
	inst._wants_despawn = false
	inst._wants_victory_laugh = false
	inst.persists = true

	if attacker ~= nil and attacker:IsValid() then
		inst.components.combat:SetTarget(attacker)
	end

	-- 同帧 SG attacked 处理器可能仍会跑到，避免把 taunt 顶成 hit
	inst._just_engaged_from_stalk = true
	if not inst.sg:HasStateTag("dead") then
		inst.sg:GoToState("taunt")
	end
end

local function OnAttacked(inst, data)
	if data == nil or data.attacker == nil or not data.attacker:IsValid() then
		return
	end

	if inst._stalking then
		EngageFromStalk(inst, data.attacker)
		return
	end

	-- 尖啸期间：仅玩家攻击可打断
	if inst.sg ~= nil and inst.sg:HasStateTag("screaming") then
		if data.attacker:HasTag("player") then
			inst.components.combat:SetTarget(data.attacker)
			inst:PushEvent("ms_screamer_screambreak", { attacker = data.attacker })
		end
		return
	end

	local target = inst.components.combat.target
	if target ~= nil and (target.isplayer or target:HasTag("epic")) then
		local x, y, z = inst.Transform:GetWorldPosition()
		local range = TUNING.MOUNTAIN_SCREAMER.ATTACK_RANGE + target:GetPhysicsRadius(0)
		if target:GetDistanceSqToPoint(x, y, z) < range * range then
			return
		end
	end

	inst.components.combat:SetTarget(data.attacker)
end

local function IsTargetDefeated(target)
	if target == nil then
		return false
	end
	if not target:IsValid() then
		return true
	end
	if target:HasTag("playerghost") then
		return true
	end
	return target.components.health ~= nil and target.components.health:IsDead()
end

local function TryVictoryLaugh(inst)
	if not inst._wants_victory_laugh or inst.components.health:IsDead() then
		return
	end
	if inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("dead") then
		return
	end
	inst._wants_victory_laugh = false
	inst.sg:GoToState("laugh_pre", true)
end

local function OnNewTarget(inst, data)
	if inst._stalking then
		inst.components.combat:DropTarget()
		return
	end
	if data ~= nil and data.target ~= nil then
		inst._engaged = true
		inst._wants_despawn = false
		inst._wants_victory_laugh = false
	end
end

local function OnDroppedTarget(inst, data)
	if inst._stalking or not inst._engaged or inst.components.health:IsDead() then
		return
	end

	-- 仍有可打目标 → 立即换仇
	local next_target = RetargetFn(inst)
	if next_target ~= nil then
		inst.components.combat:SetTarget(next_target)
		return
	end

	-- 脱战：白天直接离开；夜晚原地闲逛等天亮（玩家可复活继续挑战）
	inst._loiter_pos = inst:GetPosition()
	if IsTargetDefeated(data ~= nil and data.target or nil) then
		inst._wants_victory_laugh = true
		inst:PushEvent("ms_screamer_victory")
		TryVictoryLaugh(inst)
	end
	if not TheWorld.state.iscavenight then
		inst:PushEvent("ms_screamer_leave")
	end
end

local function FindSkeleton(inst)
	if inst.components.health:IsDead() or inst.components.health:GetPercent() >= 1 then
		return nil
	end
	return FindEntity(inst, TUNING.MOUNTAIN_SCREAMER.EAT_RANGE, function(guy)
		return guy:IsValid() and not guy:IsInLimbo()
	end, SKELETON_MUST_TAGS, SKELETON_CANT_TAGS)
end

-- 正式开战（出场动画为 appear；瞬移再用 disappear / appearbig）
local function StartBattle(inst, pos)
	if inst.components.health:IsDead() then
		return
	end
	inst._stalking = false
	inst._stalk_target = nil
	inst._engaged = true
	inst._wants_despawn = false
	inst._wants_victory_laugh = false
	if pos ~= nil then
		inst.Physics:Teleport(pos.x, 0, pos.z)
	end
	if not inst.sg:HasStateTag("busy") then
		inst.sg:GoToState("appear")
	end
end

local function StartStalk(inst, player)
	if inst.components.health:IsDead() or player == nil or not player:IsValid() then
		return
	end

	inst._stalking = true
	inst._stalk_target = player
	inst._engaged = false
	inst._wants_despawn = false
	inst._wants_victory_laugh = false
	inst.persists = false
	inst.components.combat:DropTarget()

	if not inst.sg:HasStateTag("busy") then
		inst.sg:GoToState("appear")
	end
end

local function OnSave(inst, data)
	data.engaged = inst._engaged or nil
	data.wants_despawn = inst._wants_despawn or nil
	-- stalk encounters do not persist
end

local function OnLoad(inst, data)
	if data ~= nil then
		inst._engaged = data.engaged
		inst._wants_despawn = data.wants_despawn
	end
end

local function HasActiveCombatTarget(inst)
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if target == nil or not target:IsValid() or target:HasTag("playerghost") then
		return false
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return false
	end
	return true
end

-- 天亮离开：注视态，或已开战但当前没在打（闲逛等待中）
local function OnIsCaveNight(inst, iscavenight)
	if iscavenight or inst.components.health:IsDead() then
		return
	end
	if HasActiveCombatTarget(inst) then
		return
	end
	inst:PushEvent("ms_screamer_leave")
end

--------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("scarytoprey")
	inst:AddTag("largecreature")
	inst:AddTag("epic")
	inst:AddTag("mountain_screamer")

	inst.DynamicShadow:SetSize(4, 2.5)
	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("mountain_screamer")
	inst.AnimState:SetBuild("mountain_screamer")
	inst.AnimState:PlayAnimation("idle", true)

	inst:SetPhysicsRadiusOverride(1.2)
	MakeGiantCharacterPhysics(inst, 500, inst.physicsradiusoverride)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst._engaged = false
	inst._stalking = false
	inst._stalk_target = nil
	inst._wants_despawn = false
	inst._wants_victory_laugh = false

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.MOUNTAIN_SCREAMER.SPEED
	inst.components.locomotor.runspeed = TUNING.MOUNTAIN_SCREAMER.SPEED

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.MOUNTAIN_SCREAMER.HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")
	inst.components.combat.playerdamagepercent = 0.5
	inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_SCREAMER.DAMAGE)
	inst.components.combat:SetRange(TUNING.MOUNTAIN_SCREAMER.ATTACK_RANGE)
	inst.components.combat:SetAttackPeriod(TUNING.MOUNTAIN_SCREAMER.ATTACK_PERIOD)
	inst.components.combat:SetRetargetFunction(3, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	-- 官方方案：ChaseAndAttack → BattleCry → SG "taunt"；CD = interval + 0~3s
	inst.components.combat.battlecryenabled = true
	inst.components.combat.battlecryinterval = TUNING.MOUNTAIN_SCREAMER.TAUNT_CD

	inst:AddComponent("timer")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_screamer")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

	MakeHauntable(inst)

	inst.FindSkeleton = FindSkeleton
	inst.StartBattle = StartBattle
	inst.StartStalk = StartStalk
	inst.EngageFromStalk = EngageFromStalk
	inst.GetStalkRelocatePos = GetStalkRelocatePos
	inst.IsValidStalkTarget = IsValidStalkTarget

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("droppedtarget", OnDroppedTarget)

	inst:WatchWorldState("iscavenight", OnIsCaveNight)

	-- 注视态：目标失效/离开表层 → 离开；距离过远 → 跟随瞬移
	inst:DoPeriodicTask(0.5, function(inst)
		if inst.components.health:IsDead() then
			return
		end

		if inst._stalking then
			local target = inst._stalk_target
			if not IsValidStalkTarget(target) then
				LeaveNow(inst)
				return
			end
			if inst.sg:HasStateTag("busy") then
				return
			end
			local follow = TUNING.MOUNTAIN_SCREAMER.STALK_FOLLOW_DIST
			if not inst:IsNear(target, follow) then
				inst:PushEvent("ms_screamer_stalkrelocate")
			end
			return
		end

		TryVictoryLaugh(inst)
		if inst._wants_victory_laugh or inst.sg:HasStateTag("busy") then
			return
		end
		local skel = FindSkeleton(inst)
		if skel ~= nil and inst:IsNear(skel, TUNING.MOUNTAIN_SCREAMER.EAT_DIST) then
			inst:PushEvent("ms_screamer_eat", { target = skel })
		end
	end)

	inst:SetStateGraph("SGmountain_screamer")
	inst:SetBrain(brain)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("mountain_screamer", fn, assets, prefabs)
