--------------------------------------------------------------------------
-- 全局控制山岭魔像地基：魔像/魔柱存在期间，所有 platform 均不可建造
--------------------------------------------------------------------------

local MountainGolemPlatformCtrl = Class(function(self, inst)
	self.inst = inst
	self.platforms = {}
	self.locked = false
	self._refresh_task = nil
end)

local function IsActiveSummon(ent)
	return ent ~= nil
		and ent:IsValid()
		and not ent:IsInLimbo()
		and (ent:HasTag("mountain_golem") or ent:HasTag("mountain_golem_pillar"))
end

function MountainGolemPlatformCtrl:HasActiveSummon()
	for _, ent in pairs(Ents) do
		if IsActiveSummon(ent)
			and (ent.prefab == "mountain_golem" or ent.prefab == "mountain_golem_pillar")
		then
			return true
		end
	end
	return false
end

function MountainGolemPlatformCtrl:RegisterPlatform(platform)
	if platform == nil then
		return
	end
	self.platforms[platform] = true
	if platform.SetConstructionLocked ~= nil then
		platform:SetConstructionLocked(self.locked)
	end
end

function MountainGolemPlatformCtrl:UnregisterPlatform(platform)
	if platform ~= nil then
		self.platforms[platform] = nil
	end
end

function MountainGolemPlatformCtrl:SetLocked(locked)
	locked = locked == true
	if self.locked == locked then
		-- 仍同步一遍，避免存档加载顺序导致个别平台状态不一致
		if locked then
			for platform in pairs(self.platforms) do
				if platform:IsValid() and platform.SetConstructionLocked ~= nil then
					platform:SetConstructionLocked(true)
				end
			end
		end
		return
	end

	self.locked = locked
	for platform in pairs(self.platforms) do
		if platform:IsValid() and platform.SetConstructionLocked ~= nil then
			platform:SetConstructionLocked(locked)
		else
			self.platforms[platform] = nil
		end
	end
end

function MountainGolemPlatformCtrl:LockAll()
	self:SetLocked(true)
end

function MountainGolemPlatformCtrl:UnlockAll()
	self:SetLocked(false)
end

function MountainGolemPlatformCtrl:Refresh()
	self:SetLocked(self:HasActiveSummon())
end

function MountainGolemPlatformCtrl:ScheduleRefresh()
	if self._refresh_task ~= nil then
		self._refresh_task:Cancel()
	end
	self._refresh_task = self.inst:DoTaskInTime(0, function()
		self._refresh_task = nil
		self:Refresh()
	end)
end

function MountainGolemPlatformCtrl:NotifySummonSpawned()
	self:LockAll()
end

function MountainGolemPlatformCtrl:NotifySummonRemoved()
	self:ScheduleRefresh()
end

function MountainGolemPlatformCtrl:OnSave()
	return { locked = self.locked or nil }
end

function MountainGolemPlatformCtrl:OnLoad(data)
	if data ~= nil and data.locked then
		self.locked = true
	end
end

function MountainGolemPlatformCtrl:OnLoadPostPass()
	self:Refresh()
	-- 再同步一次已注册平台（Refresh 时可能尚未全部 Register）
	self.inst:DoTaskInTime(0, function()
		self:Refresh()
	end)
end

return MountainGolemPlatformCtrl
