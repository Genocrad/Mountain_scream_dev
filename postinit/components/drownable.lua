local Drownable = require("components/drownable")
local old_OnFallInVoid =  Drownable.OnFallInVoid
local old_ShouldFallInVoid = Drownable.ShouldFallInVoid
local old_Teleport = Drownable.Teleport

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local function IsMsClouds(tile)
  return tile == WORLD_TILES.CLOUDS_WHITE or
         tile == WORLD_TILES.CLOUDS_DARK 
end

local function IsMsTechnicalTile(tile)
  return tile == WORLD_TILES.VOID_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_LOW_2_TECHNICAL or
         tile == WORLD_TILES.MS_MOUNTAIN_HIGH_TECHNICAL or
         tile == WORLD_TILES.MS_PERMAFROST_TECHNICAL or
         tile == 3 -- Luigi: Sir, i have no idea how this tile is possible at the mountain, but whatever?
end
  
function Drownable:ShouldFallInVoid()
  local x, y, z = self.inst.Transform:GetWorldPosition()
  -- Oof, I cant use isvisualground for overhang. This shall do.
  return (not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and TheWorld.Map:GetTileAtPoint(x, y, z) ~= WORLD_TILES.VOID_TECHNICAL) 
    or old_ShouldFallInVoid(self)
end

function Drownable:Teleport()
  if TheWorld.net.components.dungeonmapoverwatch and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(self.src_x, self.src_y, self.src_z) then
    local target_x, target_y, target_z = self.dest_x, self.dest_y, self.dest_z
    if self.inst.Physics ~= nil then
        self.inst.Physics:Teleport(target_x, target_y, target_z)
    elseif self.inst.Transform ~= nil then
        self.inst.Transform:SetPosition(target_x, target_y, target_z)
    end
  else
    old_Teleport(self)
  end
end

function Drownable:OnFallInVoid(teleport_x, teleport_y, teleport_z)
  
	self.src_x, self.src_y, self.src_z = self.inst.Transform:GetWorldPosition()
  -- we still need this
  if TheWorld.net.components.dungeonmapoverwatch and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(self.src_x, self.src_y, self.src_z) then
    -- Find the closest one. 
    -- Level one in all fail safe scenarios
    local level_in = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(self.src_x, self.src_y, self.src_z) 
    

    if level_in == 2 then
      self.dest_x, self.dest_y, self.dest_z = TheWorld.ms_worldmigrator.Transform:GetWorldPosition()
      self.dest_x = self.dest_x + 1.5;
      self.dest_z = self.dest_z + 1.5;
    elseif level_in == 10 then
      self.dest_x, self.dest_y, self.dest_z = TheWorld.ms_arenateleporter.Transform:GetWorldPosition()
      self.dest_x = self.dest_x + 1.5;
      self.dest_z = self.dest_z + 1.5;
    else
      local level_x, level_z =  TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(level_in)
      local delta_x, delta_z = level_x - self.src_x, level_z - self.src_z
      
      local level_to_x, level_to_z =  TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(level_in-1)
      if TileGroupManager:IsLandTile(TheWorld.Map:GetTileAtPoint(level_to_x - delta_x, 0, level_to_z - delta_z)) and not IsMsTechnicalTile(TheWorld.Map:GetTileAtPoint(level_to_x - delta_x, 0, level_to_z - delta_z)) then
       self.dest_x, self.dest_y, self.dest_z = TheWorld.Map:GetTileCenterPoint(level_to_x - delta_x, 0, level_to_z - delta_z)
      else
        for check_x = 0, 80 do -- Performance-wise would be better to make it go in steps of 4, but then it leads to some ugly results.
          for check_z = 0, 80  do
            local check_tile = TheWorld.Map:GetTileAtPoint(level_to_x - delta_x + check_x, 0, level_to_z - delta_z + check_z)
            if not IsMsTechnicalTile(check_tile) and TileGroupManager:IsLandTile(check_tile) then
               self.dest_x, self.dest_y, self.dest_z = level_to_x - delta_x + check_x, 0, level_to_z - delta_z + check_z
               return -- Found land! Abort the search!
            end
            check_tile = TheWorld.Map:GetTileAtPoint(level_to_x - delta_x - check_x, 0, level_to_z - delta_z + check_z)
            if not IsMsTechnicalTile(check_tile) and TileGroupManager:IsLandTile(check_tile) then
               self.dest_x, self.dest_y, self.dest_z = level_to_x - delta_x - check_x, 0, level_to_z - delta_z + check_z
               return
            end
            check_tile = TheWorld.Map:GetTileAtPoint(level_to_x - delta_x - check_x, 0, level_to_z - delta_z - check_z)
            if not IsMsTechnicalTile(check_tile) and TileGroupManager:IsLandTile(check_tile) then
               self.dest_x, self.dest_y, self.dest_z = level_to_x - delta_x - check_x, 0, level_to_z - delta_z - check_z
               return
            end
            check_tile = TheWorld.Map:GetTileAtPoint(level_to_x - delta_x + check_x, 0, level_to_z - delta_z - check_z)
            if not IsMsTechnicalTile(check_tile) and TileGroupManager:IsLandTile(check_tile) then
               self.dest_x, self.dest_y, self.dest_z = level_to_x - delta_x + check_x, 0, level_to_z - delta_z - check_z
               return
            end
          end
        end
        self.dest_x, self.dest_y, self.dest_z = TheWorld.ms_worldmigrator.Transform:GetWorldPosition()
        return
      end
    end
  else
    old_OnFallInVoid(self, teleport_x, teleport_y, teleport_z)
  end
end
