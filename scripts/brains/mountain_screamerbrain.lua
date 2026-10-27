require("behaviours/chaseandattack")
require("behaviours/leash")
require("behaviours/wander")
require("behaviours/faceentity")

local Mountain_ScreamerBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function ShouldChase(inst)
	if inst._stalking or inst._wants_victory_laugh then
		return false
	end
	return inst.components.combat.target ~= nil
end

local function GetEatTarget(inst)
	return inst.FindSkeleton ~= nil and inst:FindSkeleton() or nil
end

local function ShouldEat(inst)
	if inst._stalking or inst._wants_victory_laugh or inst.sg:HasStateTag("busy") then
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

local function ShouldStalk(inst)
	return inst._stalking == true
		and inst._stalk_target ~= nil
		and (inst.IsValidStalkTarget == nil or inst:IsValidStalkTarget(inst._stalk_target))
end

local function GetStalkTarget(inst)
	return inst._stalk_target
end

local function KeepStalkTarget(inst, target)
	return inst._stalking
		and target == inst._stalk_target
		and (inst.IsValidStalkTarget == nil or inst:IsValidStalkTarget(target))
end

-- 脱战后以脱战点为中心闲逛（无 home）
local function GetLoiterPos(inst)
	return inst._loiter_pos or inst:GetPosition()
end

function Mountain_ScreamerBrain:OnStart()
	local root = PriorityNode({
		WhileNode(
			function() return not self.inst.sg:HasAnyStateTag("busy", "dead") end,
			"<not busy>",
			PriorityNode({
				-- 夜间注视：只面向玩家
				WhileNode(function() return ShouldStalk(self.inst) end, "stalk stare",
					FaceEntity(self.inst, GetStalkTarget, KeepStalkTarget)),

				WhileNode(function() return not self.inst._stalking end, "not stalking",
					WhileNode(function() return not self.inst._wants_victory_laugh end, "not awaiting victory",
						PriorityNode({
							WhileNode(function() return ShouldEat(self.inst) end, "eat skeleton",
								PriorityNode({
									Leash(self.inst, GetSkeletonPos, TUNING.MOUNTAIN_SCREAMER.EAT_DIST * 0.9, 0.5),
								}, 0.25)),

							WhileNode(function() return ShouldChase(self.inst) end, "chase and attack",
								ChaseAndAttack(self.inst)),

							-- 脱战等待天亮：在脱战点附近闲逛，复活的玩家可被重新索敌
							Wander(self.inst, GetLoiterPos, 8, {
								minwalktime = 2,
								randwalktime = 1.5,
								minwaittime = 3,
								randwaittime = 2,
							}),
						}, 0.25)
					)
				),
			}, 0.25)
		),
	}, 0.25)

	self.bt = BT(self.inst, root)
end

return Mountain_ScreamerBrain
