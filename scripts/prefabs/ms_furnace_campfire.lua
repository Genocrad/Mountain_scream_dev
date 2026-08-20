require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/campfire.zip"),
    Asset("ANIM", "anim/furnace_firesplash_fx.zip"),
}

local prefabs =
{
    "campfirefire",
    "collapse_small",
    "ash",
	"charcoal",
}

local function onhammered(inst, worker)
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("ash").Transform:SetPosition(x, y, z)
    SpawnPrefab("collapse_small").Transform:SetPosition(x, y, z)
    inst:Remove()
end

local function onextinguish(inst)
    if inst.components.fueled ~= nil then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function ontakefuel(inst)
  inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function ontakefuelitemfn(inst, item)
  print(inst.furnace)
  if inst.furnace and item.prefab == "ms_coal" then
    inst.furnace.components.temperature:DoDelta(200, true)
    if inst.furnace.components.furnituredecortaker.decor_item then
      inst.furnace.components.furnituredecortaker.decor_item.components.temperature:DoDelta(100, true)
    end
  end
end

local function updatefuelrate(inst)
	inst.components.fueled.rate = TheWorld.state.israining and inst.components.rainimmunity == nil and 1 + TUNING.CAMPFIRE_RAIN_RATE * TheWorld.state.precipitationrate or 1
end

local function onupdatefueled(inst)
    if inst.components.burnable ~= nil and inst.components.fueled ~= nil then
        updatefuelrate(inst)
        
        inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
    end
end


local HEAT_OUTPUTS = { 2, 5, 5, 10 }
local function onfuelchange(newsection, oldsection, inst)
  if newsection <= 0 then
		if inst.queued_charcoal then
			SpawnPrefab("charcoal").Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.queued_charcoal = nil
		end
    else
      if not inst.components.burnable:IsBurning() then
        updatefuelrate(inst)
        inst.components.burnable:Ignite()
      end
      inst.AnimState:PlayAnimation("cooking_loop_fire")
      inst.components.burnable:SetFXLevel(newsection, inst.components.fueled:GetSectionPercent())
		if newsection == inst.components.fueled.sections then
			inst.queued_charcoal = not inst.disable_charcoal
		end
    end
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("cooking_loop_fire", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function OnBellowActivated(inst)
  if inst.components.fueled then
    inst.components.fueled:DoDelta(-TUNING.MED_FUEL)
    if inst.components.burnable.fxchildren and inst.components.burnable.fxchildren[1] then
      local x, y, z = inst.Transform:GetWorldPosition()
      local fire = SpawnPrefab("furnace_firesplash_fx")
      fire.Transform:SetPosition(x,y,z)
      inst.components.burnable.fxchildren[1]._overfueled = 2
    end
  end
end

local SECTION_STATUS =
{
    [0] = "OUT",
    [1] = "EMBERS",
    [2] = "LOW",
    [3] = "NORMAL",
    [4] = "HIGH",
}
local function getstatus(inst)
    return SECTION_STATUS[inst.components.fueled:GetCurrentSection()]
end

local function OnHaunt(inst)
    if inst.components.fueled ~= nil and
        inst.components.fueled.accepting and
        math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
        inst.components.fueled:DoDelta(TUNING.TINY_FUEL)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function OnInit(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local bellow = SpawnPrefab("ms_furnace_bellow")
    bellow.Transform:SetPosition(x,y,z)
    bellow.campfire = inst
    if inst.components.burnable ~= nil then
        inst.components.burnable:FixFX()
    end
    
end

local function OnSave(inst, data)
    data.queued_charcoal = inst.queued_charcoal or nil
end

local function OnLoad(inst, data)
    if data ~= nil and data.queued_charcoal then
        inst.queued_charcoal = true
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst:SetDeploySmartRadius(1) --recipe min_spacing/2
    MakeObstaclePhysics(inst, 0.7)

    inst.AnimState:SetBank("ms_furnace")
    inst.AnimState:SetBuild("ms_furnace")
    inst.AnimState:PlayAnimation("cooking_loop_fire")
    inst.AnimState:SetFinalOffset(-2)
    inst.AnimState:SetMultColour(0.5, 0.5, 0.5, 1)

    inst:AddTag("campfire")
    inst:AddTag("ms_furnace_campfire")
    inst:AddTag("NPC_workable")

    --cooker (from cooker component) added to pristine state for optimization
    inst:AddTag("cooker")

	-- for storytellingprop component
	inst:AddTag("storytellingprop")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------

    -----------------------

    inst:AddComponent("burnable")
    --inst.components.burnable:SetFXLevel(2)
    inst.components.burnable:AddBurnFX("ms_furnace_campfirefire", Vector3(0, 0, 0), "firefx")
    inst.components.burnable:SetFXOffset(0, 30, 0)
    inst:ListenForEvent("onextinguish", onextinguish)

    -------------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(nil)
    inst.components.workable:SetOnFinishCallback(onhammered)

    -------------------------
    inst:AddComponent("cooker")
    -------------------------
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = 10 * TUNING.CAMPFIRE_FUEL_MAX
    inst.components.fueled.accepting = true

    inst.components.fueled:SetSections(20)

    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled:SetTakeFuelItemFn(ontakefuelitemfn)
    inst.components.fueled:SetUpdateFn(onupdatefueled)
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.CAMPFIRE_FUEL_START)


    --------------------
    inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_SMALL)
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    inst.OnBellowActivated = OnBellowActivated
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0, OnInit)

    return inst
end

-------------------------------------------------------------------------------



-------------------------------------------------------------------------------

return Prefab("ms_furnace_campfire", fn, assets, prefabs),
    MakePlacer("campfire_placer", "campfire", "campfire", "preview")
   
