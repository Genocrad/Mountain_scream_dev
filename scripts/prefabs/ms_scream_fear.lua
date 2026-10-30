--[[ 尖啸开场恐惧：复刻织影 mindcontroller 的联网方式
     客户端每帧 Push mindcontrollevel → MindControlOver 黑影占屏（先渐入再满屏）
     服务端在满屏后 Push mindcontrolled → 短暂无法操作
]]

local function GetFearTicks()
	return math.max(1, math.floor(TUNING.MOUNTAIN_SCREAMER.SCREAM_FEAR_DURATION / FRAMES + 0.5))
end

local function GetFadeInFrames()
	local fade = TUNING.MOUNTAIN_SCREAMER.SCREAM_FEAR_FADE_IN or 0.75
	local total = TUNING.MOUNTAIN_SCREAMER.SCREAM_FEAR_DURATION or 2
	-- 渐入不超过总时长的 80%，保证后面仍有锁人时间
	fade = math.min(fade, total * 0.8)
	return math.max(1, math.floor(fade / FRAMES + 0.5))
end

local function ResetFade(inst)
	inst._level = 0
	inst._level_step = 1 / GetFadeInFrames()
end

local function OnAttached(inst, target)
	inst.entity:SetParent(target.entity)
	inst.Network:SetClassifiedTarget(target)
	ResetFade(inst)
end

local function OnDetached(inst, target)
	if target ~= nil and target:IsValid() then
		target:PushEvent("mindcontrollevel", 0)
	end
	inst:Remove()
end

local function ExtendDebuff(inst)
	inst.countdown = GetFearTicks()
	ResetFade(inst)
end

local function OnUpdate(inst, ismastersim)
	local parent = inst.entity:GetParent()
	if parent ~= nil then
		if inst._level == nil then
			ResetFade(inst)
		end
		if inst._level < 1 then
			inst._level = math.min(1, inst._level + inst._level_step)
		end
		-- 每帧刷新：MindControlOver 若不持续推送会在 1～2 帧后清掉
		parent:PushEvent("mindcontrollevel", inst._level)
		-- 满屏后再锁操作（渐入阶段仍可动，方便读动画）
		if ismastersim and inst._level >= 1 then
			parent:PushEvent("mindcontrolled")
		end
	end

	if ismastersim then
		if inst.countdown > 1 then
			inst.countdown = inst.countdown - 1
		else
			inst.components.debuff:Stop()
		end
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	inst:AddTag("CLASSIFIED")

	ResetFade(inst)

	-- 与 mindcontroller 相同：双端各自每帧跑，驱动本地 HUD / 服务端锁人
	inst:DoPeriodicTask(0, OnUpdate, nil, TheWorld.ismastersim)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(OnAttached)
	inst.components.debuff:SetDetachedFn(OnDetached)
	inst.components.debuff:SetExtendedFn(ExtendDebuff)

	ExtendDebuff(inst)

	return inst
end

return Prefab("ms_scream_fear", fn)
