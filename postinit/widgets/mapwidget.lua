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
      if GLOBAL.TheCamera.saved_camera_rotation then
        GLOBAL.TheCamera:SetHeadingTarget(GLOBAL.TheCamera.saved_camera_rotation)
        GLOBAL.TheCamera.heading = GLOBAL.TheCamera.saved_camera_rotation
      end  
      
      return 
    end
    
    local x, y = GLOBAL.TheWorld.net.components.dungeonmapoverwatch:GetPointForLevel(GLOBAL.ThePlayer.map_level_shown)
    local playerx, playery, playerz = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    
     self.minimap:ResetOffset()
     
     
     
    GLOBAL.TheCamera.controllable = false
    
    --GLOBAL.ThePlayer.HUD.controls:FocusMapOnWorldPosition(TheFrontEnd:GetOpenScreenOfType("MapScreen"), x*GLOBAL.ThePlayer.mult + playerx*GLOBAL.ThePlayer.player_mult, y*GLOBAL.ThePlayer.mult + playerz*GLOBAL.ThePlayer.player_mult)
    
    local scale = 6 / 9
    self:Offset(scale * (playerx-x), scale * (playerz-y))
    self.minimap:Zoom(1.5 - self.minimap:GetZoom())
  else
    GLOBAL.TheCamera.controllable = true
    old_Update(self, dt)
  end
	
end


local MapControlsDungeon = require "widgets/mapcontrols_dungeon"

AddGlobalClassPostConstruct("screens/mapscreen", "MapScreen", function(self, owner)
    self.mapcontrolsdungeon = self.bottomright_root:AddChild(MapControlsDungeon())
    if GLOBAL.ThePlayer.map_level_shown ~= nil then
      GLOBAL.TheCamera.saved_camera_rotation = GLOBAL.TheCamera:GetHeadingTarget()
      GLOBAL.TheCamera.heading = 270
      GLOBAL.TheCamera:SetHeadingTarget(270)
    end
  end)

local old_OnBecomeInactive = MapScreen.OnBecomeInactive

function MapScreen:OnBecomeInactive()
  old_OnBecomeInactive(self)
  self.mapcontrolsdungeon:Hide()
  
  GLOBAL.TheCamera:SetHeadingTarget(GLOBAL.TheCamera.saved_camera_rotation)
  GLOBAL.TheCamera.heading = GLOBAL.TheCamera.saved_camera_rotation
    
  local x,y,z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
  if GLOBAL.TheWorld.net.components.dungeonmapoverwatch and GLOBAL.TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) ~= nil and GLOBAL.TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) > GLOBAL.TUNING.MS_CAVES_START then
    GLOBAL.TheCamera.controllable = false
  else
    GLOBAL.TheCamera.controllable = true
  end
end

