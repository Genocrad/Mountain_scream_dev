

local UpvalueHacker = require("tools/upvaluehacker")

local PlayerVision = require("components/playervision")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)
 
local mountain_cc =
 {
  [1] = {
    day = "images/colour_cubes/spring_day_cc.tex",
    dusk = "images/colour_cubes/spring_dusk_cc.tex",
    night = "images/colour_cubes/spring_dusk_cc.tex",--"images/colour_cubes/spring_night_cc.tex",
    full_moon = "images/colour_cubes/purple_moon_cc.tex"
  },
  [2] = {
    day = "images/colour_cubes/spring_day_cc.tex",
    dusk = "images/colour_cubes/spring_dusk_cc.tex",
    night = "images/colour_cubes/spring_dusk_cc.tex",--"images/colour_cubes/spring_night_cc.tex",
    full_moon = "images/colour_cubes/purple_moon_cc.tex"
  },
  [3] = {
    day = "images/colour_cubes/spring_day_cc.tex",
    dusk = "images/colour_cubes/spring_dusk_cc.tex",
    night = "images/colour_cubes/spring_dusk_cc.tex",--"images/colour_cubes/spring_night_cc.tex",
    full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
  [4] = {
    day = "images/colour_cubes/snow_cc.tex",
    dusk = "images/colour_cubes/snowdusk_cc.tex",
    night = "images/colour_cubes/night04_cc.tex",
    full_moon = "images/colour_cubes/purple_moon_cc.tex"
  },
    [5] = {
    day = "images/colour_cubes/snow_cc.tex",
    dusk = "images/colour_cubes/snowdusk_cc.tex",
    night = "images/colour_cubes/night04_cc.tex",
    full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
  [6] = {  
      day = resolvefilepath("images/mountainday_cc.tex"),
      dusk = resolvefilepath("images/mountaindusk_cc.tex"),
      night = resolvefilepath("images/mountainnight_cc.tex"),
      full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
  [7] = {  
      day = resolvefilepath("images/mountainday_cc.tex"),
      dusk = resolvefilepath("images/mountaindusk_cc.tex"),
      night = resolvefilepath("images/mountainnight_cc.tex"),
      full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
      [8] = {  
      day = resolvefilepath("images/mountainday_cc.tex"),
      dusk = resolvefilepath("images/mountaindusk_cc.tex"),
      night = resolvefilepath("images/mountainnight_cc.tex"),
      full_moon = "images/colour_cubes/purple_moon_cc.tex"
    },
  }      
    
local old_updatecc = PlayerVision.UpdateCCTable

local NIGHTVISION_COLOURCUBES = UpvalueHacker.GetUpvalue(old_updatecc, "NIGHTVISION_COLOURCUBES")
local GHOSTVISION_COLOURCUBES = UpvalueHacker.GetUpvalue(old_updatecc, "GHOSTVISION_COLOURCUBES")
local NIGHTVISION_PHASEFN = UpvalueHacker.GetUpvalue(old_updatecc, "NIGHTVISION_PHASEFN")

local MS_CAVE_PHASEFN =
{
    blendtime = 8,
    events = { "phasechanged" }, 
    fn = function()
        return TheWorld.components.worldstate.data["cavephase"]
    end,
}

function PlayerVision:UpdateCCTable()
  old_updatecc(self)
  
  -- So other can actually get those from us.
  
  local hook = NIGHTVISION_COLOURCUBES
  hook = GHOSTVISION_COLOURCUBES
  hook = NIGHTVISION_PHASEFN
  
  if not (self.ghostvision or self.overridecctable or self.nightvision or self.forcenightvision or self.nightmarevision) and self.inst.map_level_current then
    if mountain_cc[self.inst.map_level_current] ~= self.currentcctable then
        self.currentcctable = mountain_cc[self.inst.map_level_current]
        self.inst:PushEvent("ccoverrides", mountain_cc[self.inst.map_level_current])
        self.inst:PushEvent("ccphasefn", MS_CAVE_PHASEFN)
    end
  end  

end



