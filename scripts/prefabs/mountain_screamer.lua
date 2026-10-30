local assets =
{
	Asset("ANIM", "anim/mountain_screamer.zip"),
}

local prefabs =
{
	"boneshard",
	"rocks",
	"warningshadow",
	"collapse_small",
	"ms_blood_fx",
	"ms_scream_fear",
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

--------------------------------------------------------------------------
-- 山域层号 / 坠落换层追击（刷出用 IsInstInMSOverWorld；追击用软校验，参考 falcon）
--------------------------------------------------------------------------

local TRANSIT_SG = {
	abyss_fall = true,
	abyss_drop = true,
	ms_umbrella_glide = true,
	ms_umbrella_glide_pst = true,
	ms_door_use = true,
	ms_door_use_pre = true,
}

local function GetMountainLevel(ent)
	if ent == nil or not ent:IsValid() then
		return nil
	end
	if ent.components.dungeonplayertracker ~= nil then
		return ent.components.dungeonplayertracker:GetLevel()
	end
	local overwatch = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch or nil
	if overwatch == nil then
		return nil
	end
	local x, y, z = ent.Transform:GetWorldPosition()
	return overwatch:GetNearestLevel(x, y, z)
end

local function IsMountainSurfaceLevel(level)
	return level ~= nil and level <= TUNING.MS_CAVES_START
end

-- 玩家掉到别层后若允许 EntitySleep，PeriodicTask/Brain 会停，永远追不上。
-- 追击中强制保持清醒（同 mountain_falcon）。
local function SetPursueCanSleep(inst, can_sleep)
	if inst._pursue_can_sleep == can_sleep then
		return
	end
	inst._pursue_can_sleep = can_sleep
	inst.entity:SetCanSleep(can_sleep)
end

local function IsActivelyPursuing(inst)
	if inst._wants_relocate then
		return true
	end
	if inst._stalking and inst._stalk_target ~= nil then
		return true
	end
	if inst._pursue_target ~= nil then
		return true
	end
	if inst._pursue_lost_since ~= nil then
		return true
	end
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	return target ~= nil
end

local function SyncPursueSleep(inst)
	SetPursueCanSleep(inst, not IsActivelyPursuing(inst))
end

local function RememberPursueTarget(inst, target)
	if target == nil or not target:IsValid() then
		return
	end
	inst._pursue_target = target
	local level = GetMountainLevel(target)
	-- 仅在拿到有效层号时刷新记忆；坠落中途 nil 不清 lost 计时
	if level ~= nil then
		inst._pursue_target_level = level
		inst._pursue_lost_since = nil
	end
	SetPursueCanSleep(inst, false)
end

local function ClearPursueMemory(inst)
	inst._pursue_target = nil
	inst._pursue_target_level = nil
	inst._pursue_lost_since = nil
	inst._wants_relocate = nil
	SyncPursueSleep(inst)
end

local function GetPursueTarget(inst)
	if inst._stalking then
		local target = inst._stalk_target
		if target ~= nil and target:IsValid() then
			return target
		end
		return nil
	end
	local target = inst.components.combat ~= nil and inst.components.combat.target or nil
	if target ~= nil and target:IsValid() then
		return target
	end
	target = inst._pursue_target
	if target ~= nil and target:IsValid() then
		return target
	end
	inst._pursue_target = nil
	return nil
end

-- 硬失效：死亡/鬼 / 进入深层洞穴 → 放弃
local function IsHardInvalidPursueTarget(target)
	if target == nil or not target:IsValid() then
		return true
	end
	if target:HasTag("playerghost") then
		return true
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return true
	end
	local level = GetMountainLevel(target)
	if level ~= nil and level > TUNING.MS_CAVES_START then
		return true
	end
	return false
end

-- 坠落/过门中：level 短暂为 nil，或仍在 abyss_fall 等 SG
local function IsPursueTargetInTransit(target)
	if target == nil or not target:IsValid() then
		return false
	end
	if target:HasTag("INLIMBO") then
		return true
	end
	if GetMountainLevel(target) == nil then
		return true
	end
	if target.sg ~= nil and target.sg.currentstate ~= nil and TRANSIT_SG[target.sg.currentstate.name] then
		return true
	end
	return false
end

-- 注视/交战追击软校验：不要求实时 IsInstInMSOverWorld（坠落中途会 false）
local function IsValidStalkTarget(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	if not target:HasTag("player") or target:HasTag("playerghost") then
		return false
	end
	if IsHardInvalidPursueTarget(target) then
		return false
	end
	-- 坠落中途粘住当前注视目标
	if IsPursueTargetInTransit(target) then
		return target == inst._stalk_target or target == inst._pursue_target
	end
	return IsMountainSurfaceLevel(GetMountainLevel(target))
end

local function NeedsPursueRelocate(inst, target)
	if target == nil or not target:IsValid() then
		return false
	end
	local cross = TUNING.MOUNTAIN_SCREAMER.CROSS_FLOOR_DIST
	if inst:GetDistanceSqToInst(target) >= cross * cross then
		return true
	end
	local my_level = GetMountainLevel(inst)
	local their_level = GetMountainLevel(target)
	if my_level ~= nil and their_level ~= nil and my_level ~= their_level then
		return true
	end
	local prev = inst._pursue_target_level
	if their_level ~= nil and prev ~= nil and their_level ~= prev then
		return true
	end
	-- 同层普通跟随距离（仅注视态）
	if inst._stalking then
		local follow = TUNING.MOUNTAIN_SCREAMER.STALK_FOLLOW_DIST
		if not inst:IsNear(target, follow) then
			return true
		end
	end
	return false
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
	-- 坠落落点附近地块查询可能失败：仍贴目标瞬移，避免放弃追击
	local theta = math.random() * TWOPI
	return Vector3(x + dist * math.cos(theta), 0, z + dist * math.sin(theta))
end

local function LeaveNow(inst)
	if inst.components.health:IsDead() then
		return
	end
	ClearPursueMemory(inst)
	-- leave 动画播完才 Remove；远距时若立刻允许 sleep 可能卡在 disappear
	SetPursueCanSleep(inst, false)
	inst:PushEvent("ms_screamer_leave")
end

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
	if IsHardInvalidPursueTarget(target) then
		return false
	end
	-- 交战粘性：掉崖换层 / level 短暂 nil / 远距都不丢仇，由 UpdatePursue 落地后再瞬移
	if inst._engaged and target == inst._pursue_target then
		return true
	end
	-- 坠落/过门中：短暂无法 CanTarget 也粘住
	if IsPursueTargetInTransit(target) and (target == inst._pursue_target or target == inst.components.combat.target) then
		return true
	end
	if not inst.components.combat:CanTarget(target) then
		return false
	end
	if inst:IsNear(target, TUNING.MOUNTAIN_SCREAMER.DEAGGRO_DIST) then
		return true
	end
	-- 山表层上目标已掉到别层：保持仇恨，由追击 tick 瞬移跟上
	local level = GetMountainLevel(target)
	if IsMountainSurfaceLevel(level) then
		return true
	end
	return false
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
	inst._leave_after_victory_laugh = nil
	inst.persists = true

	if attacker ~= nil and attacker:IsValid() then
		inst.components.combat:SetTarget(attacker)
		RememberPursueTarget(inst, attacker)
	end

	-- 同帧 SG attacked 处理器可能仍会跑到，避免把 taunt 顶成 hit
	inst._just_engaged_from_stalk = true
	if not inst.sg:HasStateTag("dead") then
		inst.sg:GoToState("taunt")
	end
end

-- 注视 / 交战共用：跨层或坠落落地后 disappear→appear 跟上
-- 尖啸中只记目标不跨层；其它 busy 排队 _wants_relocate，空闲再瞬移
local function UpdatePursue(inst)
	SyncPursueSleep(inst)

	if inst.components.health:IsDead() then
		return
	end
	if inst.sg ~= nil and (inst.sg:HasStateTag("dead") or inst.sg:HasStateTag("leaving")) then
		return
	end

	local target = GetPursueTarget(inst)
	if target == nil then
		inst._wants_relocate = nil
		SyncPursueSleep(inst)
		if inst._stalking then
			LeaveNow(inst)
		end
		return
	end

	if IsHardInvalidPursueTarget(target) then
		if inst._stalking then
			LeaveNow(inst)
		else
			ClearPursueMemory(inst)
			if inst.components.combat ~= nil and inst.components.combat.target == target then
				inst.components.combat:DropTarget()
			end
		end
		return
	end

	-- 坠落/过门中：粘住，等落地后再瞬移（避免出现在虚空）
	if IsPursueTargetInTransit(target) then
		RememberPursueTarget(inst, target)
		-- SG/INLIMBO 中的短暂 nil 不算丢失；长时间无层号才放弃（已离山）
		local sg_name = target.sg ~= nil and target.sg.currentstate ~= nil and target.sg.currentstate.name or nil
		local mid_fall = target:HasTag("INLIMBO") or (sg_name ~= nil and TRANSIT_SG[sg_name])
		if GetMountainLevel(target) == nil and not mid_fall then
			if inst._pursue_lost_since == nil then
				inst._pursue_lost_since = GetTime()
			elseif GetTime() - inst._pursue_lost_since >= TUNING.MOUNTAIN_SCREAMER.LOST_TARGET_TIME then
				if inst._stalking then
					LeaveNow(inst)
				else
					ClearPursueMemory(inst)
					if inst.components.combat ~= nil then
						inst.components.combat:DropTarget()
					end
				end
			end
		else
			inst._pursue_lost_since = nil
		end
		return
	end

	RememberPursueTarget(inst, target)

	-- 尖啸期间：继续尖啸，不做跨层 relocate
	if inst.sg ~= nil and inst.sg:HasStateTag("screaming") then
		return
	end

	if not NeedsPursueRelocate(inst, target) then
		inst._wants_relocate = nil
		return
	end

	-- 其它 busy（攻击/闪烁等）：排队，等 idle 再追
	if inst.sg ~= nil and inst.sg:HasStateTag("busy") then
		inst._wants_relocate = true
		SetPursueCanSleep(inst, false)
		return
	end

	inst._wants_relocate = nil
	SetPursueCanSleep(inst, false)
	inst:PushEvent("ms_screamer_stalkrelocate")
end

local function OnAttacked(inst, data)
	if data == nil or data.attacker == nil or not data.attacker:IsValid() then
		return
	end

	if inst._stalking then
		EngageFromStalk(inst, data.attacker)
		return
	end

	-- 尖啸期间：仅「铝器砸脸投掷」可打断（水平点地投 / 近战不行）
	if inst.sg ~= nil and inst.sg:HasStateTag("screaming") then
		if data.stimuli == "ms_aluminum_face_throw"
			and data.attacker:HasTag("player")
		then
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
		inst._leave_after_victory_laugh = nil
		RememberPursueTarget(inst, data.target)
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
		RememberPursueTarget(inst, next_target)
		return
	end

	local dropped = data ~= nil and data.target or nil
	if IsTargetDefeated(dropped) then
		ClearPursueMemory(inst)
		-- 脱战：击杀后先胜利笑；白天笑完再 leave
		inst._loiter_pos = inst:GetPosition()
		inst._wants_victory_laugh = true
		if not TheWorld.state.iscavenight then
			inst._leave_after_victory_laugh = true
		end
		inst:PushEvent("ms_screamer_victory")
		TryVictoryLaugh(inst)
		return
	end

	-- 掉崖/换层途中误丢仇：保留记忆并重挂目标，避免清记忆后白天 leave
	local mem = inst._pursue_target
	if mem ~= nil and mem:IsValid() and not IsHardInvalidPursueTarget(mem) then
		if IsPursueTargetInTransit(mem) or NeedsPursueRelocate(inst, mem) then
			inst.components.combat:SetTarget(mem)
			RememberPursueTarget(inst, mem)
			return
		end
	end

	ClearPursueMemory(inst)

	-- 脱战：白天离开；夜晚原地闲逛等天亮（玩家可复活继续挑战）
	inst._loiter_pos = inst:GetPosition()
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
	SetPursueCanSleep(inst, false)
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
	RememberPursueTarget(inst, player)

	if not inst.sg:HasStateTag("busy") then
		inst.sg:GoToState("appear")
	end
end

-- 仍有追击目标时拒绝休眠，否则掉层后停脑永远不 relocate
local function OnEntitySleep(inst)
	if IsActivelyPursuing(inst) then
		SetPursueCanSleep(inst, false)
		return
	end
	SetPursueCanSleep(inst, true)
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
	SyncPursueSleep(inst)
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

-- 熊獾式移动撞毁：碰撞时摧毁可锤/砍/挖/矿建筑
local function ClearRecentlyCharged(inst, other)
	inst.recentlycharged[other] = nil
end

local function OnOtherCollide(inst, other)
	if not other:IsValid() or inst.recentlycharged[other] then
		return
	elseif other:HasTag("smashable") and other.components.health ~= nil then
		other.components.health:Kill()
	elseif other.components.workable ~= nil
		and other.components.workable:CanBeWorked()
		and other.components.workable:GetWorkAction() ~= ACTIONS.NET
	then
		SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
		other.components.workable:Destroy(inst)
		if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
			inst.recentlycharged[other] = true
			inst:DoTaskInTime(3, ClearRecentlyCharged, other)
		end
	end
end

local function OnCollide(inst, other)
	if other ~= nil and other:IsValid() and Vector3(inst.Physics:GetVelocity()):LengthSq() >= 1 then
		inst:DoTaskInTime(2 * FRAMES, OnOtherCollide, other)
	end
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
	inst._pursue_can_sleep = true
	inst.recentlycharged = {}
	inst.Physics:SetCollisionCallback(OnCollide)

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
	-- 嘲讽仅开战前播一次（EngageFromStalk → taunt），战斗中不 BattleCry
	inst.components.combat.battlecryenabled = false

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
	inst.GetPursueTarget = GetPursueTarget
	inst.IsValidStalkTarget = IsValidStalkTarget

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("droppedtarget", OnDroppedTarget)

	inst:WatchWorldState("iscavenight", OnIsCaveNight)

	-- 注视/交战追击：坠落换层粘住 → 落地后瞬移；硬失效才离开
	inst:DoPeriodicTask(0.5, function(inst)
		if inst.components.health:IsDead() then
			return
		end

		if inst._stalking or (inst._engaged and GetPursueTarget(inst) ~= nil) then
			UpdatePursue(inst)
			if inst._stalking then
				return
			end
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
	inst.OnEntitySleep = OnEntitySleep

	return inst
end

return Prefab("mountain_screamer", fn, assets, prefabs)
