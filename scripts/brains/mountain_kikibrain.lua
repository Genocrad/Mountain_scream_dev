require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/chaseandattack"
local BrainCommon = require("brains/braincommon")

local RUN_AWAY_DIST = 7
local STOP_RUN_AWAY_DIST = 15

local SEE_ITEM_DISTANCE = 10

local MAX_WANDER_DIST = 20

local MAX_CHASE_TIME = 60
local MAX_CHASE_DIST = 40

local TIME_BETWEEN_EATING = 30

local NO_PICKUP_TAGS = { "INLIMBO", "catchable", "fire", "irreplaceable", "heavy", "outofreach", "spider", "mineactive", "_container" }

local PICKUP_ONEOF_TAGS = { "_inventoryitem", "pickable", "readyforharvest" }

local POOL_TAGS = { "mountain_crater_pool" }

local MountainKikiBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local function ShouldRunFn(inst, hunter)
	return (inst.components.combat.target ~= nil)
		and hunter.isplayer
		and inst.HasAmmo(inst)
end

local function IsBathing(inst)
	return inst.sg ~= nil and inst.sg:HasStateTag("soakin")
end

local ValidFoodsToPick =
{
	"berries",
	"cave_banana",
	"carrot",
	"red_cap",
	"blue_cap",
	"green_cap",
}

local function ItemIsInList(item, list)
	for k, v in pairs(list) do
		if v == item or k == item then
			return true
		end
	end
end

local function EatFoodAction(inst)
	if IsBathing(inst) or
			math.random() < .75 or
			inst.sg:HasStateTag("busy") or
			inst.components.combat:HasTarget() or
			(
				inst.components.eater:TimeSinceLastEating() ~= nil and
				inst.components.eater:TimeSinceLastEating() < TIME_BETWEEN_EATING
			) or (
				inst.components.inventory ~= nil and inst.components.inventory:IsFull()
			) then
		return
	elseif inst.components.inventory ~= nil and inst.components.eater ~= nil then
		local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
		if target ~= nil then
			return BufferedAction(inst, target, ACTIONS.EAT)
		end
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, SEE_ITEM_DISTANCE,
		nil,
		NO_PICKUP_TAGS,
		PICKUP_ONEOF_TAGS)

	for _, item in ipairs(ents) do
		if item:GetTimeAlive() > 8 and
				item.components.inventoryitem ~= nil and
				item.components.inventoryitem.canbepickedup and
				inst.components.eater:CanEat(item) and
				item:IsOnValidGround() then
			return BufferedAction(inst, item, ACTIONS.PICKUP)
		end
	end

	for _, item in ipairs(ents) do
		if item.components.pickable ~= nil and
			item.components.pickable.caninteractwith and
			item.components.pickable:CanBePicked() and
			(item.prefab == "worm" or ItemIsInList(item.components.pickable.product, ValidFoodsToPick)) then
			return BufferedAction(inst, item, ACTIONS.PICK)
		end
	end

	for _, item in ipairs(ents) do
		if item.components.crop ~= nil and
				item.components.crop:IsReadyForHarvest() then
			return BufferedAction(inst, item, ACTIONS.HARVEST)
		end
	end
end

local function GoHome(inst)
	if IsBathing(inst) then
		local pool = inst.sg.statemem.occupying_bathingpool
		if pool ~= nil and pool:IsValid() and pool.components.bathingpool ~= nil then
			pool.components.bathingpool:LeavePool(inst)
		end
	end
	if inst.components.combat ~= nil then
		inst.components.combat:SetTarget(nil)
	end
	local homeseeker = inst.components.homeseeker
	if homeseeker ~= nil and homeseeker.home ~= nil and homeseeker.home:IsValid()
			and (homeseeker.home.components.burnable == nil or not homeseeker.home.components.burnable:IsBurning()) then
		return BufferedAction(inst, homeseeker.home, ACTIONS.GOHOME)
	end
end

local function ShouldGoHome(inst)
	return TheWorld.state.iscavenight
end

local function CanTryBath(inst)
	return not TheWorld.state.iscavenight
		and not IsBathing(inst)
		and not inst.components.combat:HasTarget()
		and inst.components.timer ~= nil
		and not inst.components.timer:TimerExists("kiki_bath_cooldown")
		and math.random() < TUNING.MOUNTAIN_KIKI.BATH_CHANCE
end

local function DoSoakin(inst)
	if not CanTryBath(inst) then
		return
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	for _, pool in ipairs(TheSim:FindEntities(x, y, z, TUNING.MOUNTAIN_KIKI.BATH_SEARCH_RANGE, POOL_TAGS)) do
		if pool.components.bathingpool ~= nil
				and (pool.HasKikiBather == nil or not pool:HasKikiBather()) then
			return BufferedAction(inst, pool, ACTIONS.SOAKIN)
		end
	end
end

local function ExitHotSpring(inst)
	local pool = inst.sg.statemem.occupying_bathingpool
	if pool ~= nil and pool:IsValid() and pool.components.bathingpool ~= nil then
		pool.components.bathingpool:LeavePool(inst)
	end
end

local function EquipWeapon(inst, weapon)
	if weapon ~= nil and not weapon.components.equippable:IsEquipped() then
		inst.components.inventory:Equip(weapon)
	end
end

local function EquipThrower(inst)
	if inst.EquipThrower ~= nil then
		inst:EquipThrower()
	end
end

function MountainKikiBrain:OnStart()
	local root = PriorityNode(
	{
		BrainCommon.PanicTrigger(self.inst),
		BrainCommon.ElectricFencePanicTrigger(self.inst),

		EventNode(self.inst, "gohome", DoAction(self.inst, GoHome)),

		WhileNode(function() return ShouldGoHome(self.inst) end, "Go Home At Night",
			DoAction(self.inst, GoHome)),

		WhileNode(function() return IsBathing(self.inst) end, "Soaking",
			PriorityNode({
				IfNode(function() return TheWorld.state.iscavenight end, "Leave Pool At Night",
					ActionNode(function() ExitHotSpring(self.inst) end)),
				IfNode(function()
						return self.inst.components.timer ~= nil
							and not self.inst.components.timer:TimerExists("soaktime")
					end, "Leave Pool When Done",
					ActionNode(function() ExitHotSpring(self.inst) end)),
				WaitNode(1),
			})),

		RunAway(self.inst, "character", RUN_AWAY_DIST, STOP_RUN_AWAY_DIST,
				function(hunter) return ShouldRunFn(self.inst, hunter) end
			),
		WhileNode(function() return self.inst.components.combat.target and
								self.inst.HasAmmo(self.inst)
							end, "Ranged Attack",
			SequenceNode({
				ActionNode(function() EquipThrower(self.inst) end, "Equip Thrower"),
				ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
			})),

		WhileNode(function() return self.inst.components.combat.target and
								not self.inst.HasAmmo(self.inst)
							end, "Melee Attack",
			SequenceNode({
				ActionNode(function() EquipWeapon(self.inst, self.inst.weaponitems.hitter) end, "Equip hitter"),
				ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
			})),

		WhileNode(function() return not self.inst.components.combat.target
							end, "Should Eat",
			DoAction(self.inst, EatFoodAction)),

		WhileNode(function() return not self.inst.components.combat.target
							end, "Try Bath",
			DoAction(self.inst, DoSoakin, "soak in hot spring", true)),

		WhileNode(function() return not self.inst.components.combat.target
							end, "Wander Around Home",
			Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, MAX_WANDER_DIST))
	}, .25)
	self.bt = BT(self.inst, root)
end

return MountainKikiBrain
