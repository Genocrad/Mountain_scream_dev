------------------------------------------------------------------------------------------------------------------------
-- ms_furnace container widget

local containers = require("containers")
local cooking = require("cooking")
local params = containers.params

params.ms_furnace =
{
	widget =
	{
		slotpos =
		{
			Vector3(0, 64 + 32 + 8 + 4, 0),
			Vector3(0, 32 + 4, 0),
			Vector3(0, -(32 + 4), 0),
			Vector3(0, -(64 + 32 + 8 + 4), 0),
		},
		animbank = "ui_cookpot_1x4",
		animbuild = "ui_cookpot_1x4",
		pos = Vector3(200, 0, 0),
		side_align_tip = 100,
		buttoninfo =
		{
			text = STRINGS.ACTIONS.MS_SMELT,
			position = Vector3(0, -165, 0),
		},
	},
	acceptsstacks = false,
	type = "cooker",
}

function params.ms_furnace.itemtestfn(container, item, slot)
	return cooking.IsCookingIngredient(item.prefab) and not container.inst:HasTag("hasfurnituredecoritem") and item:HasTag("ms_ore")
end

function params.ms_furnace.widget.buttoninfo.fn(inst, doer)
	if inst.components.container ~= nil then
		BufferedAction(doer, inst, ACTIONS.COOK):Do()
	elseif inst.replica.container ~= nil and not inst.replica.container:IsBusy() then
		SendRPCToServer(RPC.DoWidgetButtonAction, ACTIONS.COOK.code, inst, ACTIONS.COOK.mod_name)
	end
end

function params.ms_furnace.widget.buttoninfo.validfn(inst)
	return inst.replica.container ~= nil and inst.replica.container:IsFull()
end

------------------------------------------------------------------------------------------------------------------------
-- Construction plans（可分多次投入）

-- 山岭魔像地基：累计投入 40 石头 + 10 切割石块后建成魔柱
CONSTRUCTION_PLANS["mountain_golem_platform"] = { Ingredient("rocks", 40), Ingredient("cutstone", 10) }
-- 山顶：投入 4 木棍 + 4 草插旗
CONSTRUCTION_PLANS["mountain_top"] = { Ingredient("twigs", 4), Ingredient("cutgrass", 4) }
