require("behaviours/chaseandattack")
require("behaviours/runaway")
require("behaviours/wander")
require("behaviours/doaction")
require("behaviours/useshield")

local BrainCommon = require("brains/braincommon")

local MAX_WANDER_DIST = 50
local HOME_WANDER_DIST = 8
local MAX_CHASE_DIST = 20
local MAX_CHASE_TIME = 8

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 5

local AVOID_PROJECTILE_ATTACKS = false

local EAT_CANT_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "outofreach" }

local function GetHome(inst)
	return inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
end

local function GetHomePos(inst)
	local home = GetHome(inst)
	return home ~= nil and home:GetPosition() or nil
end

local function GoHomeAction(inst)
	if inst.components.homeseeker ~= nil
		and inst.components.homeseeker.home ~= nil
		and inst.components.homeseeker.home:IsValid()
		and inst.components.homeseeker.home.components.childspawner ~= nil then
		return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME)
	end
end

local function GetWanderPoint(inst)
	local homepos = GetHomePos(inst)
	if homepos ~= nil then
		return homepos
	end
	return inst.components.knownlocations:GetLocation("home")
		or inst.components.knownlocations:GetLocation("spawnpoint")
end

local function EatFoodAction(inst)
	if inst.sg:HasStateTag("busy") then
		return nil
	end

	local target = FindEntity(inst, TUNING.MOUNTAIN_COCKROACH.SEE_FOOD_DIST, function(item)
		return item:IsOnPassablePoint()
			and inst.components.eater:CanEat(item)
	end, nil, EAT_CANT_TAGS, inst.components.eater:GetEdibleTags())

	return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end

local MountainCockroachBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function MountainCockroachBrain:OnStart()
	local root = PriorityNode({
		WhileNode(function() return not self.inst.sg:HasStateTag("jumping") end, "AttackAndWander",
			PriorityNode({
				BrainCommon.PanicTrigger(self.inst),

				UseShield(self.inst,
					TUNING.MOUNTAIN_COCKROACH.DAMAGE_UNTIL_SHIELD,
					TUNING.MOUNTAIN_COCKROACH.SHIELD_TIME,
					AVOID_PROJECTILE_ATTACKS),

				WhileNode(function()
					return self.inst.components.combat.target == nil
						or not self.inst.components.combat:InCooldown()
				end, "AttackMomentarily",
					ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

				WhileNode(function()
					return self.inst.components.combat.target ~= nil
						and self.inst.components.combat:InCooldown()
				end, "Dodge",
					RunAway(self.inst, function()
						return self.inst.components.combat.target
					end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)),

				DoAction(self.inst, EatFoodAction),

				EventNode(self.inst, "gohome",
					DoAction(self.inst, GoHomeAction, "go home", true)),

				WhileNode(function() return GetHome(self.inst) ~= nil end, "HasHome",
					Wander(self.inst, GetHomePos, HOME_WANDER_DIST, {
						minwalktime = .5,
						randwalktime = .5,
						minwaittime = 0,
						randwaittime = .2,
					})),

				Wander(self.inst, GetWanderPoint, MAX_WANDER_DIST, {
					minwalktime = .5,
					randwalktime = .5,
					minwaittime = 0,
					randwaittime = .2,
				}),
			}, .25)
		),
	}, .25)

	self.bt = BT(self.inst, root)
end

function MountainCockroachBrain:OnInitializationComplete()
	local pos = self.inst:GetPosition()
	if not self.inst.components.knownlocations:GetLocation("home") then
		self.inst.components.knownlocations:RememberLocation("home", pos, true)
	end
	if not self.inst.components.knownlocations:GetLocation("spawnpoint") then
		self.inst.components.knownlocations:RememberLocation("spawnpoint", pos, true)
	end
end

return MountainCockroachBrain
