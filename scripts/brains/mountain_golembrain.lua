require("behaviours/chaseandattack")
require("behaviours/faceentity")
require("behaviours/wander")

local Mountain_GolemBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function GetHomePos(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function GetPointAtTargetFn(inst)
	return inst.components.combat.target
end

local function KeepPointAtTargetFn(inst, target)
	return inst.components.combat:TargetIs(target) and not inst:IsNear(target, 4)
end

local function ShouldChase(inst)
	local home = GetHomePos(inst)
	if home == nil then
		return true
	end

	local target = inst.components.combat.target
	return target ~= nil and target:GetDistanceSqToPoint(home) < TUNING.MOUNTAIN_GOLEM.COMBAT_RANGE * TUNING.MOUNTAIN_GOLEM.COMBAT_RANGE
end

local function ShouldPointAtTarget(inst)
	local target = inst.components.combat.target
	if target == nil then
		return false
	end

	local home = GetHomePos(inst)
	if home == nil then
		return false
	end

	local x1, y1, z1 = target.Transform:GetWorldPosition()
	local dsq = math2d.DistSq(x1, z1, home.x, home.z)
	local range = TUNING.MOUNTAIN_GOLEM.COMBAT_RANGE
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
			local len = (TUNING.MOUNTAIN_GOLEM.COMBAT_RANGE - 10) / math.sqrt(dx * dx + dz * dz)
			return Vector3(home.x + dx * len, 0, home.z + dz * len)
		end
	end
end

function Mountain_GolemBrain:OnStart()
	local _ChaseAndAttackOrJump =
		ParallelNodeAny{
			ChaseAndAttack(self.inst),
			SequenceNode{
				WaitNode(4),
				ConditionWaitNode(function()
					local target = self.inst.components.combat.target
					if target and self.inst.canquickjump and self.inst:IsNear(target, 8) then
						self.inst:PushEvent("ms_pillarguard_quickjump", { target = target })
						return true
					end
					return false
				end, "quickjump"),
			},
		}

	local _Wander =
		Wander(self.inst, GetHomePos, 4, {
			minwalktime = 2.5,
			randwalktime = 1.5,
			minwaittime = 4,
			randwaittime = 2,
		})

	local root = PriorityNode({
		WhileNode(
			function() return not self.inst.sg:HasStateTag("jumping") end,
			"<busy state guard>",
			PriorityNode({
				WhileNode(function() return ShouldChase(self.inst) end, "chase and attack", _ChaseAndAttackOrJump),
				WhileNode(function() return ShouldPointAtTarget(self.inst) end, "point at target",
					PriorityNode({
						Leash(self.inst, GetPointAtTargetPos, 6, 0.5),
						FaceEntity(self.inst, GetPointAtTargetFn, KeepPointAtTargetFn),
					}, 0.25)),
				_Wander,
			}, 0.25)),
	}, 0.25)

	self.bt = BT(self.inst, root)
end

function Mountain_GolemBrain:OnInitializationComplete()
	self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition(), true)
end

return Mountain_GolemBrain
