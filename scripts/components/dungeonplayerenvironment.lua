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
    self._oncameraupdate = function() self:UpdateCameraClouds() end

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
        TheCamera.targetoffset.z = -14
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
    -- Reset zoom on region changes or when the native camera restores defaults.
    if region == "mountain" then
        TheCamera.mindist = 10
        TheCamera.maxdist = 50
        TheCamera.mindistpitch = 30
        TheCamera.maxdistpitch = 50
        TheCamera.distancetarget = 30
        TheCamera.fov = 35
    elseif region == "ms_cave" then
        TheCamera.mindist = 15
        TheCamera.maxdist = 35
        TheCamera.mindistpitch = 25
        TheCamera.maxdistpitch = 40
        TheCamera.distancetarget = 30
        TheCamera.fov = 35
    else
        TheCamera.mindist = 15
        TheCamera.maxdist = 35
        TheCamera.mindistpitch = 25
        TheCamera.maxdistpitch = 40
        TheCamera.distancetarget = 25
        TheCamera.fov = 35
    end
end

function DungeonPlayerEnvironment:OnCameraReset()
    if TheNet:IsDedicated() or self.inst ~= ThePlayer or self._clientinactive or not self.tracker:IsReady() then
        return
    end
    local region = self.tracker:GetRegion()
    if region == "mountain" or region == "ms_cave" then
        -- Native defaults use the shard's cave tag, which does not describe our regions.
        self:ApplyCamera(region)
        self:UpdateCameraTarget()
    end
end

function DungeonPlayerEnvironment:ClearCameraClouds()
    local hud = self._cloudhud
    if hud ~= nil and hud.clouds_on then
        hud.clouds_on = false
        hud.clouds:Hide()
        TheFocalPoint.SoundEmitter:KillSound("windsound")
        TheMixer:PopMix("high")
    end
    if self._cloudcamera ~= nil then
        self._cloudcamera.should_push_down = false
    end
    self._cloudhud = nil
end

function DungeonPlayerEnvironment:UpdateCameraClouds()
    if self.inst ~= ThePlayer or self._clientinactive or not self.tracker:IsInMsOverWorld() then
        self:SetCameraCloudsEnabled(false)
        return
    end
    local hud = self.inst.HUD
    if hud ~= self._cloudhud then
        self:ClearCameraClouds()
        self._cloudhud = hud
    end
    if hud ~= nil then
        hud:UpdateClouds(self._cloudcamera)
    end
end

function DungeonPlayerEnvironment:SetCameraCloudsEnabled(enabled)
    if self._cloudcamera ~= nil and (not enabled or self._cloudcamera ~= TheCamera) then
        self._cloudcamera:RemoveListener(self)
        self:ClearCameraClouds()
        self._cloudcamera = nil
    end
    if enabled and self._cloudcamera == nil then
        self._cloudcamera = TheCamera
        -- Use a listener so HUD activation cannot replace this with its cave callback.
        self._cloudcamera:AddListener(self, self._oncameraupdate)
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
    self:SetCameraCloudsEnabled(region == "mountain")
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
    self:SetCameraCloudsEnabled(false)
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
