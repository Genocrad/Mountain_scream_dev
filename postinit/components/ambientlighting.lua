local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local MountainLighting = require("mountainlighting")
local UpvalueHacker = require("tools/upvaluehacker")

local MS_MOUNTAIN_COLOURS = {}
for _, phase_colours in pairs(MountainLighting.PHASE_COLOUR_SETS) do
    local colours = {}
    for phase, params in pairs(phase_colours) do
        colours[phase] =
        {
            CAVE_COLOUR = params,
            default = params,
        }
    end
    MS_MOUNTAIN_COLOURS[phase_colours] = colours
end

AddComponentPostInit("ambientlighting", function(self)
    if TheNet:IsDedicated() then
        return
    end

    local inst = self.inst
    local _realcolour = UpvalueHacker.GetUpvalue(self.OnUpdate, "_realcolour")
    local _overridecolour = UpvalueHacker.GetUpvalue(self.OnUpdate, "_overridecolour")
    local DoUpdateFlash = UpvalueHacker.GetUpvalue(self.OnUpdate, "DoUpdateFlash")
    local ComputeTargetColour, i, scope_fn
    if type(DoUpdateFlash) == "function" then
        ComputeTargetColour, i, scope_fn = UpvalueHacker.GetUpvalue(DoUpdateFlash, "ComputeTargetColour")
    end
    if _realcolour == nil or _overridecolour == nil or type(ComputeTargetColour) ~= "function" then
        print("[Mountain Scream] Ambient lighting hook unavailable: native colour upvalues not found.")
        return
    end

    local NORMAL_COLOURS = _realcolour.currentcolourset
    local function MS_ComputeTargetColour(targetsettings, timeoverride, ...)
        local player = targetsettings == _overridecolour and targetsettings.currentcolourset == NORMAL_COLOURS
            and MountainLighting.GetLocalMountainPlayer(inst) or nil
        if player ~= nil then
            local phase_colours = MountainLighting.GetPhaseColours(player.components.dungeonplayertracker:GetLevel())
            local colours = MS_MOUNTAIN_COLOURS[phase_colours][MountainLighting.GetPhase(inst)]
            if colours ~= nil then
                -- Replace only the local player's normal visual lighting.
                local temp = targetsettings.currentcolourset
                targetsettings.currentcolourset = colours
                ComputeTargetColour(targetsettings, timeoverride, ...)
                targetsettings.currentcolourset = temp
                return
            end
        end
        ComputeTargetColour(targetsettings, timeoverride, ...)
    end

    debug.setupvalue(scope_fn, i, MS_ComputeTargetColour)

    local current_player, current_phase, current_colours
    function self:MS_RefreshLighting()
        local player = MountainLighting.GetLocalMountainPlayer(inst)
        local phase = player ~= nil and MountainLighting.GetPhase(inst) or nil
        if phase == nil then
            player = nil
        end
        local colours = player ~= nil
            and MountainLighting.GetPhaseColours(player.components.dungeonplayertracker:GetLevel()) or nil
        if player == current_player and phase == current_phase and colours == current_colours then
            return
        end
        local region_changed = player ~= current_player or colours ~= current_colours
        local entering_mountain = region_changed and player ~= nil
        current_player, current_phase, current_colours = player, phase, colours
        -- Apply region lighting immediately on entry; keep normal phase fades.
        MS_ComputeTargetColour(_overridecolour, region_changed and (entering_mountain and 0 or 0.1) or nil)
        if entering_mountain then
            self:OnUpdate(0)
        end
    end

    local function OnPhaseChanged()
        self:MS_RefreshLighting()
    end
    inst:WatchWorldState("cavephase", OnPhaseChanged)
    inst:WatchWorldState("iscavefullmoon", OnPhaseChanged)

    local _OnRemoveFromEntity = self.OnRemoveFromEntity
    function self:OnRemoveFromEntity(...)
        inst:StopWatchingWorldState("cavephase", OnPhaseChanged)
        inst:StopWatchingWorldState("iscavefullmoon", OnPhaseChanged)
        if _OnRemoveFromEntity ~= nil then
            return _OnRemoveFromEntity(self, ...)
        end
    end
end)
