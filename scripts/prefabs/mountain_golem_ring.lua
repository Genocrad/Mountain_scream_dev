local assets =
{
	Asset("ANIM", "anim/mountain_golem_ring.zip"),
}

local function ApplyRingVisuals(inst)
	local scale = TUNING.MOUNTAIN_GOLEM.RING_SCALE
	inst.Transform:SetScale(scale, scale, scale)
	inst.AnimState:SetDeltaTimeMultiplier(TUNING.MOUNTAIN_GOLEM.RING_ANIM_SPEED)
end

local function ApplyProtectionLevel(inst)
	local level = inst.level:value()
	for i = 1, TUNING.MOUNTAIN_GOLEM.RING_MAX_LEVEL do
		if i <= level then
			inst.AnimState:Show("pro_"..i)
		else
			inst.AnimState:Hide("pro_"..i)
		end
	end
end

local function OnLevelDirty(inst)
	if not TheWorld.ismastersim then
		ApplyProtectionLevel(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("mountain_golem_ring")
	inst.AnimState:SetBuild("mountain_golem_ring")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	ApplyRingVisuals(inst)

	for i = 1, TUNING.MOUNTAIN_GOLEM.RING_MAX_LEVEL do
		inst.AnimState:Hide("pro_"..i)
	end

	inst.level = net_smallbyte(inst.GUID, "mountain_golem_ring.level", "leveldirty")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("leveldirty", OnLevelDirty)
		ApplyProtectionLevel(inst)
		return inst
	end

	inst.SetProtectionLevel = function(inst, level)
		level = math.clamp(level or 0, 0, TUNING.MOUNTAIN_GOLEM.RING_MAX_LEVEL)
		if inst.level:value() ~= level then
			inst.level:set(level)
		end
		ApplyProtectionLevel(inst)
	end

	inst.persists = false

	return inst
end

return Prefab("mountain_golem_ring", fn, assets)
