local DungeonPlayerTracker = Class(function(self, inst)
    self.inst = inst
    self.level = nil
    self.ready = false
    inst:AddTag("dungeonplayertracker")
    inst:StartUpdatingComponent(self)
end)

function DungeonPlayerTracker:Refresh()
    local level
    if TheWorld:HasTag("mountain_scream_dungeons") then
        local overwatch = TheWorld.net ~= nil and TheWorld.net.components.dungeonmapoverwatch or nil
        if overwatch == nil or not overwatch:IsLevelDataReady() then
            self.ready = false
            return false
        end
        level = overwatch:GetNearestLevel(self.inst.Transform:GetWorldPosition())
    end

    local changed = not self.ready or self.level ~= level
    self.level = level
    self.ready = true
    if changed then
        -- Commit the state before notifying listeners, including the initial nil level.
        self.inst:PushEvent("mslevelchanged", level)
    end
    return true
end

function DungeonPlayerTracker:OnUpdate()
    self:Refresh()
end

function DungeonPlayerTracker:IsReady()
    return self.ready
end

function DungeonPlayerTracker:GetRegion()
    if not self.ready then
        return nil
    elseif self.level ~= nil then
        return self.level <= TUNING.MS_CAVES_START and "mountain" or "ms_cave"
    end
    return TheWorld:HasTag("cave") and "cave" or "surface"
end

function DungeonPlayerTracker:IsInMsCave()
    return self.ready and self.level ~= nil and self.level > TUNING.MS_CAVES_START
end

function DungeonPlayerTracker:IsInMsOverWorld()
    return self.ready and self.level ~= nil and self.level <= TUNING.MS_CAVES_START
end

function DungeonPlayerTracker:IsInMsLevel()
    return self.ready and self.level ~= nil
end

function DungeonPlayerTracker:GetLevel()
    return self.ready and self.level or nil
end

return DungeonPlayerTracker
