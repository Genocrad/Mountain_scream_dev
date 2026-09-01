local MsCloudsOverlay = require("widgets/ms_clouds_overlay")
local AddPlayerPostInit = AddPlayerPostInit

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local function findnearestfloor(inst)
  for k,v in pairs(MS_FOCALPOINT_FLOORS) do
    -- Rooms should never overlap, so no sorting or figuring out minimum required.
    if v:IsValid() then
      if inst:GetDistanceSqToInst(v) < 28 * 28 then
        return v
      end
    end
  end
  return nil
end

local function IsUsingMSDoorDirty(inst)
    if TheNet:IsDedicated() then return end
   
    local x,y,z = ThePlayer.Transform:GetWorldPosition() 
    if TheWorld.net.components.dungeonmapoverwatch and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) ~= nil and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) > TUNING.MS_CAVES_START then  
        TheCamera.target = findnearestfloor(inst) and findnearestfloor(inst) or TheFocalPoint
        TheCamera.targetoffset.z = -12
        TheCamera.targetoffset.y = 2
        TheCamera.controllable = false
        TheCamera:SetHeadingTarget(270)
        TheCamera.distancetarget = 30
    else
      TheCamera.target = TheFocalPoint
      TheCamera.targetoffset.z = 0
      TheCamera.targetoffset.y = 0
      TheCamera.controllable = true
    end
end

local function CheckMountainLevel(inst)
  local x,y,z = ThePlayer.Transform:GetWorldPosition()
  if TheWorld.net.components.dungeonmapoverwatch then
    local level = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z)
    if level then
      if TheWorld.wavemanager_on == false then
        TheWorld:PushEvent("wavemanager_on")
      end
      if level < 10 and TheCamera.target ~= TheFocalPoint then
        IsUsingMSDoorDirty(inst)
      else
        IsUsingMSDoorDirty(inst)
      end
    elseif level== nil and TheWorld.wavemanager_on == true then
      TheWorld:PushEvent("wavemanager_off")
      IsUsingMSDoorDirty(inst)
    end
    
    ThePlayer.map_level_shown = level
    ThePlayer.map_level_current = level
    
    ThePlayer.components.playervision:UpdateCCTable()
  end
end

AddPlayerPostInit(function(inst)
  -- To cancel stuff we did in MakeCharacterPhysics, as it does not have a name or prefab at loading. (?)
  if not enable_collision_for_player then
    inst.Physics:SetCollisionMask(
        COLLISION.WORLD,
        COLLISION.OBSTACLES,
        COLLISION.SMALLOBSTACLES,
        COLLISION.CHARACTERS,
        COLLISION.GIANTS
      )
  end
  inst._isusingmsdoor = net_ushortint(inst.GUID, "inst._isusingmsdoor", "isusingmsdoordirty")
  inst._isusingmsdoor:set(2)
  if not TheNet:IsDedicated() then
    inst:ListenForEvent("setowner", function(inst)
      if inst == ThePlayer then
      IsUsingMSDoorDirty(inst)
      inst:ListenForEvent("isusingmsdoordirty", IsUsingMSDoorDirty)
      -- Not changearea, as it needs a node, and our artificial islands do not have it...
      inst:DoTaskInTime(0, CheckMountainLevel) 
      inst:DoPeriodicTask(0.3, function(inst) CheckMountainLevel(inst) end)
    end  
    end)
  end
end)
