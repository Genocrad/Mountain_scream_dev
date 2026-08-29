
local ENV = env
GLOBAL.setfenv(1, GLOBAL)

-- Let's just pray they do not change this. Or im kinda fucked, lol.

local old_MakeCharacterPhysics = MakeCharacterPhysics

function MakeCharacterPhysics(inst, mass, rad, ...)
  
  
  if TheWorld:HasTag("mountain_scream_dungeons") then
    local phys = inst.entity:AddPhysics()
    phys:SetMass(mass)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.CHARACTERS)
    phys:SetCapsule(rad, 1)
    phys:SetCollisionMask(
      COLLISION.WORLD,
      COLLISION.OBSTACLES,
      COLLISION.SMALLOBSTACLES,
      COLLISION.CHARACTERS,
      COLLISION.GIANTS
    )
    
    if TheWorld.ismastersim then
      phys:SetCollisionMask(
      COLLISION.WORLD,
      COLLISION.OBSTACLES,
      COLLISION.SMALLOBSTACLES,
      COLLISION.CHARACTERS,
      COLLISION.GIANTS,
      COLLISION.MS_CLOUDS
      )  
    end
  
    return phys
  
  
  
  else
    return old_MakeCharacterPhysics(inst, mass, rad, ...)
  end
end

local old_IsTeleportingPermittedFromPointToPoint = IsTeleportingPermittedFromPointToPoint

local function IsMsTechnicalTile(tile)
  return tile == WORLD_TILES.VOID_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL or
         tile == WORLD_TILES.MS_PERMAFROST_TECHNICAL
end

local type_to_points = {
  ["tri"] = {{13,-20}, {13,-9}, {0,0}, {-13,-9}, {-13,-20}, {13,-20}},
  ["round"] = {{-13,-20}, {-13,-8}, {-7,0}, {7,0}, {13,-8}, {13,-20}, {-13,-20}},
  ["rect"] = { {-13,-20}, {-13,0}, {13,0}, {13,-20}, {-13,-20}},
}

function IsTeleportingPermittedFromPointToPoint(fx, fy, fz, tx, ty, tz, ...)
  local map = TheWorld.Map

  if IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(tx, ty, tz)) then
    return false
  end
  if TheWorld.Map:GetTileAtPoint(tx, ty, tz) == WORLD_TILES.MS_CAVE_FLOOR then
    local floor = TheSim:FindEntities(tx, ty, tz, 20, {"ms_focalpoint_floor"})
    floor = floor[1]
    if floor then
      local floor_type = string.gsub(tostring(floor.prefab), "cave_floor_7x5_", "")
      local floor_x, _, floor_z = floor.Transform:GetWorldPosition()
      for j=1, #type_to_points[floor_type]-1 do
        if math2d.LineIntersectsLine(type_to_points[floor_type][j][1], type_to_points[floor_type][j][2], type_to_points[floor_type][j+1][1], type_to_points[floor_type][j+1][2],
         tx-floor_x, tz-floor_z , 0, -10.75) then
          return false
        end
      end
    end
  end
  return old_IsTeleportingPermittedFromPointToPoint(fx, fy, fz, tx, ty, tz, ...)
end
