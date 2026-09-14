local fx_assets =
{
	Asset("ANIM", "anim/mountain_tornado.zip"),
}

------------------------------------------------------------------------------------------------------------------------
-- 龙卷风外观 FX（挂在玩家身上）
------------------------------------------------------------------------------------------------------------------------

local function fx_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("mountain_tornado")
	inst.AnimState:SetBuild("mountain_tornado")
	inst.AnimState:PlayAnimation("tornado_pre")
	inst.AnimState:PushAnimation("tornado_loop", true)
	inst.AnimState:SetFinalOffset(2)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("NOBLOCK")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tornado", "spinLoop")

	inst:ListenForEvent("onremove", function()
		inst.SoundEmitter:KillSound("spinLoop")
	end)

	return inst
end

------------------------------------------------------------------------------------------------------------------------
-- 食用 buff：60s 内可右键自身变身龙卷风
------------------------------------------------------------------------------------------------------------------------

local function Buff_OnAttached(inst, target)
	inst.entity:SetParent(target.entity)
	inst.Transform:SetPosition(0, 0, 0)
	target:AddTag("ms_tornado_buff")
	inst:ListenForEvent("death", function()
		inst.components.debuff:Stop()
	end, target)
end

local function Buff_Say(target, strid)
	if target ~= nil and target:IsValid() and target.components.talker ~= nil then
		target.components.talker:Say(GetString(target, strid))
	end
end

local function Buff_OnDetached(inst, target)
	if target ~= nil and target:IsValid() then
		target:RemoveTag("ms_tornado_buff")
		if target.sg ~= nil and target.sg:HasStateTag("ms_tornado") then
			target.sg.statemem.exiting_to_pst = true
			target.sg:GoToState("ms_tornado_pst")
		end
		if target.components.health == nil or not target.components.health:IsDead() then
			Buff_Say(target, "MS_TORNADO_MILKSHAKE_END")
		end
	end
	inst:Remove()
end

local function Buff_OnExtended(inst)
	inst.components.timer:StopTimer("buffover")
	inst.components.timer:StartTimer("buffover", TUNING.MOUNTAIN_TORNADO_SORBET.BUFF_DURATION)
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
	inst.components.timer:StartTimer("buffover", TUNING.MOUNTAIN_TORNADO_SORBET.BUFF_DURATION)
	inst:ListenForEvent("timerdone", Buff_OnTimerDone)

	return inst
end

-- 料理本体由 scripts/prefabs/mountain_preparedfoods.lua 创建
return Prefab("buff_mountain_tornado_sorbet", buff_fn),
	Prefab("mountain_tornado_player_fx", fx_fn, fx_assets)
