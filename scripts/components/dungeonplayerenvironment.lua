local function FindNearestFloor(inst)
    for _, floor in pairs(MS_FOCALPOINT_FLOORS) do
        if floor:IsValid() and inst:GetDistanceSqToInst(floor) < 28 * 28 then
            return floor
        end
    end
end

local function RemoveFX(fx)
    if fx ~= nil and fx:IsValid() then
        fx:Remove()
    end
end

local DungeonPlayerEnvironment = Class(function(self, inst)
    self.inst = inst
    self.tracker = inst.components.dungeonplayertracker
    self._onlevelchanged = function() self:Apply() end
    self._onrefresh = function() self:Refresh() end
    self._onphase = function() self:ApplyMaster() end
    self._ondoor = function() self:UpdateCameraTarget() end
    self._ondeactivated = function() self:DeactivateClient() end

    inst:ListenForEvent("mslevelchanged", self._onlevelchanged)
    if TheWorld.ismastersim then
        self.lights = {}
        -- Two lights preserve the existing daylight intensity.
        for i = 1, 2 do
            local light = SpawnPrefab("light_fake_overworld")
            light._target = inst
            self.lights[i] = light
        end
        inst:WatchWorldState("cavephase", self._onphase)
    end
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("setowner", self._onrefresh)
        inst:ListenForEvent("playeractivated", self._onrefresh)
        inst:ListenForEvent("playerdeactivated", self._ondeactivated)
        inst:ListenForEvent("isusingmsdoordirty", self._ondoor)
    end
    self._inittask = inst:DoTaskInTime(0, function()
        self._inittask = nil
        self:Refresh()
    end)
end)

function DungeonPlayerEnvironment:Refresh()
    if self.inst == ThePlayer then
        self._clientinactive = false
    end
    self.tracker:Refresh()
    self:Apply()
end

function DungeonPlayerEnvironment:Apply()
    if not self.tracker:IsReady() then
        return
    end
    self:ApplyMaster()
    self:ApplyClient()
end

function DungeonPlayerEnvironment:ApplyMaster()
    if not TheWorld.ismastersim or not self.tracker:IsReady() then
        return
    end
    local level = self.tracker:GetLevel()
    for _, light in ipairs(self.lights) do
        light:UpdateLevel(level)
    end
    if self.inst.components.sanity ~= nil then
        self.inst.components.sanity:SetLightDrainImmune(
            self.tracker:IsInMsOverWorld() and TheWorld.state.cavephase == "day", self.inst)
    end
end

function DungeonPlayerEnvironment:UpdateCameraTarget()
    if self.inst ~= ThePlayer or self._clientinactive or TheCamera == nil or not self.tracker:IsReady() then
        return
    end
    if self.tracker:IsInMsCave() then
        TheCamera.target = FindNearestFloor(self.inst) or TheFocalPoint
        TheCamera.targetoffset.z = -12
        TheCamera.targetoffset.y = 2
        TheCamera.controllable = false
        TheCamera:SetHeadingTarget(270)
    else
        TheCamera.target = TheFocalPoint
        TheCamera.targetoffset.z = 0
        TheCamera.targetoffset.y = 0
        TheCamera.controllable = true
    end
end

function DungeonPlayerEnvironment:ApplyCamera(region)
    -- Keep the current camera tuning; only reset zoom on a change of region type.
    if region == "mountain" then
        TheCamera.mindist = 10
        TheCamera.maxdist = 25
        TheCamera.mindistpitch = 35
        TheCamera.maxdistpitch = 45
        TheCamera.distancetarget = 25
        TheCamera.fov = 50
    else
        TheCamera.mindist = 15
        TheCamera.maxdist = 35
        TheCamera.mindistpitch = 25
        TheCamera.maxdistpitch = 40
        TheCamera.distancetarget = region == "ms_cave" and 30 or 25
        TheCamera.fov = 35
    end
end

function DungeonPlayerEnvironment:SetMountainAnnouncements(enabled)
    if enabled then
        if self._announcements ~= nil then
            return
        end
        self._announcements = {}
        for _, strings in pairs(STRINGS.CHARACTERS) do
            if strings.ANNOUNCE_WORMS ~= nil then
                self._announcements[strings] = {
                    worms = strings.ANNOUNCE_WORMS,
                    boss = strings.ANNOUNCE_WORMS_BOSS,
                }
                local falcon = strings.ANNOUNCE_FALCON or STRINGS.CHARACTERS.GENERIC.ANNOUNCE_FALCON
                strings.ANNOUNCE_WORMS = falcon
                strings.ANNOUNCE_WORMS_BOSS = falcon
            end
        end
    elseif self._announcements ~= nil then
        for strings, original in pairs(self._announcements) do
            strings.ANNOUNCE_WORMS = original.worms
            strings.ANNOUNCE_WORMS_BOSS = original.boss
        end
        self._announcements = nil
    end
end

function DungeonPlayerEnvironment:ApplyClient()
    if TheNet:IsDedicated() or self.inst ~= ThePlayer or self._clientinactive then
        return
    end
    local region = self.tracker:GetRegion()
    local level = self.tracker:GetLevel()
    local changed = self._clientregion ~= region or self._clientlevel ~= level
    if self._clientregion ~= region then
        self:ApplyCamera(region)
        self:SetMountainAnnouncements(region == "mountain")
        TheWorld:PushEvent(region == "mountain" and "wavemanager_on" or "wavemanager_off")
    end
    if changed then
        self:UpdateCameraTarget()
    end
    self._clientregion = region
    self._clientlevel = level

    local ambientsound = TheWorld.components.ambientsound
    local preset = region == "mountain" and "default" or "cave"
    if ambientsound ~= nil and TheWorld.ms_reverb_preset ~= preset then
        ambientsound:SetReverbPreset(preset)
        TheWorld.ms_reverb_preset = preset
    end
    if self.inst.components.playervision ~= nil then
        self.inst.components.playervision:UpdateCCTable()
    end
    if self._rain == nil or not self._rain:IsValid() then
        self._rain = SpawnPrefab("ms_fake_rain")
    end
    if self._snow == nil or not self._snow:IsValid() then
        self._snow = SpawnPrefab("ms_fake_snow")
    end
    if changed then
        self.inst:PushEvent("msenvironmentchanged", {level = level, region = region})
    end
end

function DungeonPlayerEnvironment:DeactivateClient()
    self._clientinactive = true
    self:SetMountainAnnouncements(false)
    RemoveFX(self._rain)
    RemoveFX(self._snow)
    self._rain = nil
    self._snow = nil
    self._clientregion = nil
    self._clientlevel = nil
end

function DungeonPlayerEnvironment:OnRemoveFromEntity()
    self:DeactivateClient()
    if self._inittask ~= nil then
        self._inittask:Cancel()
    end
    self.inst:RemoveEventCallback("mslevelchanged", self._onlevelchanged)
    self.inst:RemoveEventCallback("setowner", self._onrefresh)
    self.inst:RemoveEventCallback("playeractivated", self._onrefresh)
    self.inst:RemoveEventCallback("playerdeactivated", self._ondeactivated)
    self.inst:RemoveEventCallback("isusingmsdoordirty", self._ondoor)
    if TheWorld.ismastersim then
        self.inst:StopWatchingWorldState("cavephase", self._onphase)
        if self.inst.components.sanity ~= nil then
            self.inst.components.sanity:SetLightDrainImmune(false, self.inst)
        end
        for _, light in ipairs(self.lights) do
            RemoveFX(light)
        end
    end
end

DungeonPlayerEnvironment.OnRemoveEntity = DungeonPlayerEnvironment.OnRemoveFromEntity

return DungeonPlayerEnvironment
