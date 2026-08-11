------------------------------------------------------------------------------------------------------------------------
-- 地牢传送门：USE DOOR

local UpvalueHacker = require("tools/upvaluehacker")

local MS_USE_DOOR = Action({ priority = 10 })
MS_USE_DOOR.id = "MS_USE_DOOR"
MS_USE_DOOR.str = "Enter"
MS_USE_DOOR.fn = function(act)
	act.doer.sg:GoToState("ms_door_use", { teleporter = act.target })
	return true
end

AddAction(MS_USE_DOOR)

local COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
local old_teleport = COMPONENT_ACTIONS["SCENE"]["teleporter"]
COMPONENT_ACTIONS["SCENE"]["teleporter"] = function(inst, doer, actions, right, ...)
	if inst:HasTag("ms_teleporter") then
		table.insert(actions, ACTIONS.MS_USE_DOOR)
	else
		old_teleport(inst, doer, actions, right, ...)
	end
end

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MS_USE_DOOR, "ms_door_use_pre"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MS_USE_DOOR, "ms_door_use_pre"))

------------------------------------------------------------------------------------------------------------------------
-- 铝镐对石钟乳：专用「开采」→ 直线飞向 (x, THROW_HIT_HEIGHT, z)

local MS_MINE_STALACTITE = Action({ priority = 10, distance = 15, mount_valid = true })
MS_MINE_STALACTITE.id = "MS_MINE_STALACTITE"
MS_MINE_STALACTITE.str = "Mine"
MS_MINE_STALACTITE.fn = function(act)
	if act.invobject ~= nil
			and act.target ~= nil
			and act.invobject.ThrowAtStalactite ~= nil then
		return act.invobject:ThrowAtStalactite(act.doer, act.target)
	end
	return false
end

AddAction(MS_MINE_STALACTITE)

local MS_THROW_STALACTITE = Action({ priority = 10, distance = 15, mount_valid = true })
MS_THROW_STALACTITE.id = "MS_THROW_STALACTITE"
MS_THROW_STALACTITE.str = "Throw"
MS_THROW_STALACTITE.fn = MS_MINE_STALACTITE.fn 

AddAction(MS_THROW_STALACTITE)

local is_chinese = locale == "zh" or locale == "zht" or locale == "zhr"
STRINGS.ACTIONS.MS_MINE_STALACTITE = is_chinese and "开采" or "Mine"

AddComponentAction("EQUIPPED", "aoetargeting", function(inst, doer, target, actions, right)
	if not right
			and inst:HasTag("ms_aluminum_pickaxe")
			and target ~= nil then
        if target:HasTag("mountain_stalactite") then
          table.insert(actions, ACTIONS.MS_MINE_STALACTITE)
        -- Luigi: For future, as it is unclear what zeroguzok means with "box" on a bush.
        elseif target:HasTag("mountain_throw_target") then
          table.insert(actions, ACTIONS.MS_THROW_STALACTITE)
        end
	end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MS_MINE_STALACTITE, "throw_line"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MS_MINE_STALACTITE, "throw_line"))
