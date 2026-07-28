local assets = {
    Asset("ANIM", "anim/cave_exit_rope.zip"),
}

local function StartTravelSound(inst, doer)
    inst.SoundEmitter:PlaySound("dontstarve/cave/tentapiller_hole_enter") -- FIXME(JBK): rifts6 sounds
    doer:PushEvent("wormholetravel", WORMHOLETYPE.VAULTLOBBYEXIT) --Event for playing local travel sound
end

local function OnActivate(inst, doer)
    if doer:HasTag("player") then
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
        --Sounds are triggered in player's stategraph
    elseif inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/cave/tentapiller_hole_enter") -- FIXME(JBK): rifts7: sounds
    end
end

local function SetExitTarget(inst, targetinst)
    local oldtarget = inst.components.teleporter:GetTarget()
    if oldtarget then
        inst:RemoveEventCallback("onremove", inst._exittarget_onremove, targetinst)
    end

    inst.components.teleporter:Target(targetinst)
    if not targetinst then
        inst.AnimState:PlayAnimation("up")
        inst.components.teleporter:SetEnabled(false)
        return
    end

    inst.components.teleporter:SetEnabled(true)
    inst:ListenForEvent("onremove", inst._exittarget_onremove, targetinst)
end

local function ScheduleForDelete(inst)
    if inst:IsAsleep() then
        inst:Remove()
        return
    end

    inst.persists = false
    inst.AnimState:PlayAnimation("up")
    inst:ListenForEvent("animover", inst.Remove)
end

local function OnSave(inst, data)
	if inst.components.teleporter.targetTeleporter then
		data.target_x, data.target_y, data.target_z =  inst.components.teleporter.targetTeleporter.Transform:GetWorldPosition()
	end
end

local function OnLoad(inst, data)
	if data ~= nil and data.target_x then
    local exit = SpawnPrefab("ms_climbing_down")
    exit.Transform:SetPosition(data.target_x, data.target_y, data.target_z)
    exit:SetExitTarget(inst)
    inst:SetExitTarget(exit)
	end
end


local function fn()
    local inst = CreateEntity()

   
    
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("exitrope")
    inst.AnimState:SetBuild("cave_exit_rope")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("climbable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    local teleporter = inst:AddComponent("teleporter")
    teleporter.onActivate = OnActivate
    teleporter.offset = 3
    teleporter:SetSelfManaged(true)
    --Does not save.
    --teleporter.saveenabled = true
    teleporter:SetEnabled(false)
    inst.StartTravelSound = StartTravelSound
    inst:ListenForEvent("starttravelsound", inst.StartTravelSound) -- triggered by player stategraph

    inst.SetExitTarget = SetExitTarget
    inst._exittarget_onremove = function()
        inst:SetExitTarget(nil)
    end

    inst.ScheduleForDelete = ScheduleForDelete
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    
    return inst
end

return Prefab("ms_climbing", fn, assets)
