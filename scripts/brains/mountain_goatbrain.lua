require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/attackwall"

local BrainCommon = require("brains/braincommon")

local WANDER_DIST_DAY = 20
local WANDER_DIST_NIGHT = 5
local MAX_CHASE_TIME = 6

local RUN_AWAY_DIST = 8
local STOP_RUN_AWAY_DIST = 12
local START_FACE_DIST = 10
local KEEP_FACE_DIST = 14

local HUNTER_PARAMS = { tags = { "character" }, notags = { "notarget" } }

local function GetFaceTargetFn(inst)
	local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
	return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
	return not target:HasTag("notarget")
		and inst:IsNear(target, KEEP_FACE_DIST)
end

local function GetWanderDistFn(inst)
	return TheWorld.state.isday and WANDER_DIST_DAY or WANDER_DIST_NIGHT
end

local function GetWanderHome(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

local MountainGoatBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function MountainGoatBrain:OnStart()
	local root =
	PriorityNode({
		BrainCommon.PanicTrigger(self.inst),
		IfNode(function() return self.inst.components.combat.target ~= nil end, "hastarget", AttackWall(self.inst)),
		ChaseAndAttack(self.inst, MAX_CHASE_TIME),
		SequenceNode{
			FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn, 0.25),
			RunAway(self.inst, HUNTER_PARAMS, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
		},
		FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
		Wander(self.inst, GetWanderHome, GetWanderDistFn),
	}, .25)

	self.bt = BT(self.inst, root)
end

function MountainGoatBrain:OnInitializationComplete()
	self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
end

return MountainGoatBrain
