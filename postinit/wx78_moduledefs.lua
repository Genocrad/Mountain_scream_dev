local Wx78_ModuleDefs = require("wx78_moduledefs")
local module_definitions = Wx78_ModuleDefs.module_definitions

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

print("MODULE", module_definitions[7].name)

local old_activate = module_definitions[7].activatefn
local old_deactivate = module_definitions[7].deactivatefn

local function OnCaveNightVisionUpdate(inst)
    local playervision = inst.components.playervision
    if playervision then
      
        local on
        if IsInstInMSOverWorld(inst) then
          on = TheWorld.state.iscavenight 
        else
          on = TheWorld.state.isnight and not TheWorld.state.isfullmoon
        end
        
        if on then
            local nonightvisioncc = inst.components.skilltreeupdater:IsActivated("wx78_circuitry_betabuffs_1")
            playervision:PushForcedNightVision(inst, 0, nil, nil, nil, nonightvisioncc)
        else
            playervision:PopForcedNightVision(inst)
        end
    end
end 

local function nightvision_common_activate(inst, wx)
  old_activate(inst, wx)
  if wx._nightvision_modcount == 1 and TheWorld:HasTag("mountain_scream_dungeons") then
    wx:WatchWorldState("iscavenight", OnCaveNightVisionUpdate)
    -- Tau: Let's hope this will not cause problems.
    --wx:ListenForEvent("onactivateskill_client", OnNightVisionUpdate)
    --wx:ListenForEvent("ondeactivateskill_client", OnNightVisionUpdate)
    wx:DoPeriodicTask(1, OnCaveNightVisionUpdate) -- Tau: I do not want to track players, sorry
   
  end
end

local function nightvision_common_deactivate(inst, wx)
  old_deactivate(inst, wx)
  if wx._nightvision_modcount == 0 then
    wx:StopWatchingWorldState("iscavenight", OnCaveNightVisionUpdate)
    --wx:RemoveEventCallback("onactivateskill_client", OnNightVisionUpdate)
    --wx:RemoveEventCallback("ondeactivateskill_client", OnNightVisionUpdate)
    if wx.components.playervision then
      wx.components.playervision:PopForcedNightVision(wx)
    end
  end
end

module_definitions[7].activatefn = nightvision_common_activate
module_definitions[7].deactivatefn = nightvision_common_deactivate
module_definitions[7].client_activatefn = nightvision_common_activate
module_definitions[7].client_deactivatefn = nightvision_common_deactivate