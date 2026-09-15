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
-- 竞技场传送：带 ms_snow_teleport 的门走自定义进出状态（雪特效），懒人塔仍走官方 entertownportal

local old_TELEPORT_fn = ACTIONS.TELEPORT.fn
ACTIONS.TELEPORT.fn = function(act)
	if act.doer ~= nil and act.doer.sg ~= nil then
		local teleporter
		if act.invobject ~= nil then
			if act.doer.sg.currentstate.name == "dolongaction" then
				teleporter = act.invobject
			end
		elseif act.target ~= nil
			and act.doer.sg.currentstate.name == "give" then
			teleporter = act.target
		end
		if teleporter ~= nil
			and teleporter:HasTag("teleporter")
			and teleporter:HasTag("ms_snow_teleport") then
			act.doer.sg:GoToState("ms_entertownportal", { teleporter = teleporter })
			return true
		end
	end
	return old_TELEPORT_fn(act)
end

------------------------------------------------------------------------------------------------------------------------
-- 铝镐对石钟乳/墙面矿石：专用「开采」→ 直线飞向目标命中高度

local function IsInvalidTile(tile)
  return tile == WORLD_TILES.VOID_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL or
  tile == WORLD_TILES.MS_PERMAFROST_TECHNICAL or 
  (not tile == 1 and not TileGroupManager:IsLandTile(tile))
end

local MS_MINE_STALACTITE = Action({ priority = 10, distance = 10, mount_valid = true })
MS_MINE_STALACTITE.id = "MS_MINE_STALACTITE"
MS_MINE_STALACTITE.str = "Mine"
MS_MINE_STALACTITE.fn = function(act)
	if act.invobject ~= nil
			and act.target ~= nil
			and act.invobject.ThrowAtStalactite ~= nil 
      and act.doer ~= nil then
        -- check whether we have line of sight to this object
        local x,y,z = act.target.Transform:GetWorldPosition()
        local x1,y1,z1 = act.doer.Transform:GetWorldPosition()
        
        local throw_angle = (-act.target.Transform:GetRotation()-math.deg(math.atan2(z1-z, x1-x)))
        throw_angle = throw_angle > -270 and throw_angle or 360 - throw_angle
        if IsInvalidTile(TheWorld.Map:GetTileAtPoint((x+x1+x1+x1)/4, 0, (z+z1+z1+z1)/4)) and not (math.abs(throw_angle) < 90) then
          return false
        else
          return act.invobject:ThrowAtStalactite(act.doer, act.target)
        end
	end
	return false
end

AddAction(MS_MINE_STALACTITE)

-- 铝斧左键投掷：墙面灌木 mountain_throw_target；结果期苹果树 ms_apple_harvestable
local MS_THROW = Action({ priority = 10, distance = 10, mount_valid = true })
MS_THROW.id = "MS_THROW"
MS_THROW.str = "Throw"
MS_THROW.fn = function(act)
	if act.invobject ~= nil
			and act.target ~= nil
			and act.invobject.ThrowAtBush ~= nil 
      and act.doer ~= nil then
      -- check whether we have line of sight to this object
        local x,y,z = act.target.Transform:GetWorldPosition()
        local x1,y1,z1 = act.doer.Transform:GetWorldPosition()
        
        local throw_angle = (-act.target.Transform:GetRotation()-math.deg(math.atan2(z1-z, x1-x)))
        throw_angle = throw_angle > -270 and throw_angle or 360 - throw_angle
        if IsInvalidTile(TheWorld.Map:GetTileAtPoint((x+x1+x1+x1)/4, 0, (z+z1+z1+z1)/4)) and not (math.abs(throw_angle) < 90) then
          return false
        else
          return act.invobject:ThrowAtBush(act.doer, act.target)
        end
	end
	return false
end

AddAction(MS_THROW)

------------------------------------------------------------------------------------------------------------------------
-- mountain_kiki：拍打成熟苹果树掉果（不砍倒）

local MS_KNOCK_APPLE = Action({ priority = 1, distance = 1.75, mount_valid = true })
MS_KNOCK_APPLE.id = "MS_KNOCK_APPLE"
MS_KNOCK_APPLE.str = "Knock"
MS_KNOCK_APPLE.fn = function(act)
	if act.target ~= nil and act.target:IsValid() and act.target.HarvestApples ~= nil then
		return act.target:HarvestApples(act.doer) == true
	end
	return false
end

AddAction(MS_KNOCK_APPLE)

local is_chinese = locale == "zh" or locale == "zht" or locale == "zhr"
STRINGS.ACTIONS.MS_MINE_STALACTITE = is_chinese and "开采" or "Mine"
STRINGS.ACTIONS.MS_THROW = is_chinese and "投掷" or "Throw"
STRINGS.ACTIONS.MS_KNOCK_APPLE = is_chinese and "拍打" or "Knock"

AddComponentAction("EQUIPPED", "aoetargeting", function(inst, doer, target, actions, right)
	if right or target == nil then
		return
	end

	-- 铝镐：只对石钟乳「开采」
	if inst:HasTag("ms_aluminum_pickaxe") and target:HasTag("mountain_stalactite") then
		table.insert(actions, ACTIONS.MS_MINE_STALACTITE)
		return
	end

	-- 铝斧：结果期苹果树 / 墙面灌木
	if inst:HasTag("ms_aluminum_axe") then
		if target:HasTag("ms_apple_harvestable")
				and not target:HasTag("stump")
				and not target:HasTag("burnt") then
			table.insert(actions, ACTIONS.MS_THROW)
		elseif target:HasTag("mountain_throw_target")
				and not target:HasTag("ms_apple_tree") then
			table.insert(actions, ACTIONS.MS_THROW)
		end
	end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MS_MINE_STALACTITE, "throw_line"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MS_MINE_STALACTITE, "throw_line"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MS_THROW, "throw_line"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.MS_THROW, "throw_line"))

------------------------------------------------------------------------------------------------------------------------
-- 铁砧上的锤子：锻造锭，不是拆除铁砧。熔炉等建筑仍显示原版 Destroy。

if STRINGS.ACTIONS.MS_FORGE == nil then
	STRINGS.ACTIONS.MS_FORGE = is_chinese and "锻造" or (locale == "ru" and "Ковать" or "Forge")
end
if STRINGS.ACTIONS.MS_SMELT == nil then
	STRINGS.ACTIONS.MS_SMELT = is_chinese and "炼制" or (locale == "ru" and "Плавить" or "Smelt")
end

local old_hammer_stroverridefn = ACTIONS.HAMMER.stroverridefn
ACTIONS.HAMMER.stroverridefn = function(act)
	if act.target ~= nil and act.target:HasTag("ms_anvil") then
		return STRINGS.ACTIONS.MS_FORGE
	end
	if old_hammer_stroverridefn ~= nil then
		return old_hammer_stroverridefn(act)
	end
end

-- 熔炉仍走 COOK 逻辑，但文案是炼制，不改烹饪锅
local old_cook_stroverridefn = ACTIONS.COOK.stroverridefn
ACTIONS.COOK.stroverridefn = function(act)
	if act.target ~= nil and act.target:HasTag("ms_furnace") then
		return STRINGS.ACTIONS.MS_SMELT
	end
	if old_cook_stroverridefn ~= nil then
		return old_cook_stroverridefn(act)
	end
end
