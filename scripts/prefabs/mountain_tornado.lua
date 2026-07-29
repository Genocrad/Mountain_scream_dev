local assets =
{
	Asset("ANIM", "anim/mountain_tornado.zip"),
}

local brain = require("brains/tornadobrain")

local function OnLifetime(inst)
	inst.task = nil
	inst.sg:GoToState("despawn")
end

local function SetDuration(inst, duration)
	if inst.task ~= nil then
		inst.task:Cancel()
	end
	inst.task = inst:DoTaskInTime(duration, OnLifetime)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetFinalOffset(2)
	inst.AnimState:SetBank("mountain_tornado")
	inst.AnimState:SetBuild("mountain_tornado")
	inst.AnimState:PlayAnimation("tornado_pre")
	inst.AnimState:PushAnimation("tornado_loop")

	inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tornado", "spinLoop")

	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("knownlocations")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.TORNADO_WALK_SPEED * .33
	inst.components.locomotor.runspeed = TUNING.TORNADO_WALK_SPEED

	inst:SetStateGraph("SGmountain_tornado")
	inst:SetBrain(brain)

	inst.WINDSTAFF_CASTER = nil
	inst.persists = false

	inst.SetDuration = SetDuration
	inst:SetDuration(TUNING.TORNADO_LIFETIME)

	return inst
end

return Prefab("mountain_tornado", fn, assets)
