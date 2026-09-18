

local UpvalueHacker = require("tools/upvaluehacker")
local AddPrefabPostInit = AddPrefabPostInit
local Hounded = require("components/hounded")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local SPAWN_DIST = 30

AddPrefabPostInit("cave", function(inst)
    local Hounded = inst.components.hounded
  if Hounded then

local old_check = UpvalueHacker.GetUpvalue(Hounded.OnUpdate, "CheckForLocationImmunity")

local function CheckForLocationImmunity(player)
   
  local _targetableplayers = UpvalueHacker.GetUpvalue(Hounded.OnUpdate, "_targetableplayers")
	if not _targetableplayers[player.GUID] then
		
		local x,y,z = player.Transform:GetWorldPosition()
		if TheWorld.net.components.dungeonmapoverwatch and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) ~= nil and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) > TUNING.MS_CAVES_START then  
      _targetableplayers[player.GUID] = "ms_caves"
    end
	end
  old_check(player)
end

UpvalueHacker.SetUpvalue(Hounded.OnUpdate, CheckForLocationImmunity, "CheckForLocationImmunity")


local old_summonspawn = UpvalueHacker.GetUpvalue(Hounded.SummonSpawn, "SummonSpawn")

local function NoHoles(pt)
  local x,y,z = pt:Get()
  local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
  return not TheWorld.Map:IsPointNearHole(pt) and not (tile == WORLD_TILES.VOID_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL or
         tile == WORLD_TILES.MS_PERMAFROST_TECHNICAL or
         tile == 3)
end

local function GetSpawnPoint(pt, radius_override)
	if radius_override == nil then
		radius_override = SPAWN_DIST
	end
	if TheWorld.has_ocean then
		local function OceanSpawnPoint(offset)
			local x = pt.x + offset.x
			local y = pt.y + offset.y
			local z = pt.z + offset.z
			return TheWorld.Map:IsAboveGroundAtPoint(x, y, z, true) and NoHoles(pt)
		end

		local offset = FindValidPositionByFan(math.random() * TWOPI, radius_override, 12, OceanSpawnPoint)
		if offset ~= nil then
			offset.x = offset.x + pt.x
			offset.z = offset.z + pt.z
			return offset
		end
	else
		if not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
			pt = FindNearbyLand(pt, 1) or pt
		end
		local offset = FindWalkableOffset(pt, math.random() * TWOPI, radius_override, 12, true, true, NoHoles)
		if offset ~= nil then
			offset.x = offset.x + pt.x
			offset.z = offset.z + pt.z
			return offset
		end
	end
end

local function SummonSpawn(pt, upgrade, radius_override, ...)
	local spawn_pt = GetSpawnPoint(pt, radius_override)
	if spawn_pt ~= nil then
    local x,y,z = spawn_pt:Get()
    if TheWorld.net.components.dungeonmapoverwatch and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) ~= nil then
      local spawn = SpawnPrefab("mountain_falcon")
      if spawn ~= nil then

        if spawn.hounded_overridelocation then
          local new_spawn_pt = spawn:hounded_overridelocation(pt)
          if new_spawn_pt then
            spawn_pt = new_spawn_pt
          end
        end

        if spawn.Physics then        		
          spawn.Physics:Teleport(spawn_pt:Get())
        else
          spawn.Transform:SetPosition(spawn_pt:Get())
        end
        spawn:FacePoint(pt)
        if spawn.components.spawnfader ~= nil then
          spawn.components.spawnfader:FadeIn()
        end
        return spawn
      end
   
    else
      old_summonspawn(pt, upgrade, radius_override, ...)
    end
  end
end

UpvalueHacker.SetUpvalue(Hounded.SummonSpawn, SummonSpawn, "SummonSpawn")


end
end)