local prefabs =
{
	"mountain_goat",
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	--[[Non-networked entity]]

	inst:AddTag("herd")
	--V2C: Don't use CLASSIFIED because herds use FindEntities on "herd" tag
	inst:AddTag("NOBLOCK")
	inst:AddTag("NOCLICK")

	inst:AddComponent("herd")
	inst.components.herd:SetMemberTag("mountain_goat")
	inst.components.herd:SetMaxSize(TUNING.MOUNTAIN_GOATHERD.MAX_SIZE)
	inst.components.herd:SetGatherRange(TUNING.MOUNTAIN_GOATHERD.GATHER_RANGE)
	inst.components.herd:SetUpdateRange(20)
	inst.components.herd:SetOnEmptyFn(inst.Remove)
	inst.components.herd.nomerging = true

	return inst
end

return Prefab("mountain_goatherd", fn, nil, prefabs)
