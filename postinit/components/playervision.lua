

local UpvalueHacker = require("tools/upvaluehacker")

local PlayerVision = require("components/playervision")

local ENV = env
GLOBAL.setfenv(1, GLOBAL)
 
local mountain_cc = require("mountaincolourcubes")

local old_updatecc = PlayerVision.UpdateCCTable

local NIGHTVISION_COLOURCUBES = UpvalueHacker.GetUpvalue(old_updatecc, "NIGHTVISION_COLOURCUBES")
local GHOSTVISION_COLOURCUBES = UpvalueHacker.GetUpvalue(old_updatecc, "GHOSTVISION_COLOURCUBES")
local NIGHTVISION_PHASEFN = UpvalueHacker.GetUpvalue(old_updatecc, "NIGHTVISION_PHASEFN")

local MS_CAVE_PHASEFN =
{
    blendtime = 8,
    events = { "phasechanged", "moonphasechanged2" },
    fn = function()
        local state = TheWorld.state
        return state.cavephase == "night" and state.iscavefullmoon and "full_moon" or state.cavephase
    end,
}

function PlayerVision:UpdateCCTable()
    -- Keep the native upvalues reachable for other vision integrations.
    local hook = NIGHTVISION_COLOURCUBES
    hook = GHOSTVISION_COLOURCUBES
    hook = NIGHTVISION_PHASEFN

    local tracker = self.inst.components.dungeonplayertracker
    local cctable = tracker ~= nil and mountain_cc[tracker:GetLevel()] or nil
    if cctable ~= nil and not (self.ghostvision or self.overridecctable
        or self.nightvision or self.forcenightvision or self.nightmarevision or self.blendcctable) then
        if self.currentcctable ~= cctable or self.currentccphasefn ~= MS_CAVE_PHASEFN then
            self.currentcctable = cctable
            self.currentccphasefn = MS_CAVE_PHASEFN
            self.inst:PushEvent("ccoverrides", cctable)
            self.inst:PushEvent("ccphasefn", MS_CAVE_PHASEFN)
        end
    else
        -- Native vision priorities also clear the mountain override when leaving.
        old_updatecc(self)
    end
end
