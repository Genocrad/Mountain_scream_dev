require("behaviours/chaseandattack")
require("behaviours/leash")
require("behaviours/wander")
require("behaviours/faceentity")

local Mountain_ScreamerBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function GetHomePos(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function ShouldChase(inst)
	if inst._wants_despawn then
		return false
	end
	local home = GetHomePos(inst)
	if home == nil then
		return inst.components.combat.target ~= nil
	end
	local target = inst.components.combat.target
	return target ~= nil
		and target:GetDistanceSqToPoint(home) < TUNING.MOUNTAIN_SCREAMER.COMBAT_RANGE * TUNING.MOUNTAIN_SCREAMER.COMBAT_RANGE
end

local function ShouldReturnHome(inst)
	return inst._wants_despawn == true
end

local function GetEatTarget(inst)
	return inst.FindSkeleton ~= nil and inst:FindSkeleton() or nil
end

local function ShouldEat(inst)
	if inst._wants_despawn or inst.sg:HasStateTag("busy") then
		return false
	end
	if inst.components.health:GetPercent() >= 1 then
		return false
	end
	return GetEatTarget(inst) ~= nil
end

local function GetSkeletonPos(inst)
	local skel = GetEatTarget(inst)
	return skel ~= nil and skel:GetPosition() or nil
end

local function ShouldPointAtTarget(inst)
	local target = inst.components.combat.target
	if target == nil or inst._wants_despawn then
		return false
	end
	local home = GetHomePos(inst)
	if home == nil then
		return false
	end
	local x1, y1, z1 = target.Transform:GetWorldPosition()
	local dsq = distsq(x1, z1, home.x, home.z)
	local range = TUNING.MOUNTAIN_SCREAMER.COMBAT_RANGE
	if dsq >= range * range then
		return true
	end
	range = range - 4
	if dsq < range * range then
		return false
	elseif inst:GetDistanceSqToPoint(x1, y1, z1) < 16 then
		return false
	end
	return true
end

local function GetPointAtTargetFn(inst)
	return inst.components.combat.target
end

local function KeepPointAtTargetFn(inst, target)
	return inst.components.combat:TargetIs(target)
end

local function GetPointAtTargetPos(inst)
	local target = inst.components.combat.target
	if target then
		local home = GetHomePos(inst)
		if home then
			local x1, y1, z1 = target.Transform:GetWorldPosition()
			local dx = x1 - home.x
			local dz = z1 - home.z
			local len_sq = dx * dx + dz * dz
			if len_sq > 0 then
				local len = (TUNING.MOUNTAIN_SCREAMER.COMBAT_RANGE - 10) / math.sqrt(len_sq)
				return Vector3(home.x + dx * len, 0, home.z + dz * len)
			end
		end
	end
end

function Mountain_ScreamerBrain:OnStart()
	local root = PriorityNode({
		WhileNode(
			function() return not self.inst.sg:HasAnyStateTag("busy", "dead") end,
			"<not busy>",
			PriorityNode({
				-- 脱战回巢（到家后由 idle 触发 disappear）
				WhileNode(function() return ShouldReturnHome(self.inst) end, "return home",
					Leash(self.inst, GetHomePos, 2, 0.5)),

				-- 走近骷髅；贴近后由 idle/事件进入 eat
				WhileNode(function() return ShouldEat(self.inst) end, "eat skeleton",
					PriorityNode({
						Leash(self.inst, GetSkeletonPos, TUNING.MOUNTAIN_SCREAMER.EAT_DIST * 0.9, 0.5),
					}, 0.25)),

				WhileNode(function() return ShouldChase(self.inst) end, "chase and attack",
					ChaseAndAttack(self.inst)),

				WhileNode(function() return ShouldPointAtTarget(self.inst) end, "point at target",
					PriorityNode({
						Leash(self.inst, GetPointAtTargetPos, 6, 0.5),
						FaceEntity(self.inst, GetPointAtTargetFn, KeepPointAtTargetFn),
					}, 0.25)),

				Wander(self.inst, GetHomePos, 4, {
					minwalktime = 2,
					randwalktime = 1.5,
					minwaittime = 3,
					randwaittime = 2,
				}),
			}, 0.25)),
	}, 0.25)

	self.bt = BT(self.inst, root)
end

function Mountain_ScreamerBrain:OnInitializationComplete()
	self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition(), true)
end

return Mountain_ScreamerBrain
