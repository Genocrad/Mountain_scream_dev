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
    if IsInstInMSCaves(ThePlayer) then  
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

-- Client-local: mountain floors use surface reverb; side caves / base cave keep cave echo.
local function UpdateMountainReverb(level)
  local ambientsound = TheWorld.components.ambientsound
  if ambientsound == nil then
    return
  end

  local preset = (level ~= nil and level <= TUNING.MS_CAVES_START) and "default" or "cave"
  if TheWorld.ms_reverb_preset ~= preset then
    TheWorld.ms_reverb_preset = preset
    ambientsound:SetReverbPreset(preset)
  end
end

-- Another client-side. Is different from IsUsingMSDoorDirty as it handles camera control

local function UpdateCameraHeightToCave()
  TheCamera.mindist = 15
  TheCamera.maxdist = 35
  TheCamera.mindistpitch = 25
  TheCamera.maxdistpitch = 40
  TheCamera.distancetarget = 25
end

local function UpdateCameraHeightToOverworld()
  TheCamera.mindist = 15
  TheCamera.maxdist = 35
  TheCamera.mindistpitch = 25
  TheCamera.maxdistpitch = 40
  TheCamera.distancetarget = 30
end

local function UpdateCameraHeightToMSCave()
  TheCamera.mindist = 15
  TheCamera.maxdist = 35
  TheCamera.mindistpitch = 25
  TheCamera.maxdistpitch = 40
end

local function LevelUpdateMaster(inst, level)
  if inst.fake_light then inst.fake_light:UpdateLevel(level) end
  if inst.fake_light2 then inst.fake_light2:UpdateLevel(level) end
  if level and level <= TUNING.MS_CAVES_START then
    if TheWorld.state.iscaveday then
      inst.components.sanity:SetLightDrainImmune(true, inst)
    else
      inst.components.sanity:SetLightDrainImmune(false, inst)
    end
  else
    inst.components.sanity:SetLightDrainImmune(false, inst)
  end
end

local old_announce = {}
local old_announce_boss = {} 

local chars = {"GENERIC", "WILLOW", "WOLFGANG", "WENDY", "WX78", "WAXWELL", "WICKERBOTTOM", "WOODIE", "WES", "WAXWELL", "WATHGRITHR", "WEBBER", "WINONA", "WARLY", "WORTOX", "WORMWOOD", "WURT", "WALTER", "WANDA"}

local function CheckMountainLevel(inst, level)
  if level then
    if level <= TUNING.MS_CAVES_START then -- General caves to mountain transition
      for _, char in ipairs(chars) do 
        old_announce[char] = STRINGS.CHARACTERS.GENERIC.ANNOUNCE_WORMS
        old_announce_boss[char] = STRINGS.CHARACTERS.GENERIC.ANNOUNCE_WORMS_BOSS
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_WORMS = STRINGS.CHARACTERS.GENERIC.ANNOUNCE_FALCON
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_WORMS_BOSS = STRINGS.CHARACTERS.GENERIC.ANNOUNCE_FALCON
      end
      TheWorld:PushEvent("wavemanager_on")
      IsUsingMSDoorDirty(inst)
      UpdateCameraHeightToOverworld()
    else -- Mountain to ms caves transition
      UpdateCameraHeightToMSCave()
      TheWorld:PushEvent("wavemanager_off")
      IsUsingMSDoorDirty(inst)
    end
  else -- Ms anything to general caves
    for _, char in ipairs(chars) do 
      if old_announce[char] then
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_WORMS = old_announce[char] 
        STRINGS.CHARACTERS.GENERIC.ANNOUNCE_WORMS_BOSS = old_announce_boss[char]
      end
    end
    TheWorld:PushEvent("wavemanager_off")
    IsUsingMSDoorDirty(inst)
    UpdateCameraHeightToCave()
  end
  
  ThePlayer.map_level_current = level
  ThePlayer.components.playervision:UpdateCCTable()
  UpdateMountainReverb(level)
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
  
  inst:AddComponent("dungeonplayertracker")
  
  if not TheNet:IsDedicated() then
    inst:ListenForEvent("setowner", function(inst)
      if inst == ThePlayer then
        inst:ListenForEvent("mslevelchanged", CheckMountainLevel)
        inst:ListenForEvent("isusingmsdoordirty", IsUsingMSDoorDirty)
        inst:DoTaskInTime(0, CheckMountainLevel) 
        -- Client-only surface rain/snow FX for green vs snow mountain floors.
        if TheWorld:HasTag("mountain_scream_dungeons") then
          if ThePlayer.ms_fake_rain == nil or not ThePlayer.ms_fake_rain:IsValid() then
            ThePlayer.ms_fake_rain = SpawnPrefab("ms_fake_rain")
          end
          if ThePlayer.ms_fake_snow == nil or not ThePlayer.ms_fake_snow:IsValid() then
            ThePlayer.ms_fake_snow = SpawnPrefab("ms_fake_snow")
          end
        end
      end  
    end)
  end
  
  if TheWorld.ismastersim and  TheWorld:HasTag("mountain_scream_dungeons") then
    inst.fake_light = SpawnPrefab("light_fake_overworld")
    inst.fake_light._target = inst   
    -- Otherwise not intensive enough. No, internsity > 1 does not fix this.
    inst.fake_light2 = SpawnPrefab("light_fake_overworld")
    inst.fake_light2._target = inst  
    inst:ListenForEvent("mslevelchanged", LevelUpdateMaster)
  end
end)
