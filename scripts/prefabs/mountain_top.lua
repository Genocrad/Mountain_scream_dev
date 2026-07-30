local assets =
{
	Asset("ANIM", "anim/mountain_top.zip"),
	Asset("ANIM", "anim/ui_construction_4x1.zip"),
}

local prefabs =
{
	"construction_container",
}

local function NoSanityFalloffFn()
	return 1
end

local function EnableSanityAura(inst)
	if inst.components.sanityaura == nil then
		inst:AddComponent("sanityaura")
	end
	inst.components.sanityaura.aura = TUNING.MOUNTAIN_TOP.AURA_PER_SECOND
	inst.components.sanityaura.max_distsq = TUNING.MOUNTAIN_TOP.AURA_RANGE * TUNING.MOUNTAIN_TOP.AURA_RANGE
	inst.components.sanityaura.fallofffn = NoSanityFalloffFn
end

local function OnSetFlagAnimOver(inst)
	if inst.AnimState:IsCurrentAnimation("set_flag") then
		inst.AnimState:PlayAnimation("idle_flag", true)
	end
end

local function ApplyFlaggedState(inst, planter_name, instant)
	inst._is_flagged = true
	inst._planter_name:set(planter_name or "")

	if inst.components.constructionsite ~= nil then
		inst:RemoveComponent("constructionsite")
	end
	inst:RemoveTag("constructionsite")

	if inst.components.named ~= nil and planter_name ~= nil and planter_name ~= "" then
		inst.components.named:SetName(planter_name)
	end

	EnableSanityAura(inst)

	inst:RemoveEventCallback("animover", OnSetFlagAnimOver)
	if instant then
		inst.AnimState:PlayAnimation("idle_flag", true)
	else
		inst.AnimState:PlayAnimation("set_flag")
		inst:ListenForEvent("animover", OnSetFlagAnimOver)
	end
end

local function GetSpecialDescription(inst, viewer)
	local name = inst._planter_name:value()
	if name ~= nil and name ~= "" then
		return subfmt(STRINGS.MOUNTAIN_TOP.FLAGGED_DESC, { name = name })
	end
	return STRINGS.MOUNTAIN_TOP.GENERIC_DESC
end

local function OnConstructed(inst, doer)
	if inst.components.constructionsite == nil or not inst.components.constructionsite:IsComplete() then
		return
	end

	local planter_name = (doer ~= nil and doer:GetDisplayName()) or "???"
	ApplyFlaggedState(inst, planter_name, false)

	if doer ~= nil and doer.components.sanity ~= nil then
		doer.components.sanity:DoDelta(TUNING.MOUNTAIN_TOP.FLAG_SANITY)
	end
end

local function OnSave(inst, data)
	data.flagged = inst._is_flagged or nil
	local name = inst._planter_name:value()
	if name ~= nil and name ~= "" then
		data.planter_name = name
	end
end

local function OnLoad(inst, data)
	if data ~= nil and data.flagged then
		ApplyFlaggedState(inst, data.planter_name, true)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1.5)

	inst.AnimState:SetBank("mountain_top")
	inst.AnimState:SetBuild("mountain_top")
	inst.AnimState:PlayAnimation("no_flag")

	inst:AddTag("structure")
	inst:AddTag("constructionsite")

	inst._planter_name = net_string(inst.GUID, "mountain_top._planter_name", "planternamedirty")

	inst:SetDeploySmartRadius(2)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst._is_flagged = false

	inst:AddComponent("inspectable")
	inst.components.inspectable.getspecialdescription = GetSpecialDescription

	inst:AddComponent("named")
	inst.components.named.nameformat = STRINGS.MOUNTAIN_TOP.NAMED_FMT

	inst:AddComponent("constructionsite")
	inst.components.constructionsite:SetConstructionPrefab("construction_container")
	inst.components.constructionsite:SetOnConstructedFn(OnConstructed)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

return Prefab("mountain_top", fn, assets, prefabs)
