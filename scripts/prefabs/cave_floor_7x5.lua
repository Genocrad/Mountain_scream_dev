local assets = {
    Asset("ANIM", "anim/cave_floor_7x5.zip")
}
local prefabs = {
  "ms_cave_wall",
}

local function buildrect(triangles, x0 ,x1,z0,z1)
      local y0 = 0
      local y1 = 10
        table.insert(triangles, x0)
        table.insert(triangles, y0)
        table.insert(triangles, z0)

        table.insert(triangles, x0)
        table.insert(triangles, y1)
        table.insert(triangles, z0)

        table.insert(triangles, x1)
        table.insert(triangles, y0)
        table.insert(triangles, z1)

        table.insert(triangles, x1)
        table.insert(triangles, y0)
        table.insert(triangles, z1)

        table.insert(triangles, x0)
        table.insert(triangles, y1)
        table.insert(triangles, z0)

        table.insert(triangles, x1)
        table.insert(triangles, y1)
        table.insert(triangles, z1)
  end
  
  local function OnRemove(inst)
    if TheCamera.target == inst then
      TheCamera.target = TheFocalPoint
    end
  end

  local function MakeFloor(name, anim, spawnwallfn, build_mesh_fn, minimap)
    local function fn()
      local inst = CreateEntity()

      inst.entity:AddTransform()
      inst.entity:AddAnimState()
      inst.entity:AddNetwork()
      inst.entity:AddMiniMapEntity()
      
      inst:AddTag("FX")
      inst:AddTag("decor")
      inst:AddTag("ms_focalpoint_floor")
      
      inst.MiniMapEntity:SetIcon(minimap)
      inst.MiniMapEntity:SetPriority(-100)
      
      -- Causes a crash upon deloading otherwise.
      inst.entity:SetCanSleep(false)
      
      
        
      inst.Transform:SetScale(2.87,3,3)
      --inst.Transform:SetRotation(180)
      inst.AnimState:SetBuild("cave_floor_7x5")
      inst.AnimState:SetBank("cave_floor_7x5")
      inst.AnimState:PlayAnimation(anim)
      inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
      inst.AnimState:SetLayer(LAYER_BACKGROUND)
      inst.AnimState:SetSortOrder(-3)

      local phys = inst.entity:AddPhysics()
      phys:SetMass(0)
      phys:SetFriction(0)
      phys:SetDamping(5)
      phys:SetRestitution(0)
      phys:SetCollisionGroup(COLLISION.BOAT_LIMITS)
      phys:SetCollisionMask(
        COLLISION.CHARACTERS,
        COLLISION.WORLD
      )

      inst.Physics:SetTriangleMesh(build_mesh_fn())
      
      table.insert(MS_FOCALPOINT_FLOORS, inst)
      
      inst.OnRemoveEntity = OnRemove
        
      inst.entity:SetPristine()

      --inst.OnEntityWake = spawnwallfn
      if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, spawnwallfn)
      end


      if not TheWorld.ismastersim then
        return inst
      end
      return inst
    end
    return Prefab(name, fn, assets, prefabs)
  end
  
local function build_mesh_tri()
  local triangles = {}
  local y0 = 0
  local y1 = 4

  -- Back wall
  buildrect(triangles,2,-14.5, 1, -10)
  buildrect(triangles,-13.5,-13.5, -8, -24)
  buildrect(triangles,-2,14.5, 1, -10)
  buildrect(triangles,13.5,13.5, -8, -24)
  buildrect(triangles,-16.5,16.5, -22, -22)
  return triangles
end

local function build_mesh_rect()
  local triangles = {}
  local y0 = 0
  local y1 = 4

  -- Back wall.
  
  
  buildrect(triangles,-14,14,0,0)
  buildrect(triangles,13.5,13.5, 2, -24)
  buildrect(triangles,-13.5,-13.5, 2, -24)
  buildrect(triangles,-16.5,16.5, -22, -22)
  return triangles
end

local function build_mesh_round()
  local triangles = {}
  local y0 = 0
  local y1 = 4

  -- Back wall.
  
  
  buildrect(triangles,-10,10,0,0)
  buildrect(triangles,-6,-14.5, 2, -10)
  buildrect(triangles,-13.5,-13.5, -8, -24)
  buildrect(triangles,6,14.5, 2, -10)
  buildrect(triangles,13.5,13.5, -8, -24)
  buildrect(triangles,-16.5,16.5, -22, -22)
  return triangles
end

local function rectwallfn(inst)
  print("CREATING WALLS")
  
  local x, y, z = inst.Transform:GetWorldPosition()
  local wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(2.13,2.5,2.5)
  wall.Transform:SetPosition(x,y,z)
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(1.34,2.5,2.5)
  wall.Transform:SetPosition(x+14,y,z-10.5)
  wall.Transform:SetRotation(90)
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(1.34,2.5,2.5)
  wall.Transform:SetPosition(x-14,y,z-10.5)
  wall.Transform:SetRotation(270)
  
  
end

local function roundwallfn(inst)

  print("CREATING WALLS")
  local x, y, z = inst.Transform:GetWorldPosition()
  local wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(1.5,2.5,2.5)
  wall.Transform:SetPosition(x,y,z)
  
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(1.12,2.5,2.5)
  wall.Transform:SetPosition(x+10.3,y,z-4)
  wall.Transform:SetRotation(29)
  
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(1.12,2.5,2.5)
  wall.Transform:SetPosition(x-10.3,y,z-4)
  wall.Transform:SetRotation(151)
  
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(0.8,2.5,2.5)
  wall.Transform:SetPosition(x+14,y,z-15)
  wall.Transform:SetRotation(90)
  
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(0.8,2.5,2.5)
  wall.Transform:SetPosition(x-14,y,z-15)
  wall.Transform:SetRotation(270)
  
  
  
end


local function triwallfn(inst)

  print("CREATING WALLS")
  local x, y, z = inst.Transform:GetWorldPosition()
  
  local wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(1.5,2.5,2.5)
  wall.Transform:SetPosition(x+6.9,y,z-4.3)
  wall.Transform:SetRotation(20.5)
  
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(1.5,2.5,2.5)
  wall.Transform:SetPosition(x-6.9,y,z-4.3)
  wall.Transform:SetRotation(159.5)
  
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(0.8,2.5,2.5)
  wall.Transform:SetPosition(x+14.05,y,z-15.05)
  wall.Transform:SetRotation(90)
  
  wall = SpawnPrefab("ms_cave_wall")
  wall.Transform:SetScale(0.8,2.5,2.5)
  wall.Transform:SetPosition(x-14.05,y,z-15.05)
  wall.Transform:SetRotation(270)
  
  
end

return MakeFloor("cave_floor_7x5_round", "half_round",roundwallfn, build_mesh_round, "cave_floor_round.tex" ),
MakeFloor("cave_floor_7x5_rect", "half_rect",rectwallfn, build_mesh_rect, "cave_floor_rect.tex"),
MakeFloor("cave_floor_7x5_tri", "half_tri_spike",triwallfn, build_mesh_tri, "cave_floor_tri.tex")
