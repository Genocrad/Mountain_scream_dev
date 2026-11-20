
local AOEUtil = require("aoeutil")

local assets = {
    Asset("ANIM", "anim/whirlportal.zip"),
}

local prefabs = {
    "wave_med",
    "oceanwhirlportal_splash",
}

local bone_assets =
{
    Asset("ANIM", "anim/fossil_spike.zip"),
}

local bone_prefabs =
{
    "erode_ash",
    "fossilspike_base",
}
local function KeepTargetFn()
    return false
end

local function OnCollideBone(inst, other)
  if other ~= nil then
    if not other:HasTag("epic") then
      if other.components.health then
         inst.components.combat:DoAttack(other)
         inst:Remove()
      end
    end
  end
end
  
local function bonefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fossil_spike")
    inst.AnimState:SetBuild("fossil_spike")
    inst.AnimState:PlayAnimation("fossil_pst")
    inst.AnimState:SetFinalOffset(1)

    inst.Physics:SetMass(10)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
	inst.Physics:SetCollisionMask(
		COLLISION.ITEMS,
		COLLISION.OBSTACLES,
    COLLISION.CHARACTERS,
		COLLISION.WORLD
	)
    inst.Physics:SetCapsule(0.5, 2)

    inst:AddTag("notarget")
    inst:AddTag("groundspike")
    inst:AddTag("fossilspike")

    inst.entity:SetPristine()
    
    inst.SoundEmitter:PlaySound("rifts2/shadow_rift/shadowrift_portal_allstage")
      
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_PROJ)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    
    inst.Physics:SetCollisionCallback(OnCollideBone)
    inst.persists = false
    
    local variation = math.random(7)
    if variation > 1 then
        inst.AnimState:OverrideSymbol("bone1", "fossil_spike", "bone"..tostring(variation))
    end

    return inst
end

local function MakeSmallAndStretch(inst)
  if inst.ms_sizechange then
    inst.ms_sizechange = inst.ms_sizechange - 0.04
    inst.Transform:SetScale(inst.ms_sizechange, math.min(inst.ms_sizechange + 0.2, 1), 1)
  end
end

local function OnUpdate(inst)
	if inst == nil then
		return
	end
  
	local x, y, z = inst.Transform:GetWorldPosition()
	local range = TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_PULL_RANGE
	local player_count = 0
  for i, v in ipairs(TheSim:FindEntities(x, y, z, range, nil, {"NOCLICK", "FX", "DECOR", "playerghost", "INLIMBO", "birdblocker", "eatenup_stopcolliding"})) do
    if v.Physics and (v.components.locomotor or v.components.inventoryitem or v:HasTag("groundspike"))  then -- If it does not have phisics, we probably should not move it.
                                                                                 -- If it does not have locomotor or inventoryitem, then it also probably was not planned to be moved.
      local x1,y1,z1 = v.Transform:GetWorldPosition()
      local dist = math.sqrt(v:GetDistanceSqToPoint(x,y,z))
      if dist ~= 0 then
        v.Transform:SetPosition(x1 - (x1-x) / ((dist) * math.max(dist, 3)), y1, z1 - (z1-z)/(dist * math.max(dist, 3)))
      end
      if v:HasTag("player") then
        if not v.sg:HasStateTag("devoured") then
          player_count = player_count + 1
        end
      end
    end
	end
  if player_count == 0 or inst.amount_fed == TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_MAX then
    inst:DoTaskInTime(4, inst.EndWhirlPool) 
  end
end

local function EndWhirlPool(inst)
  inst.components.inventory:DropEverything(true)
  for k, v in pairs(inst.bones) do
    if v ~= nil and v:IsValid() then
      v:Remove()
    end
  end
  for k, v in pairs(inst.bone_tasks) do
    v:Cancel()
  end
  inst.screamer:PushEvent("whirlpool_end", {blink_pos = inst:GetPosition()})
  inst:Remove()
end

local function IsMsTechnicalTile(tile)
  return tile == WORLD_TILES.VOID_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL or
  tile == WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL or
  tile == WORLD_TILES.MS_PERMAFROST_TECHNICAL or 
  tile == WORLD_TILES.MS_BRIDGE or 
  (not TileGroupManager:IsLandTile(tile))
end

-- We are spawned in, we need to determine where can we actually spawn?
local function SetupPoints(inst)
  local x,y,z = inst.Transform:GetWorldPosition()
  for i = 0, 179 do
    local radius = TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_PULL_RANGE - 1
    local x1,z1
    for j = 0, 20 do
      x1,z1 = x + (radius-j) * math.cos(math.rad(2*i)), z - (radius-j) * math.sin(math.rad(2*i))
      if not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(x1, 0, z1)) then
        break
      end
    end
    table.insert(inst.points, {x1, z1})
  end
end
  
local function SpawnBones(inst)
  for k=0, TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_BONE_IN_WAVE do
    local rnd = math.random(3, 177)
    for i=-2, 2 do
      local point = inst.points[rnd + i] 
      local x, z = point[1], point[2]
      local bone = SpawnPrefab("mountain_screamer_bone_proj")
      bone.Transform:SetPosition(x,0,z)
      bone:FacePoint(inst.Transform:GetWorldPosition())
      table.insert(inst.bones, bone)
    end
  end
end

local function OnCollide(inst, other)
  if other ~= nil then
    if not other:HasTag("epic") and not other:HasTag("eatenup_stopcolliding") then
      if other:HasTag("groundspike") then
        other:Remove()
      end
      if other.components.inventoryitem then
        if other.components.inventoryitem.canbepickedup and other.components.inventoryitem.cangoincontainer then
          inst.components.inventory:GiveItem(other)
        end
      end
    
      -- Bon appetite!
      if inst.amount_fed < TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_MAX  then
        if other:HasTag("player") then  
          other:PushEventImmediate("devoured", {attacker = inst})
          inst.screamer.components.health:DoDelta(TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_HEAL_PLAYER)
          table.insert(inst.screamer.devoured_inst, other)
          inst.amount_fed = inst.amount_fed + 3
        elseif other:HasAnyTag("character", "smallcreature", "devourable") then
          inst.amount_fed = inst.amount_fed + 1
          if not other.components.updatelooper then
            other:AddComponent("updatelooper")
          end
          other.ms_sizechange = 1
          other.components.updatelooper:AddOnUpdateFn(MakeSmallAndStretch)
          other:DoTaskInTime(1, inst.Remove)
          other:AddTag("eatenup_stopcolliding")
          if other.components.edible then
            inst.screamer.components.health:DoDelta(other.components.edible.hungervalue)
          else
            inst.screamer.components.health:DoDelta(TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_HEAL_NONPLAYER)
          end
        end
      else -- Just damage and knockback.
        other:PushEvent("knockback", { knocker = inst, radius = TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_RADIUS, strengthmult = TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_KNOCKBACK, forcelanded = false })
        if other.components.health then
          inst.components.combat:DoAttack(other)
        end
        other:AddTag("eatenup_stopcolliding")
        other:DoTaskInTime(2, function(inst) other:RemoveTag("eatenup_stopcolliding") end)
      end
    end
  end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("whirlportal")
    inst.AnimState:SetBank("whirlportal")
    inst.AnimState:PlayAnimation("open_pre")
    inst.AnimState:PushAnimation("open_loop", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_WHIRLPORTAL)
    inst.AnimState:SetMultColour(0.1,0,0.1,1)
    
    inst:AddTag("birdblocker")

    inst:SetDeployExtraSpacing(2)
    
    inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:SetCollisionMask(
        COLLISION.ITEMS,
        COLLISION.OBSTACLES,
        COLLISION.CHARACTERS,
        COLLISION.FLYERS,
        COLLISION.GIANTS
    )
    
    inst.Physics:SetCollides(false)
    inst.Physics:SetCapsule(2, 1)
    
    inst.persists = false
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("updatelooper")    
    
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_DAMAGE)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
 
    inst:AddComponent("inventory")
    inst.components.inventory.maxslots = 50
        
    inst.Physics:SetCollisionCallback(OnCollide)
    
    inst.amount_fed = 0
    inst.points = {}
    inst.bones = {}
    inst.bone_tasks = {}
    inst.EndWhirlPool = EndWhirlPool 
    
    inst:DoTaskInTime(0, SetupPoints)
    
    for i=1, TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_BONE_WAVES do
      local task = inst:DoTaskInTime(i-0.5, SpawnBones)
      table.insert(inst.bone_tasks, task)
    end
      
    inst:DoTaskInTime(1, function(inst)
      inst.components.updatelooper:AddOnUpdateFn(OnUpdate)
      inst:DoTaskInTime(TUNING.MOUNTAIN_SCREAMER.WHIRLPOOL_BONE_WAVES + 4, inst.EndWhirlPool)
    end)
  
    return inst
end

return Prefab("mountain_screamer_whirlpool", fn, assets, prefabs), 
        Prefab("mountain_screamer_bone_proj", bonefn, bone_assets, bone_prefabs)

