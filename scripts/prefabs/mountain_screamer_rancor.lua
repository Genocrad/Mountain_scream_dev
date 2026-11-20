require "prefabutil"

local guard_assets =
{
    Asset("ANIM", "anim/mountain_screamer_rancor.zip"),
}
local guard_prefabs =
{
    "gestalt_guard_head",
}

local function OnCollide(inst, other)
  if other then
    local x, y, z = inst.Transform:GetWorldPosition()
    if not other:HasTag("epic") and not inst.damage_done then
      if other.components.health then
        inst.components.combat:DoAttack(other)
        inst.damage_done = true
      end
      local fx = SpawnPrefab("willow_shadow_fire_explode")
      fx.Transform:SetPosition(x,2,z)
      inst.Physics:Stop()
      inst:Remove()
    end
  end
end


local function OnUpdate(inst, dt)
  if inst.target and inst.target:IsValid() then
    local lx, ly, lz = inst.target.Transform:GetWorldPosition()
    local px, py, pz = inst.Transform:GetWorldPosition()
    
    -- Try to rotate toward target
    
    local teta = math.rad(inst.Transform:GetRotation())
    inst:FacePoint(inst.target.Transform:GetWorldPosition())    
    local teta2 = math.rad(inst.Transform:GetRotation())

    -- Trigonometry, lol
    local dist_to_inst =  math.sqrt(inst:GetDistanceSqToInst(inst.target))
    local hypotenuse = math.sqrt(
      (math.cos(teta) * 2 + px-lx)*(math.cos(teta) * 2 + px-lx) +
      (-math.sin(teta) * 2 + pz-lz)*(-math.sin(teta) * 2 + pz-lz)
    )
    
    local delta_teta = math.deg(math.acos(math.min((4 + dist_to_inst*dist_to_inst - hypotenuse*hypotenuse)/(4*dist_to_inst), 1)))
    teta = math.deg(teta)
    teta2 = math.deg(teta2)
    
    if math.abs(teta + delta_teta - teta2) < 4 then
      inst.Transform:SetRotation(teta + math.sqrt(math.sqrt(delta_teta)))
      inst.last_angle = math.sqrt(math.sqrt(delta_teta))
    elseif math.abs(teta - delta_teta - teta2) < 4 then
      inst.Transform:SetRotation(teta - math.sqrt(math.sqrt(delta_teta)))
      inst.last_angle = -math.sqrt(math.sqrt(delta_teta))
    else
      inst.Transform:SetRotation(teta +  inst.last_angle)
    end
  
    -- Change speed. If the angle of rotation is small go faster, 
    -- go slower if the angle is huge.
    
    if delta_teta < 40 then 
      inst.inertia = inst.inertia + 0.02 + inst.inertia/200
    elseif delta_teta < 70 then
      inst.inertia = inst.inertia
    else
      inst.inertia = math.max(inst.inertia - 0.02 - inst.inertia/400, 1)
    end
    
    inst.Physics:SetMotorVel(inst.inertia,0,0)
  end
end

local function KeepTargetFn(inst)--, target)
	return false
end

local function commonfn()
  
  local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddAnimState()
  inst.entity:AddNetwork()

  -- Custom physics settings
  local phys = inst.entity:AddPhysics()
  phys:SetMass(1)
  phys:SetFriction(0)
  phys:SetDamping(5)
  phys:SetCollisionGroup(COLLISION.CHARACTERS)
	phys:SetCollisionMask(
    COLLISION.GROUND,
    COLLISION.FLYERS,
    COLLISION.OBSTACLES,
		COLLISION.SMALLOBSTACLES,
    COLLISION.CHARACTERS,
		COLLISION.GIANTS)
  phys:SetCapsule(0.5, 1)

  inst.Transform:SetEightFaced()
  --inst.AnimState:EnableDepthTest(true)
  inst.AnimState:SetBuild("mountain_screamer_rancor")
  inst.AnimState:SetBank("mountain_screamer_rancor")
  inst.AnimState:PlayAnimation("appear")
  inst.AnimState:PushAnimation("idle")

  inst.entity:SetPristine()
  if not TheNet:IsDedicated() then
    local fx = SpawnPrefab("mountain_screamer_rancor_smoke")
    fx.Follower:FollowSymbol(inst.GUID, "skull")
    fx.target = inst
    
  end
  if not TheWorld.ismastersim then
    return inst
  end

  inst.persists = false

  inst:AddComponent("combat")
  inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_SCREAMER.RANCOR_DAMAGE)
  inst.components.combat:SetRange(1)
  inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
  
  local updatelooper = inst:AddComponent("updatelooper")
  inst:DoTaskInTime(1, function(inst)
    updatelooper:AddOnUpdateFn(OnUpdate)
    inst.Physics:SetCollisionCallback(OnCollide)
    inst.inertia = TUNING.MOUNTAIN_SCREAMER.RANCOR_SPEED_START
  end)
  inst:DoTaskInTime(0.4, function(inst)
    inst.Physics:SetMotorVel(inst.inertia,0,0)
  end)
  inst.OnEntitySleep = function(inst) inst:Remove() end
  inst.inertia = TUNING.MOUNTAIN_SCREAMER.RANCOR_SPEED_LAUNCH
  inst.last_angle = 0
  

  return inst
  
end

return Prefab("mountain_screamer_rancor", commonfn, guard_assets, guard_prefabs)
