require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/attackwall"
require "behaviours/doaction"
local BrainCommon = require("brains/braincommon")

local SEE_DIST = 30
local FINDFOOD_CANT_TAGS = { "INLIMBO", "outofreach" }

local HOUSE_MAX_DIST = 40
local HOUSE_RETURN_DIST = 50
local MAX_WANDER_DIST = 8

local MountainFalconBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function IsFoodValid(item, inst)
	return inst.components.eater:CanEat(item)
		and item:IsOnPassablePoint(true)
end

local function EatFoodAction(inst)
	if inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("wantstoeat") then
		return
	end
	local target = FindEntity(inst, SEE_DIST, IsFoodValid, nil, FINDFOOD_CANT_TAGS, inst.components.eater:GetEdibleTags())
	return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

local function GoHomeAction(inst)
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

local function GetLeashPos(inst)
	return GetHomePos(inst)
end

function MountainFalconBrain:OnStart()
	local root = PriorityNode({
		BrainCommon.PanicTrigger(self.inst),
		BrainCommon.ElectricFencePanicTrigger(self.inst),

		AttackWall(self.inst),

		WhileNode(function() return GetHome(self.inst) ~= nil end, "Has Home",
			ChaseAndAttack(self.inst, 10, 20)),
		WhileNode(function() return GetHome(self.inst) == nil end, "No Home",
			ChaseAndAttack(self.inst, 100)),

		WhileNode(function() return not TheWorld.state.isday end, "IsNight",
			DoAction(self.inst, GoHomeAction)),

		Leash(self.inst, GetLeashPos, HOUSE_MAX_DIST, HOUSE_RETURN_DIST),

		DoAction(self.inst, EatFoodAction, "eat food", true),

		WhileNode(function() return GetHome(self.inst) ~= nil end, "HasHome",
			Wander(self.inst, GetHomePos, MAX_WANDER_DIST)),
	}, .25)

	self.bt = BT(self.inst, root)
end

return MountainFalconBrain
