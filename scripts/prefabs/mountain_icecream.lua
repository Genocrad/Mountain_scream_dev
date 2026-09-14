local GoatCommon = require("mountain_goat_common")

local assets =
{
	Asset("ANIM", "anim/mountain_icecream.zip"),
}

local prefabs =
{
	"spoiled_food",
	"buff_mountain_icecream",
}

------------------------------------------------------------------------------------------------------------------------
-- 食用 buff：1 分钟内攻击施加 25% 冰冻
------------------------------------------------------------------------------------------------------------------------

local function OnHitOther(attacker, data)
	local target = data ~= nil and data.target or nil
	GoatCommon.PartialFreeze(target, TUNING.MOUNTAIN_ICECREAM.FREEZE_PERCENT)
end

local function Buff_OnAttached(inst, target)
	inst.entity:SetParent(target.entity)
	inst.Transform:SetPosition(0, 0, 0)
	inst:ListenForEvent("death", function()
		inst.components.debuff:Stop()
	end, target)
	inst:ListenForEvent("onhitother", OnHitOther, target)
end

local function Buff_Say(target, strid)
	if target ~= nil and target:IsValid() and target.components.talker ~= nil then
		target.components.talker:Say(GetString(target, strid))
	end
end

local function Buff_OnDetached(inst, target)
	if target ~= nil and target:IsValid() then
		inst:RemoveEventCallback("onhitother", OnHitOther, target)
		if target.components.health == nil or not target.components.health:IsDead() then
			Buff_Say(target, "MS_MOUNTAIN_ICE_CREAM_END")
		end
	end
	inst:Remove()
end

local function Buff_OnExtended(inst)
	inst.components.timer:StopTimer("buffover")
	inst.components.timer:StartTimer("buffover", TUNING.MOUNTAIN_ICECREAM.BUFF_DURATION)
end

local function Buff_OnTimerDone(inst, data)
	if data.name == "buffover" then
		inst.components.debuff:Stop()
	end
end

local function buff_fn()
	local inst = CreateEntity()

	if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, inst.Remove)
		return inst
	end

	inst.entity:AddTransform()
	inst.entity:Hide()
	inst.persists = false

	inst:AddTag("CLASSIFIED")

	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(Buff_OnAttached)
	inst.components.debuff:SetDetachedFn(Buff_OnDetached)
	inst.components.debuff:SetExtendedFn(Buff_OnExtended)
	inst.components.debuff.keepondespawn = true

	inst:AddComponent("timer")
	inst.components.timer:StartTimer("buffover", TUNING.MOUNTAIN_ICECREAM.BUFF_DURATION)
	inst:ListenForEvent("timerdone", Buff_OnTimerDone)

	return inst
end

------------------------------------------------------------------------------------------------------------------------
-- 雪山冰激凌
------------------------------------------------------------------------------------------------------------------------

local function OnEaten(inst, eater)
	if eater ~= nil and eater.components.debuffable ~= nil and eater:HasTag("player") then
		eater:AddDebuff("buff_mountain_icecream", "buff_mountain_icecream")
		Buff_Say(eater, "MS_MOUNTAIN_ICE_CREAM_START")
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_icecream")
	inst.AnimState:SetBuild("mountain_icecream")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("icebox_valid")

	MakeInventoryFloatable(inst, "small", 0.15, 0.8)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("edible")
	inst.components.edible.foodtype = FOODTYPE.GOODIES
	inst.components.edible.healthvalue = TUNING.MOUNTAIN_ICECREAM.HEALTH
	inst.components.edible.hungervalue = TUNING.MOUNTAIN_ICECREAM.HUNGER
	inst.components.edible.sanityvalue = TUNING.MOUNTAIN_ICECREAM.SANITY
	inst.components.edible.temperaturedelta = TUNING.MOUNTAIN_ICECREAM.TEMP_DELTA
	inst.components.edible.temperatureduration = TUNING.MOUNTAIN_ICECREAM.TEMP_DURATION
	inst.components.edible:SetOnEatenFn(OnEaten)

	inst:AddComponent("perishable")
	inst.components.perishable:SetPerishTime(TUNING.MOUNTAIN_ICECREAM.PERISH_TIME)
	inst.components.perishable:StartPerishing()
	inst.components.perishable.onperishreplacement = "spoiled_food"

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_icecream"

	inst:AddComponent("tradable")

	MakeHauntableLaunchAndPerish(inst)

	return inst
end

return Prefab("mountain_icecream", fn, assets, prefabs),
	Prefab("buff_mountain_icecream", buff_fn)
