--------------------------------------------------------------------------
--[[ MountainButterflySpawner class definition ]]
--[[ Spawns mountain_butterfly from mountain_plants_flower only. ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "MountainButterflySpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

self.inst = inst

local _activeplayers = {}
local _scheduledtasks = {}
local _worldstate = TheWorld.state
local _updating = false
local _butterflies = {}
local _maxbutterflies = TUNING.MOUNTAIN_BUTTERFLY.MAX
local _iscave = TheWorld:HasTag("cave")

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local FLOWER_TAGS = { "mountain_flower" }
local BUTTERFLY_TAGS = { "mountain_butterfly" }

local function GetSpawnPoint(player)
	local rad = 25
	local mindistance = 36
	local x, y, z = player.Transform:GetWorldPosition()
	local flowers = TheSim:FindEntities(x, y, z, rad, FLOWER_TAGS)

	for i, v in ipairs(flowers) do
		while v ~= nil and (v.prefab ~= "mountain_plants_flower" or player:GetDistanceSqToInst(v) <= mindistance) do
			table.remove(flowers, i)
			v = flowers[i]
		end
	end

	return next(flowers) ~= nil and flowers[math.random(1, #flowers)] or nil
end

local function SpawnButterflyForPlayer(player, reschedule)
	local pt = player:GetPosition()
	local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, 64, BUTTERFLY_TAGS)
	if #ents < _maxbutterflies then
		local spawnflower = GetSpawnPoint(player)
		if spawnflower ~= nil then
			local butterfly = SpawnPrefab("mountain_butterfly")
			if butterfly ~= nil then
				if butterfly.components.pollinator ~= nil then
					butterfly.components.pollinator:Pollinate(spawnflower)
				end
				if butterfly.components.homeseeker ~= nil then
					butterfly.components.homeseeker:SetHome(spawnflower)
				end
				butterfly.Physics:Teleport(spawnflower.Transform:GetWorldPosition())
			end
		end
	end
	_scheduledtasks[player] = nil
	reschedule(player)
end

local function ScheduleSpawn(player, initialspawn)
	if _scheduledtasks[player] == nil then
		local basedelay = initialspawn and 0.3 or 10
		_scheduledtasks[player] = player:DoTaskInTime(basedelay + math.random() * 10, SpawnButterflyForPlayer, ScheduleSpawn)
	end
end

local function CancelSpawn(player)
	if _scheduledtasks[player] ~= nil then
		_scheduledtasks[player]:Cancel()
		_scheduledtasks[player] = nil
	end
end

local function IsSpawnDay()
	if _iscave then
		return _worldstate.iscaveday
	end
	return _worldstate.isday
end

local function CanSpawnSeason()
	-- Caves: all seasons. Overworld: match vanilla (no winter).
	if _iscave then
		return true
	end
	return not _worldstate.iswinter
end

local function ToggleUpdate(force)
	if IsSpawnDay() and CanSpawnSeason() and _maxbutterflies > 0 then
		if not _updating then
			_updating = true
			for i, v in ipairs(_activeplayers) do
				ScheduleSpawn(v, true)
			end
		elseif force then
			for i, v in ipairs(_activeplayers) do
				CancelSpawn(v)
				ScheduleSpawn(v, true)
			end
		end
	elseif _updating then
		_updating = false
		for i, v in ipairs(_activeplayers) do
			CancelSpawn(v)
		end
	end
end

local function AutoRemoveTarget(inst, target)
	if _butterflies[target] ~= nil and target:IsAsleep() then
		target:Remove()
	end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnTargetSleep(target)
	inst:DoTaskInTime(0, AutoRemoveTarget, target)
end

local function OnPlayerJoined(src, player)
	for i, v in ipairs(_activeplayers) do
		if v == player then
			return
		end
	end
	table.insert(_activeplayers, player)
	if _updating then
		ScheduleSpawn(player, true)
	end
end

local function OnPlayerLeft(src, player)
	for i, v in ipairs(_activeplayers) do
		if v == player then
			CancelSpawn(player)
			table.remove(_activeplayers, i)
			return
		end
	end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

for i, v in ipairs(AllPlayers) do
	table.insert(_activeplayers, v)
end

if _iscave then
	inst:WatchWorldState("iscaveday", ToggleUpdate)
else
	inst:WatchWorldState("isday", ToggleUpdate)
	inst:WatchWorldState("iswinter", ToggleUpdate)
end
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
	ToggleUpdate(true)
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self.StartTrackingFn(target)
	if _butterflies[target] == nil then
		local restore = target.persists and 1 or 0
		target.persists = false
		if target.components.homeseeker == nil then
			target:AddComponent("homeseeker")
		else
			restore = restore + 2
		end
		_butterflies[target] = restore
		inst:ListenForEvent("entitysleep", OnTargetSleep, target)
	end
end

function self:StartTracking(target)
	self.StartTrackingFn(target)
end

function self.StopTrackingFn(target)
	local restore = _butterflies[target]
	if restore ~= nil then
		target.persists = restore == 1 or restore == 3
		if restore < 2 then
			target:RemoveComponent("homeseeker")
		end
		_butterflies[target] = nil
		inst:RemoveEventCallback("entitysleep", OnTargetSleep, target)
	end
end

function self:StopTracking(target)
	self.StopTrackingFn(target)
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
	local numbutterflies = 0
	for k, v in pairs(_butterflies) do
		numbutterflies = numbutterflies + 1
	end
	return string.format("updating:%s butterflies:%d/%d", tostring(_updating), numbutterflies, _maxbutterflies)
end

end)
