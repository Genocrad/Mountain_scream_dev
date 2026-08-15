local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

local MapWidget = require("widgets/mapwidget")
local Controls = require("widgets/controls")
local MapControls = require("widgets/mapcontrols")
local MapScreen = require("screens/mapscreen")

-- NOTES(JBK): These constants are from MiniMapRenderer ZOOM_CLAMP_MIN and ZOOM_CLAMP_MAX
local ZOOM_CLAMP_MIN = 1
local ZOOM_CLAMP_MAX = 20

local old_OnZoomIn = MapWidget.OnZoomIn
local old_OnZoomOut = MapWidget.OnZoomOut
local old_Update = MapWidget.OnUpdate

function MapWidget:OnZoomIn(negativedelta)
  if GLOBAL.ThePlayer.map_level_shown then
    return false
  else
    return old_OnZoomIn(self, negativedelta)
  end
end

function MapWidget:OnZoomOut(positivedelta)
  if GLOBAL.ThePlayer.map_level_shown then
    return false
  else
    return old_OnZoomOut(self, positivedelta)
  end
end

function MapWidget:OnUpdate(dt)
  if GLOBAL.ThePlayer.map_level_shown ~= nil then
   
    if not self.shown then 
      GLOBAL.TheCamera.controllable = true 
      GLOBAL.TheWorld:PushEvent("showallplugs")
      if GLOBAL.TheCamera.saved_camera_rotation then
        GLOBAL.TheCamera:SetHeadingTarget(GLOBAL.TheCamera.saved_camera_rotation)
        GLOBAL.TheCamera.heading = GLOBAL.TheCamera.saved_camera_rotation
      end  
      
      return 
    end
    

     
    if GLOBAL.ThePlayer.map_level_shown ~= nil then
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
      end
      end
    end
    
    local x, y = GLOBAL.TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(GLOBAL.ThePlayer.map_level_shown)
    local playerx, playery, playerz = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    
     self.minimap:ResetOffset()
     
     
    self.minimap:Zoom(1.5 - self.minimap:GetZoom())
    GLOBAL.TheCamera.controllable = false
    
    GLOBAL.ThePlayer.HUD.controls:FocusMapOnWorldPosition(TheFrontEnd:GetActiveScreen(), x*0.66 + playerx*0.33, y*0.66 + playerz*0.33)
  else
    GLOBAL.TheCamera.controllable = true
    old_Update(self, dt)
  end
	
end


local MapControlsDungeon = require "widgets/mapcontrols_dungeon"
local MinimapCloudOverlay = require "widgets/minimap_cloud_overlay"

AddGlobalClassPostConstruct("screens/mapscreen", "MapScreen", function(self, owner)
    self.mapcontrolsdungeon = self.bottomright_root:AddChild(MapControlsDungeon())
    self.cloudsoverlay = self.minimap:AddChild(MinimapCloudOverlay())
    self.cloudsoverlay:Disable()
    GLOBAL.TheCamera.saved_camera_rotation = GLOBAL.TheCamera:GetHeadingTarget()
    if GLOBAL.ThePlayer.map_level_shown ~= nil then
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

