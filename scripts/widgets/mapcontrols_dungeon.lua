local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local PauseScreen = require "screens/redux/pausescreen"


local MAPSCALE = .5
local function GetCurrentLevel()
  local tracker = ThePlayer ~= nil and ThePlayer.components.dungeonplayertracker or nil
  return tracker ~= nil and tracker:GetLevel() or nil
end

local function OnLevelPressedUp()
  if GetCurrentLevel() == nil then
    return
  end
  ThePlayer.map_level_shown = math.min((ThePlayer.map_level_shown or GetCurrentLevel()) + 1, 12)
end

local function OnLevelPressedDown()
  if GetCurrentLevel() == nil then
    return
  end
  ThePlayer.map_level_shown = math.max((ThePlayer.map_level_shown or GetCurrentLevel()) - 1, 2)
end


--base class for imagebuttons and animbuttons.
local MapControlsDungeon = Class(Widget, function(self)
    Widget._ctor(self, "Map Controls Dungeon")
    
    if ThePlayer then
        ThePlayer.map_level_shown = GetCurrentLevel()
    end
    
    self.OnLevelPressedUp = OnLevelPressedUp
    self.level1 = self:AddChild(ImageButton("images/hud.xml", "craft_end_normal.tex", nil, nil, nil, nil, {1,1}, {0,0}))
    self.level1:SetPosition(-60, 240, 0)
    self.level1:SetScale(-.7, -.7, .7)
    self.level1:SetOnClick(self.OnLevelPressedUp)

    self.OnLevelPressedDown = OnLevelPressedDown
    self.level2 = self:AddChild(ImageButton("images/hud.xml", "craft_end_normal.tex", nil, nil, nil, nil, {1,1}, {0,0}))
    self.level2:SetPosition(-60, 160, 0)
    self.level2:SetScale(-.7, .7, .7)
    self.level2:SetOnClick(self.OnLevelPressedDown)
    
    if not TheWorld:HasTag("mountain_scream_dungeons") or GetCurrentLevel() == nil then
      self:Hide()
    end
    --self:RefreshTooltips(mountain_scream_dungeons)
end)

return MapControlsDungeon
