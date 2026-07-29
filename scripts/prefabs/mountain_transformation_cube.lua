local assets =
{
	Asset("ANIM", "anim/mountain_transformation_cube.zip"),
	Asset("ATLAS", "images/inventoryimages/mountain_items.xml"),
	Asset("IMAGE", "images/inventoryimages/mountain_items.tex"),
}

local BUILDER_TAG = "mountain_science"

------------------------------------------------------------------------------------------------------------------------

local function RefreshOwnerTag(owner)
	if owner == nil or not owner:IsValid() or owner.components.inventory == nil then
		return
	end

	local has = owner.components.inventory:Has("mountain_transformation_cube", 1, true)
	if has then
		owner:AddTag(BUILDER_TAG)
	else
		owner:RemoveTag(BUILDER_TAG)
	end
	owner:PushEvent("refreshcrafting")
end

local function OnPutInInventory(inst, owner)
	owner = owner ~= nil and (owner.components.inventoryitem ~= nil and owner.components.inventoryitem:GetGrandOwner() or owner) or nil
	if owner ~= nil and owner:HasTag("player") then
		RefreshOwnerTag(owner)
	end
end

local function OnDropped(inst)
	local owner = inst._last_owner
	inst._last_owner = nil
	if owner ~= nil and owner:IsValid() and owner:HasTag("player") then
		RefreshOwnerTag(owner)
	end
end

local function OnRemove(inst)
	OnDropped(inst)
end

local function Topocket(inst, owner)
	inst._last_owner = owner ~= nil and (owner.components.inventoryitem ~= nil and owner.components.inventoryitem:GetGrandOwner() or owner) or nil
	OnPutInInventory(inst, owner)
end

------------------------------------------------------------------------------------------------------------------------

local function OnFinished(inst)
	local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem:GetGrandOwner() or nil
	inst:Remove()
	if owner ~= nil and owner:IsValid() and owner:HasTag("player") then
		RefreshOwnerTag(owner)
	end
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_transformation_cube")
	inst.AnimState:SetBuild("mountain_transformation_cube")
	inst.AnimState:PlayAnimation("idle", true)

	inst:AddTag("mountain_transformation_cube")
	inst:AddTag("nonpotatable")

	MakeInventoryFloatable(inst, "med", 0.05, 0.68)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/mountain_items.xml"
	inst.components.inventoryitem.imagename = "mountain_transformation_cube"
	inst.components.inventoryitem:SetOnPutInInventoryFn(Topocket)
	inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

	local uses = TUNING.MOUNTAIN_TRANSFORMATION_CUBE.USES
	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(uses)
	inst.components.finiteuses:SetUses(uses)
	inst.components.finiteuses:SetOnFinished(OnFinished)

	inst:ListenForEvent("percentusedchange", function()
		local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem:GetGrandOwner() or nil
		if owner ~= nil and owner:IsValid() then
			owner:PushEvent("refreshcrafting")
		end
	end)

	MakeHauntableLaunch(inst)

	inst:ListenForEvent("onremove", OnRemove)

	return inst
end

return Prefab("mountain_transformation_cube", fn, assets)
