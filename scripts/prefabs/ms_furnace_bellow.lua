local assets =
{
	Asset("ANIM", "anim/ms_bellow.zip"),
	Asset("MINIMAP_IMAGE", "vault_switch"),
}

local function ResetActivatable(inst)
	inst.components.activatable.inactive = true
end

local function OnActivate(inst, doer)
	inst.AnimState:PlayAnimation("blow")
	inst.AnimState:PushAnimation("idle", false)
	inst.SoundEmitter:PlaySound("sound_mod_tutorial/ms_fx/bellow")
  -- No check, if bellow does not have a linked campfire, we are in some SSS tier shit anyway.
  inst.campfire:OnBellowActivated()
end

local function GetActivateVerb(inst, doer)
	return "PULL"
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()
  inst.persists = false
  
	MakeSmallObstaclePhysics(inst, 0.7)

	inst.MiniMapEntity:SetIcon("vault_switch.png")

	inst.AnimState:SetBank("ms_bellow")
	inst.AnimState:SetBuild("ms_bellow")
	inst.AnimState:PlayAnimation("idle")
  inst.AnimState:SetRayTestOnBB(true)
  inst.AnimState:SetFinalOffset(-3)

	inst.GetActivateVerb = GetActivateVerb

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
 
	inst:AddComponent("activatable")
  
	inst.components.activatable.standingaction = true
	inst.components.activatable.OnActivate = OnActivate

  inst.ResetActivatable = ResetActivatable
  inst:ListenForEvent("onactivated", OnActivate)
  inst:ListenForEvent("animover", inst.ResetActivatable)
	return inst
end

return Prefab("ms_furnace_bellow", fn, assets, prefabs)
