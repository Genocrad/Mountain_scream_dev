local assets = {
    Asset("ANIM", "anim/ms_climbing.zip"),
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


local function OnSave(inst, data)
	if inst.components.teleporter.targetTeleporter then
		data.target_x, data.target_y, data.target_z = inst.components.teleporter.targetTeleporter.Transform:GetWorldPosition()
		local exit = inst.components.teleporter.targetTeleporter
		if exit.components.teleporter ~= nil then
			data.exit_teleport_offset = exit.components.teleporter.teleport_offset
		end
		-- Legacy: older worlds stored the wall normal on the climbing prefab.
		if data.exit_teleport_offset == nil then
			data.teleport_offset = inst.components.teleporter.teleport_offset
		end
	end
end

local function OnLoad(inst, data)
	local exit
	if data ~= nil and data.target_x then
		exit = SpawnPrefab("ms_climbing_down")
		exit.Transform:SetPosition(data.target_x, data.target_y, data.target_z)
		exit:SetExitTarget(inst)
		inst:SetExitTarget(exit)
	end
	-- No fixed offset when climbing up — paved upper landing + vanilla offset is better.
	inst.components.teleporter.teleport_offset = nil
	if exit ~= nil and exit.components.teleporter ~= nil and data ~= nil then
		exit.components.teleporter.teleport_offset = data.exit_teleport_offset or data.teleport_offset
	end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()
      
    MakeObstaclePhysics(inst, 3)
    inst.Physics:SetActive(false)
    
    inst.AnimState:SetBank("ms_climbing")
    inst.AnimState:SetBuild("ms_climbing")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/clickable_vertical_shader.ksh"))	
    inst.AnimState:SetDepthTestEnabled(true)
    inst.AnimState:SetDepthWriteEnabled(true)
    inst.Transform:SetScale(1.002,2,1.002)
    inst.AnimState:SetManualBB(0,0,600,1000)
    inst.AnimState:SetSymbolAddColour("climbing", 0, 0, 1, 1)
    
    inst:AddTag("climbable")
    
    inst.MiniMapEntity:SetIcon("ms_climbing.tex")
      
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
    
    inst:AddComponent("savedrotation") 
    
    inst.SetExitTarget = SetExitTarget
    
    inst._exittarget_onremove = function()
        inst:SetExitTarget(nil)
    end
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    
    return inst
end

return Prefab("ms_climbing", fn, assets)
