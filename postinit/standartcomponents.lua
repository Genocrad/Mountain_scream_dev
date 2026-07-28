
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