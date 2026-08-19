require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/attackwall"
require "behaviours/doaction"
require "behaviours/leash"
local BrainCommon = require("brains/braincommon")

local FINDFOOD_CANT_TAGS = { "INLIMBO", "outofreach" }

local MountainFalconBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function IsFoodValid(item, inst)
	return inst.components.eater:CanEat(item)
		and item:IsOnPassablePoint(true)
end

local function EatFoodAction(inst)
	if inst._returning_home or inst._cross_flooring then
		return
	end
	if inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("wantstoeat") then
		return
	end
	local target = FindEntity(
		inst,
		TUNING.MOUNTAIN_FALCON.SEE_FOOD_DIST,
		IsFoodValid,
		nil,
		FINDFOOD_CANT_TAGS,
		inst.components.eater:GetEdibleTags()
	)
	return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

local function GoHomeAction(inst)
	if inst._returning_home or inst._cross_flooring then
		return nil
	end
	return inst.components.homeseeker ~= nil
		and inst.components.homeseeker.home ~= nil
		and inst.components.homeseeker.home:IsValid()
		and inst.components.homeseeker.home.components.childspawner ~= nil
		and BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
		or nil
end

local function GetHome(inst)
	return inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
end

local function GetHomePos(inst)
	local home = GetHome(inst)
	return home ~= nil and home:GetPosition() or nil
end

local function HasCombatTarget(inst)
	return not inst._returning_home
		and not inst._cross_flooring
		and inst.components.combat ~= nil
		and inst.components.combat.target ~= nil
end

local function ShouldLeash(inst)
	return GetHome(inst) ~= nil
		and not HasCombatTarget(inst)
		and not inst._returning_home
		and not inst._cross_flooring
		and inst._pursuit_target == nil
end

function MountainFalconBrain:OnStart()
	local root = PriorityNode({
		BrainCommon.PanicTrigger(self.inst),
		BrainCommon.ElectricFencePanicTrigger(self.inst),

		AttackWall(self.inst),

		-- Same-floor chase only. Cross-floor is handled by the prefab pursuit tick
		-- (fly away → teleport near player → land → re-aggro).
		WhileNode(function() return HasCombatTarget(self.inst) end, "TerritoryPursuit",
			ChaseAndAttack(
				self.inst,
				TUNING.MOUNTAIN_FALCON.MAX_CHASE_TIME,
				TUNING.MOUNTAIN_FALCON.MAX_CHASE_DIST
			)),

		WhileNode(function()
				return not TheWorld.state.isday
					and not self.inst._returning_home
					and not self.inst._cross_flooring
					and self.inst._pursuit_target == nil
			end, "IsNight",
			DoAction(self.inst, GoHomeAction)),

		WhileNode(function() return ShouldLeash(self.inst) end, "PeaceLeash",
			Leash(
				self.inst,
				GetHomePos,
				TUNING.MOUNTAIN_FALCON.HOUSE_MAX_DIST,
				TUNING.MOUNTAIN_FALCON.HOUSE_RETURN_DIST
			)),

		DoAction(self.inst, EatFoodAction, "eat food", true),

		WhileNode(function()
				return GetHome(self.inst) ~= nil
					and not self.inst._returning_home
					and not self.inst._cross_flooring
					and self.inst._pursuit_target == nil
			end, "HasHome",
			Wander(self.inst, GetHomePos, TUNING.MOUNTAIN_FALCON.MAX_WANDER_DIST)),
	}, .25)

	self.bt = BT(self.inst, root)
end

return MountainFalconBrain
