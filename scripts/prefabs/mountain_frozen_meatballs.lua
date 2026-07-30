local assets =
{
	Asset("ANIM", "anim/mountain_frozen_meatballs.zip"),
}

local prefabs =
{
	"meatballs",
}

local function OnWork(inst, worker, workleft, workdone)
	local stacksize = inst.components.stackable:StackSize()
	local num = math.clamp(math.ceil(workdone / TUNING.MOUNTAIN_FROZEN_MEATBALLS.WORK), 1, stacksize)

	for _ = 1, num do
		local loot = SpawnPrefab("meatballs")
		if loot ~= nil then
			LaunchAt(loot, inst, worker, 1, 0.5)
		end
	end

	local consumed = inst.components.stackable:Get(num)
	consumed:Remove()
end

local function OnStackSizeChanged(inst, data)
	if data ~= nil and data.stacksize ~= nil and inst.components.workable ~= nil then
		inst.components.workable:SetWorkLeft(data.stacksize * TUNING.MOUNTAIN_FROZEN_MEATBALLS.WORK)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_frozen_meatballs")
	inst.AnimState:SetBuild("mountain_frozen_meatballs")
	inst.AnimState:PlayAnimation("idle")

	inst.pickupsound = "rock"

	inst:AddTag("molebait")
	inst:AddTag("frozen")

	MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_frozen_meatballs"

	inst:AddComponent("stackable")
	inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("tradable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.MOUNTAIN_FROZEN_MEATBALLS.WORK)
	inst.components.workable:SetOnWorkCallback(OnWork)

	inst:ListenForEvent("stacksizechange", OnStackSizeChanged)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_frozen_meatballs", fn, assets, prefabs)
