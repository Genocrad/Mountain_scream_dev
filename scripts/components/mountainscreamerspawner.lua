--------------------------------------------------------------------------
--[[ MountainScreamerSpawner ]]
--[[ Night stalk encounter: chance on cave-night for one MS-overworld player (IsInstInMSOverWorld); max one boss per night.
     Spawn gate stays OverWorld-only; chase/fall pursuit is handled on the screamer prefab with soft level checks. ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "MountainScreamerSpawner should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

self.inst = inst

local _activeplayers = {}
local _screamer = nil
local _rolled_this_night = false
local _worldstate = TheWorld.state

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function IsValidStalkTarget(player)
	return player ~= nil
		and player:IsValid()
		and player:HasTag("player")
		and not player:HasTag("playerghost")
		and IsInstInMSOverWorld(player)
end

local function GetOverworldPlayers()
	local list = {}
	for i, v in ipairs(_activeplayers) do
		if IsValidStalkTarget(v) then
			table.insert(list, v)
		end
	end
	return list
end

local function ClearScreamer()
	_screamer = nil
end

local function OnScreamerRemoved(screamer)
	if _screamer == screamer then
		ClearScreamer()
	end
end

local function GetSpawnOffset(player)
	local x, y, z = player.Transform:GetWorldPosition()
	local min = TUNING.MOUNTAIN_SCREAMER.STALK_SPAWN_DIST_MIN
	local max = TUNING.MOUNTAIN_SCREAMER.STALK_SPAWN_DIST_MAX
	local dist = GetRandomMinMax(min, max)
	local offset = FindWalkableOffset(
		Vector3(x, 0, z),
		math.random() * TWOPI,
		dist,
		12,
		false,
		true
	)
	if offset ~= nil then
		return x + offset.x, z + offset.z
	end
	-- fallback: raw ring if ground query fails (mountain tiles)
	local theta = math.random() * TWOPI
	return x + dist * math.cos(theta), z + dist * math.sin(theta)
end

local function HasLivingScreamer()
	if _screamer ~= nil and _screamer:IsValid() and not (_screamer.components.health ~= nil and _screamer.components.health:IsDead()) then
		return true
	end
	-- block if any living screamer already exists near players (debug / leftover)
	for _, player in ipairs(AllPlayers) do
		if player:IsValid() then
			local x, y, z = player.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, y, z, 80, { "mountain_screamer" })
			for _, e in ipairs(ents) do
				if e:IsValid() and e.components.health ~= nil and not e.components.health:IsDead() then
					return true
				end
			end
		end
	end
	return false
end

local function TrySpawnStalk()
	if _rolled_this_night then
		return
	end
	_rolled_this_night = true

	if HasLivingScreamer() then
		return
	end

	if math.random() > TUNING.MOUNTAIN_SCREAMER.STALK_SPAWN_CHANCE then
		return
	end

	local candidates = GetOverworldPlayers()
	if #candidates == 0 then
		return
	end

	local player = candidates[math.random(#candidates)]
	local sx, sz = GetSpawnOffset(player)
	local screamer = SpawnPrefab("mountain_screamer")
	if screamer == nil then
		return
	end

	screamer.Transform:SetPosition(sx, 0, sz)
	screamer.persists = false
	_screamer = screamer
	inst:ListenForEvent("onremove", OnScreamerRemoved, screamer)
	if screamer.StartStalk ~= nil then
		screamer:StartStalk(player)
	end
end

local function GetStalkSpawnDelay()
	return GetRandomMinMax(
		TUNING.MOUNTAIN_SCREAMER.STALK_SPAWN_DELAY_MIN,
		TUNING.MOUNTAIN_SCREAMER.STALK_SPAWN_DELAY_MAX
	)
end

local function OnIsCaveNight(src, iscavenight)
	if iscavenight then
		inst:DoTaskInTime(GetStalkSpawnDelay(), TrySpawnStalk)
	else
		_rolled_this_night = false
		-- 实体自身 WatchWorldState 也会 leave；此处兜底：未在交战则赶走
		if _screamer ~= nil and _screamer:IsValid() then
			local target = _screamer.components.combat ~= nil and _screamer.components.combat.target or nil
			local fighting = target ~= nil
				and target:IsValid()
				and not target:HasTag("playerghost")
				and (target.components.health == nil or not target.components.health:IsDead())
			if not fighting then
				_screamer:PushEvent("ms_screamer_leave")
			end
		end
	end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerJoined(src, player)
	for i, v in ipairs(_activeplayers) do
		if v == player then
			return
		end
	end
	table.insert(_activeplayers, player)
end

local function OnPlayerLeft(src, player)
	for i, v in ipairs(_activeplayers) do
		if v == player then
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

inst:WatchWorldState("iscavenight", OnIsCaveNight)
inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)

if _worldstate.iscavenight then
	inst:DoTaskInTime(GetStalkSpawnDelay(), TrySpawnStalk)
end

--------------------------------------------------------------------------
--[[ Public ]]
--------------------------------------------------------------------------

function self:GetScreamer()
	return _screamer
end

function self:GetDebugString()
	return string.format(
		"rolled:%s screamer:%s players:%d",
		tostring(_rolled_this_night),
		tostring(_screamer ~= nil and _screamer:IsValid()),
		#GetOverworldPlayers()
	)
end

-- debug: force stalk near a player
function self:DebugSpawnNear(player)
	player = player or AllPlayers[1]
	if not IsValidStalkTarget(player) then
		return nil
	end
	if _screamer ~= nil and _screamer:IsValid() then
		_screamer:Remove()
		ClearScreamer()
	end
	_rolled_this_night = true
	local sx, sz = GetSpawnOffset(player)
	local screamer = SpawnPrefab("mountain_screamer")
	if screamer == nil then
		return nil
	end
	screamer.Transform:SetPosition(sx, 0, sz)
	screamer.persists = false
	_screamer = screamer
	inst:ListenForEvent("onremove", OnScreamerRemoved, screamer)
	if screamer.StartStalk ~= nil then
		screamer:StartStalk(player)
	end
	return screamer
end

end)
