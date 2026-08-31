-- Wortox 手持铝制工具时：右键不再灵魂跳跃，走 AOE 投掷（与其他角色一致）

local function IsHoldingAluminumTool(inst)
	local inventory = inst.replica.inventory
	if inventory == nil then
		return false
	end
	local equip = inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	return equip ~= nil and equip:HasTag("ms_aluminum_tool")
end

local function WrapPointSpecialActions(inst)
	local picker = inst.components.playeractionpicker
	if picker == nil or picker.pointspecialactionsfn == nil or picker._ms_aluminum_tool_wrap then
		return
	end

	picker._ms_aluminum_tool_wrap = true
	local oldfn = picker.pointspecialactionsfn
	picker.pointspecialactionsfn = function(doer, pos, useitem, right, ...)
		if right and useitem == nil and IsHoldingAluminumTool(doer) then
			return {}
		end
		return oldfn(doer, pos, useitem, right, ...)
	end
end

AddPrefabPostInit("wortox", function(inst)
	-- 原版在 setowner 时写入 pointspecialactionsfn；之后再包一层
	inst:ListenForEvent("setowner", WrapPointSpecialActions)
	-- 兜底：若 setowner 已先触发，下一帧再尝试包装
	inst:DoTaskInTime(0, WrapPointSpecialActions)
end)
