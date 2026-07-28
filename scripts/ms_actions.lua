
local UpvalueHacker = require("tools/upvaluehacker")

local AddAction = AddAction
local AddComponentAction = AddComponentAction
local AddStategraphActionHandler = AddStategraphActionHandler

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

AddAction("MS_USE_DOOR", "USE DOOR", function(act)
    act.doer.sg:GoToState("ms_door_use", { teleporter = act.target })
    return true
   
  end)


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