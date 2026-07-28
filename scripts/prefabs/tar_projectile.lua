
local waterstreak_assets =
{
    Asset("ANIM", "anim/waterstreak.zip"),
}


local waterstreak_prefabs =
{
    "waterstreak_burst",
}


local puddle_assets =
{
    Asset("ANIM", "anim/ice_puddle.zip"),
}

local function puddle_fn()
    local inst = CreateEntity()
  
    --Use FX, not DECOR, otherwise won't inspect properly when parented
    inst:AddTag("FX")
    
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    
    inst.Transform:SetScale(1.0 + math.random()*0.3, 1.0 + math.random()*0.3, 1.0 + math.random()*0.3)
    
    inst.AnimState:SetBuild("tar_pit")
    inst.AnimState:SetBank("tar_pit")
        
    inst.AnimState:PlayAnimation("oil_deco")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetMultColour(1,1,1,1)
    return inst
end



local function OnHitWaterstreak(inst, attacker, target)
    local hpx, hpy, hpz = inst.Transform:GetWorldPosition()

    SpawnPrefab("tar_puddle").Transform:SetPosition(hpx, hpy, hpz)

   

   
    inst:Remove()
end


local function waterstreak_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

   
        inst.entity:AddPhysics()
        inst.Physics:SetMass(10)
        inst.Physics:SetFriction(0)
        inst.Physics:SetDamping(0)
        inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
		inst.Physics:SetCollisionMask(COLLISION.GROUND)
        inst.Physics:SetCapsule(0.2, 0.2)
        inst.Physics:SetDontRemoveOnSleep(true) -- so the object can land and put out the fire, also an optimization due to how this moves through the world
   
    inst.Transform:SetSixFaced()
    inst.AnimState:SetMultColour(0,0,0, 1)
    inst:AddTag("NOCLICK")
    
    inst.persists = false
    --projectile (from complexprojectile component) added to pristine state for optimization
    inst:AddTag("projectile")
	inst:AddTag("complexprojectile")

    inst.AnimState:SetBank("waterstreak")
    inst.AnimState:SetBuild("waterstreak")

    
    inst.AnimState:PlayAnimation("pre", false)
    inst.AnimState:PushAnimation("loop", true)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")



    inst:AddComponent("complexprojectile")


    inst.components.complexprojectile:SetOnHit(OnHitWaterstreak)
    return inst
end




return Prefab("tar_projectile", waterstreak_fn, waterstreak_assets, waterstreak_prefabs),
        Prefab("tar_puddle", puddle_fn, puddle_assets)
