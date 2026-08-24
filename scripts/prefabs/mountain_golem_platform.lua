require("prefabutil")

local assets =
{
	Asset("ANIM", "anim/mountain_golem_platform.zip"),
	Asset("ANIM", "anim/ui_construction_4x1.zip"),
}

local prefabs =
{
	"construction_container",
	"mountain_golem_pillar",
}

local function GetCtrl()
	return TheWorld.components.mountain_golem_platformctrl
end

local OnConstructed

local function EnableConstructionSite(inst)
	inst:AddTag("constructionsite")
	if TheWorld.ismastersim then
		if inst.components.constructionsite == nil then
			inst:AddComponent("constructionsite")
		end
		inst.components.constructionsite:SetConstructionPrefab("construction_container")
		inst.components.constructionsite:SetOnConstructedFn(OnConstructed)
	end
end

local function DisableConstructionSite(inst)
	inst:RemoveTag("constructionsite")
	if TheWorld.ismastersim and inst.components.constructionsite ~= nil then
		inst:RemoveComponent("constructionsite")
	end
end

local function ApplyLightVisibility(inst)
	if inst._construction_locked:value() then
		inst.AnimState:Hide("light")
	else
		inst.AnimState:Show("light")
	end
end

local function OnConstructionLockedDirty(inst)
	ApplyLightVisibility(inst)
end

OnConstructed = function(inst, doer)
	if not inst.components.constructionsite:IsComplete() then
		return
	end

	local ctrl = GetCtrl()
	if ctrl ~= nil and ctrl.locked then
		return
	end

	-- 先全局锁定所有地基，再生成魔柱
	if ctrl ~= nil then
		ctrl:LockAll()
	end

	local x, _, z = inst.Transform:GetWorldPosition()
	local pillar = SpawnPrefab("mountain_golem_pillar")
	pillar.Transform:SetPosition(x, 0, z)
	PreventCharacterCollisionsWithPlacedObjects(pillar)
	if pillar.StartSummon ~= nil then
		pillar:StartSummon()
	end
end

local function SetConstructionLocked(inst, locked)
	locked = locked == true
	if inst._locked == locked then
		if locked then
			DisableConstructionSite(inst)
		end
		-- 存档加载/重复同步时仍刷新 light，避免视觉与锁定状态脱节
		inst._construction_locked:set(locked)
		ApplyLightVisibility(inst)
		return
	end

	inst._locked = locked
	inst._construction_locked:set(locked)
	if locked then
		DisableConstructionSite(inst)
	else
		EnableConstructionSite(inst)
	end
	ApplyLightVisibility(inst)
end

local function OnRemoveEntity(inst)
	local ctrl = GetCtrl()
	if ctrl ~= nil then
		ctrl:UnregisterPlatform(inst)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	inst.AnimState:SetBank("mountain_golem_platform")
	inst.AnimState:SetBuild("mountain_golem_platform")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst.MiniMapEntity:SetIcon("mountain_golem_platform.tex")

	inst:SetDeploySmartRadius(1.5)

	inst:AddTag("constructionsite")
	inst._locked = false
	-- 可建造时显示 light；不可建造时隐藏。经 net_bool 同步到客户端。
	inst._construction_locked = net_bool(inst.GUID, "mountain_golem_platform.locked", "constructionlockeddirty")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("constructionlockeddirty", OnConstructionLockedDirty)
		ApplyLightVisibility(inst)
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("constructionsite")
	inst.components.constructionsite:SetConstructionPrefab("construction_container")
	inst.components.constructionsite:SetOnConstructedFn(OnConstructed)

	inst.SetConstructionLocked = SetConstructionLocked
	inst.OnRemoveEntity = OnRemoveEntity

	local function TryRegister()
		local ctrl = GetCtrl()
		if ctrl ~= nil then
			ctrl:RegisterPlatform(inst)
			return true
		end
		return false
	end
	if not TryRegister() then
		inst:DoTaskInTime(0, TryRegister)
	end

	return inst
end

return Prefab("mountain_golem_platform", fn, assets, prefabs)
