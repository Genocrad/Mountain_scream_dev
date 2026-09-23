local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

local MapWidget = require("widgets/mapwidget")
local Controls = require("widgets/controls")
local MapControls = require("widgets/mapcontrols")
local MapScreen = require("screens/mapscreen")

local old_Update = MapWidget.OnUpdate
local LEVEL_MAX_ZOOM = 4
local MAP_TILE_SIZE = 4
local MAP_BOUNDS_PADDING_TILES = 12

local function GetMapZoomMaximum()
  return GLOBAL.ThePlayer ~= nil and GLOBAL.ThePlayer.map_level_current ~= nil and LEVEL_MAX_ZOOM or 20
end

local function EnforceMapZoomMaximum(mapwidget)
  if mapwidget == nil or mapwidget.minimap == nil then
    return
  end

  local maximum = GetMapZoomMaximum()
  local current_zoom = mapwidget.minimap:GetZoom()
  if current_zoom > maximum then
    mapwidget.minimap:Zoom(maximum - current_zoom)
    current_zoom = mapwidget.minimap:GetZoom()
  end

  local mapscreen = mapwidget.mapscreen
  if mapscreen ~= nil and mapscreen.zoom_target ~= nil and mapscreen.zoom_target > maximum then
    mapscreen.zoom_target = maximum
    mapscreen.zoom_old = current_zoom
    if mapscreen.decorationdata ~= nil then
      mapscreen.decorationdata.dirty = true
    end
  end
end

local old_OnZoomOut = MapWidget.OnZoomOut
function MapWidget:OnZoomOut(positivedelta, ...)
  EnforceMapZoomMaximum(self)
  local maximum = GetMapZoomMaximum()
  local current_zoom = self.minimap:GetZoom()
  if current_zoom >= maximum then
    return false
  end

  positivedelta = math.min(positivedelta or 0.1, maximum - current_zoom)
  return old_OnZoomOut(self, positivedelta, ...)
end

local old_DoZoomOut = MapScreen.DoZoomOut
function MapScreen:DoZoomOut(positivedelta, ...)
  EnforceMapZoomMaximum(self.minimap)
  local maximum = GetMapZoomMaximum()
  local current_zoom = self.minimap:GetZoom()
  self.zoom_target = math.min(self.zoom_target or current_zoom, maximum)
  if current_zoom >= maximum then
    return
  end

  positivedelta = math.min(positivedelta or 0.1, maximum - current_zoom)
  return old_DoZoomOut(self, positivedelta, ...)
end

local old_SetZoom = MapScreen.SetZoom
function MapScreen:SetZoom(zoom_target, ...)
  zoom_target = math.min(zoom_target, GetMapZoomMaximum())
  local result = old_SetZoom(self, zoom_target, ...)
  EnforceMapZoomMaximum(self.minimap)
  return result
end

local function SetFullMapBoundsMask(self)
  if self.img ~= nil then
    self.img:EnableEffectParams2(true)
    self.img:SetEffectParams(0.5, 0.5, 0.5, 0)
    self.img:SetEffectParams2(0, 0.5, 0, 0)
  end
end

local function MapPositionToUV(self, x, z)
  local map_x, map_y = self.minimap:WorldPosToMapPos(x, z, 0)
  if map_x == nil or map_y == nil then
    return nil, nil
  end
  return map_x * 0.5 + 0.5, map_y * 0.5 + 0.5
end

local function LogMapBoundsMask(self, target, kind, message)
  local key = target .. ":" .. kind
  if self._ms_map_bounds_mask_log_key ~= key then
    self._ms_map_bounds_mask_log_key = key
    print("[MS MapBoundsMask] " .. message)
  end
end

local function UpdateMapBoundsMask(self, level, use_base_cave_bounds)
  local target = use_base_cave_bounds and "base_cave" or ("level=" .. tostring(level))
  local overwatch = GLOBAL.TheWorld.net ~= nil and GLOBAL.TheWorld.net.components.dungeonmapoverwatch or nil
  if overwatch == nil then
    LogMapBoundsMask(self, target, "no_overwatch", string.format("%s: dungeonmapoverwatch unavailable", target))
    return
  end

  local min_x, max_x, min_z, max_z
  if use_base_cave_bounds then
    min_x, max_x, min_z, max_z = overwatch:GetBoundsForBaseCave()
  else
    min_x, max_x, min_z, max_z = overwatch:GetBoundsForLevel(level)
  end
  if min_x == nil then
    LogMapBoundsMask(self, target, "no_bounds", string.format("%s: bounds unavailable", target))
    SetFullMapBoundsMask(self)
    return
  end

  local padding = MAP_TILE_SIZE * MAP_BOUNDS_PADDING_TILES
  min_x = min_x - padding
  max_x = max_x + padding
  min_z = min_z - padding
  max_z = max_z + padding

  -- Project all four corners; a rotated world rectangle becomes a parallelogram
  -- in map UV space, so pass its center and two half-edges instead of an AABB.
  local x0, y0 = MapPositionToUV(self, min_x, min_z)
  local x1, y1 = MapPositionToUV(self, max_x, min_z)
  local x2, y2 = MapPositionToUV(self, max_x, max_z)
  local x3, y3 = MapPositionToUV(self, min_x, max_z)
  if x0 == nil or x1 == nil or x2 == nil or x3 == nil then
    LogMapBoundsMask(self, target, "projection_failed", string.format(
      "%s: WorldPosToMapPos failed; world_bounds=[x %.2f..%.2f, z %.2f..%.2f]",
      target, min_x, max_x, min_z, max_z))
    SetFullMapBoundsMask(self)
    return
  end

  local center_u = (x0 + x1 + x2 + x3) * 0.25
  local center_v = (y0 + y1 + y2 + y3) * 0.25
  local half_x_u = (x1 + x2 - x0 - x3) * 0.25
  local half_x_v = (y1 + y2 - y0 - y3) * 0.25
  local half_z_u = (x3 + x2 - x0 - x1) * 0.25
  local half_z_v = (y3 + y2 - y0 - y1) * 0.25
  self.img:EnableEffectParams2(true)
  self.img:SetEffectParams(center_u, center_v, half_x_u, half_x_v)
  self.img:SetEffectParams2(half_z_u, half_z_v, 0, 0)

  local center_x, center_z = self.minimap:MapPosToWorldPos(0, 0, 0)
  local center_u, center_v
  if center_x ~= nil and center_z ~= nil then
    center_u, center_v = MapPositionToUV(self, center_x, center_z)
  end
  LogMapBoundsMask(self, target, "values", string.format(
    "%s world_bounds=[x %.2f..%.2f, z %.2f..%.2f] corners_uv=[(%.4f,%.4f) (%.4f,%.4f) (%.4f,%.4f) (%.4f,%.4f)] mask_center=(%.4f, %.4f) half_x=(%.4f, %.4f) half_z=(%.4f, %.4f) map_center_world=(%s,%s) map_center_uv=(%s,%s) zoom=%.3f",
    target, min_x, max_x, min_z, max_z,
    x0, y0, x1, y1, x2, y2, x3, y3,
    center_u, center_v, half_x_u, half_x_v, half_z_u, half_z_v,
    center_x ~= nil and string.format("%.2f", center_x) or "nil",
    center_z ~= nil and string.format("%.2f", center_z) or "nil",
    center_u ~= nil and string.format("%.4f", center_u) or "nil",
    center_v ~= nil and string.format("%.4f", center_v) or "nil",
    self.minimap:GetZoom()))
end

local function MoveMapCenterTo(self, target_x, target_z)
  local map_x, map_y = self.minimap:WorldPosToMapPos(target_x, target_z, 0)
  if map_x == nil or map_y == nil then
    return
  end

  if math.abs(map_x) < 0.0001 and math.abs(map_y) < 0.0001 then
    return
  end

  local screen_width, screen_height = GLOBAL.TheSim:GetScreenSize()
  local drag_scale = 2 / 9
  self:Offset(-map_x * screen_width * 0.5 * drag_scale, -map_y * screen_height * 0.5 * drag_scale)
end

local function ClampMapCenterToLevel(self, level, center_on_level_change)
  local overwatch = GLOBAL.TheWorld.net.components.dungeonmapoverwatch
  if overwatch == nil then
    return
  end

  if center_on_level_change then
    local center_x, center_z = overwatch:GetPointForLevel(level)
    if center_x ~= nil and center_z ~= nil then
      MoveMapCenterTo(self, center_x, center_z)
    end
    return
  end

  local min_x, max_x, min_z, max_z = overwatch:GetBoundsForLevel(level)
  if min_x == nil then
    return
  end

  local current_x, current_z = self.minimap:MapPosToWorldPos(0, 0, 0)
  if current_x == nil or current_z == nil then
    return
  end

  local clamped_x = math.max(min_x, math.min(max_x, current_x))
  local clamped_z = math.max(min_z, math.min(max_z, current_z))
  MoveMapCenterTo(self, clamped_x, clamped_z)
end

function MapWidget:OnUpdate(dt)
  if GLOBAL.ThePlayer.map_level_shown ~= nil then
   
    if not self.shown then 
      self._ms_map_level_shown = nil
      GLOBAL.TheCamera.controllable = true 
      GLOBAL.TheWorld:PushEvent("showallplugs")
      if GLOBAL.TheCamera.saved_camera_rotation then
        GLOBAL.TheCamera:SetHeadingTarget(GLOBAL.TheCamera.saved_camera_rotation)
        GLOBAL.TheCamera.heading = GLOBAL.TheCamera.saved_camera_rotation
      end  
      
      return 
    end

    -- Let the original widget process drag input before applying the floor bounds.
    old_Update(self, dt)
    EnforceMapZoomMaximum(self)
    
    
     
    if GLOBAL.ThePlayer.map_level_shown ~= nil then
      if not  GLOBAL.TheCamera.saved_camera_rotation then
        GLOBAL.TheCamera.saved_camera_rotation = GLOBAL.TheCamera:GetHeadingTarget()
      end
      GLOBAL.TheWorld:PushEvent("hideallplugs")
      if GLOBAL.ThePlayer.map_level_shown > TUNING.MS_CAVES_START then
        GLOBAL.TheCamera.heading = 270
        GLOBAL.TheCamera:SetHeadingTarget(270)
        self.mapscreen.cloudsoverlay:Disable()
      else
        self.mapscreen.cloudsoverlay:Enable()
        if GLOBAL.TheCamera.saved_camera_rotation then
          GLOBAL.TheCamera:SetHeadingTarget(GLOBAL.TheCamera.saved_camera_rotation)
          GLOBAL.TheCamera.heading = GLOBAL.TheCamera.saved_camera_rotation
           GLOBAL.TheCamera.saved_camera_rotation = nil
        end
      end
    end
    
    local level = GLOBAL.ThePlayer.map_level_shown
    local level_changed = self._ms_map_level_shown ~= level
    ClampMapCenterToLevel(self, level, level_changed)
    self._ms_map_level_shown = level
    if self._ms_map_bounds_mask_active then
      UpdateMapBoundsMask(self, level)
    end
  else
    self._ms_map_level_shown = nil
    GLOBAL.TheCamera.controllable = true
    old_Update(self, dt)
    EnforceMapZoomMaximum(self)
    -- The normal map is also floor-scoped on this custom cave world: follow
    -- the player's current floor. The cave world's own terrain has a separate
    -- captured rectangle; do not substitute floor 1 when the player is outside
    -- all generated level rectangles.
    if self._ms_map_bounds_mask_active then
      local level = GLOBAL.ThePlayer.map_level_current
      if level ~= nil then
        UpdateMapBoundsMask(self, level)
      else
        UpdateMapBoundsMask(self, nil, true)
      end
    end
  end
	
end


local MapControlsDungeon = require "widgets/mapcontrols_dungeon"
local MinimapCloudOverlay = require "widgets/minimap_cloud_overlay"

AddGlobalClassPostConstruct("screens/mapscreen", "MapScreen", function(self, owner)
    self.mapcontrolsdungeon = self.bottomright_root:AddChild(MapControlsDungeon())
    self.cloudsoverlay = self.minimap:AddChild(MinimapCloudOverlay())
    self.cloudsoverlay:Disable()

    local overwatch = GLOBAL.TheWorld.net ~= nil and GLOBAL.TheWorld.net.components.dungeonmapoverwatch or nil
    if overwatch ~= nil then
      self.minimap.img:SetEffect(resolvefilepath("shaders/map_bounds_mask.ksh"))
      self.minimap._ms_map_bounds_mask_active = true
      SetFullMapBoundsMask(self.minimap)
    end

    EnforceMapZoomMaximum(self.minimap)
    
    if GLOBAL.ThePlayer.map_level_shown ~= nil then
      GLOBAL.TheCamera.saved_camera_rotation = GLOBAL.TheCamera:GetHeadingTarget()
      if GLOBAL.ThePlayer.map_level_shown > TUNING.MS_CAVES_START then
        GLOBAL.TheCamera.heading = 270
        GLOBAL.TheCamera:SetHeadingTarget(270)
      end
      GLOBAL.TheWorld:PushEvent("hideallplugs")
    else
      GLOBAL.TheWorld:PushEvent("showallplugs")
    end
  end)

local old_OnBecomeInactive = MapScreen.OnBecomeInactive

function MapScreen:OnBecomeInactive()
  old_OnBecomeInactive(self)
  self.mapcontrolsdungeon:Hide()
  self.cloudsoverlay:Disable()
  if GLOBAL.TheCamera.saved_camera_rotation then
    GLOBAL.TheCamera:SetHeadingTarget(GLOBAL.TheCamera.saved_camera_rotation)
    GLOBAL.TheCamera.heading = GLOBAL.TheCamera.saved_camera_rotation
  end
  local x,y,z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
  if GLOBAL.TheWorld.net.components.dungeonmapoverwatch and GLOBAL.TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) ~= nil and GLOBAL.TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) > GLOBAL.TUNING.MS_CAVES_START then
    GLOBAL.TheCamera.controllable = false
  else
    GLOBAL.TheCamera.controllable = true
  end
end

