local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst:AddTag("nosteal")
  
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false

	inst:AddComponent("inventoryitem")
  inst.components.inventoryitem:SetOnDroppedFn(inst.Remove)
	return inst
end

return Prefab("mountain_kiki_ammo1", fn),
	Prefab("mountain_kiki_ammo2", fn),
	Prefab("mountain_kiki_ammo3", fn)
