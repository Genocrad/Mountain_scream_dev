local assets =
{
	Asset("ANIM", "anim/ms_blood_fx.zip"),
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("DECOR")

	inst.AnimState:SetBank("ms_blood_fx")
	inst.AnimState:SetBuild("ms_blood_fx")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetDeltaTimeMultiplier(TUNING.MOUNTAIN_SCREAMER.SCREAM_BLOOD_FX_SPEED or 0.5)
	inst.AnimState:SetFinalOffset(1)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	return inst
end

return Prefab("ms_blood_fx", fn, assets)
