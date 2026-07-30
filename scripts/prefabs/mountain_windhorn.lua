local assets =
{
	Asset("ANIM", "anim/mountain_windhorn.zip"),
}

local prefabs =
{
	"mountain_tornado",
}

local HORN_SOUND = "dontstarve/common/horn_beefalo"

local function NoHoles(pt)
	return not TheWorld.Map:IsPointNearHole(pt)
end

-- 绕玩家一圈均匀分布的方向（默认 6 向，间隔 60°）
local function GetDirection(musician, index, count)
	local base = musician.Transform:GetRotation() * DEGREES
	if count <= 1 then
		return base
	end
	return base + (index - 1) * TWOPI / count
end

local function GetPointFromOrigin(x, z, theta, dist)
	local offset = FindWalkableOffset(Vector3(x, 0, z), theta, dist, 8, false, true, NoHoles)
	if offset == nil then
		offset = Vector3(dist * math.cos(theta), 0, -dist * math.sin(theta))
	end
	return x + offset.x, z + offset.z
end

local function SpawnTornado(musician, spawn_x, spawn_z, target_x, target_z)
	local tornado = SpawnPrefab("mountain_tornado")
	if tornado == nil then
		return
	end

	tornado.WINDSTAFF_CASTER = musician
	tornado.WINDSTAFF_CASTER_ISPLAYER = musician:HasTag("player")
	tornado.Transform:SetPosition(spawn_x, 0, spawn_z)
	tornado.components.knownlocations:RememberLocation("target", Vector3(target_x, 0, target_z))

	if tornado.WINDSTAFF_CASTER_ISPLAYER then
		tornado.overridepkname = musician:GetDisplayName()
		tornado.overridepkpet = true
	end
end

local function OnPlayWindhorn(inst, musician)
	if musician == nil or not musician:IsValid() then
		return
	end

	local px, _, pz = musician.Transform:GetWorldPosition()
	local count = TUNING.MOUNTAIN_WINDHORN.TORNADO_COUNT
	local spawn_dist = TUNING.MOUNTAIN_WINDHORN.TORNADO_SPAWN_DIST
	local travel_dist = TUNING.MOUNTAIN_WINDHORN.TORNADO_TRAVEL_DIST
	for i = 1, count do
		local theta = GetDirection(musician, i, count)
		local spawn_x, spawn_z = GetPointFromOrigin(px, pz, theta, spawn_dist)
		local target_x, target_z = GetPointFromOrigin(px, pz, theta, travel_dist)
		SpawnTornado(musician, spawn_x, spawn_z, target_x, target_z)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst:AddTag("horn")
	inst:AddTag("tool")

	inst.AnimState:SetBank("mountain_windhorn")
	inst.AnimState:SetBuild("mountain_windhorn")
	inst.AnimState:PlayAnimation("idle")

	MakeInventoryFloatable(inst, "med", 0.25)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_windhorn"
	
	inst:AddComponent("instrument")
	inst.components.instrument:SetRange(TUNING.HORN_RANGE)
	inst.components.instrument:SetOnPlayedFn(OnPlayWindhorn)
	inst.components.instrument:SetAssetOverrides("mountain_windhorn", "horn01", HORN_SOUND)

	inst:AddComponent("tool")
	inst.components.tool:SetAction(ACTIONS.PLAY)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.MOUNTAIN_WINDHORN.USES)
	inst.components.finiteuses:SetUses(TUNING.MOUNTAIN_WINDHORN.USES)
	inst.components.finiteuses:SetOnFinished(inst.Remove)
	inst.components.finiteuses:SetConsumption(ACTIONS.PLAY, 1)

	MakeHauntableLaunch(inst)

	return inst
end

return Prefab("mountain_windhorn", fn, assets, prefabs)
