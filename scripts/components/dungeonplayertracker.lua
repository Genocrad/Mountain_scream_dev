local DungeonPlayerTracker = Class(function(self, inst)
    self.inst = inst
    self.lastlevel = nil
    self.level = nil
    inst:AddTag("dungeonplayertracker")    
    self.inst:StartUpdatingComponent(self)
end)

function DungeonPlayerTracker:OnUpdate()
  if not TheWorld.net.components.dungeonmapoverwatch then
    return
  end
  
  local x,y,z = self.inst.Transform:GetWorldPosition()
  
  self.level = TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z)
  
  if self.level ~= self.lastlevel then
    self.inst:PushEvent("mslevelchanged", self.level)
  end
  
  self.lastlevel = self.level
end

function DungeonPlayerTracker:IsInMsCave()
  if not self.level then
    return false
  end
  if self.level > TUNING.MS_CAVES_START then
    return true
  end
  return false
end

function DungeonPlayerTracker:IsInMsOverWorld()
  if not self.level then
    return false
  end
  if self.level <= TUNING.MS_CAVES_START then
    return true
  end
  return false
end

function DungeonPlayerTracker:IsInMsLevel()
  if self.level then
    return true
  end
  return false
end

function DungeonPlayerTracker:GetLevel()
  return self.level
end

return DungeonPlayerTracker
