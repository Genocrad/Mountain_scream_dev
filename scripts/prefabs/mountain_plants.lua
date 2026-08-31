local assets =
{
	Asset("ANIM", "anim/mountain_plants.zip"),
}

local FLOWER_SANITY = 10
local FLOWER_NAMES = { "flower_1", "flower_2", "flower_3", "flower_4", "flower_5", "flower_6", "flower_7" }

local function OnPickedFlower(inst, picker)
	if picker ~= nil and picker.components.sanity ~= nil then
		picker.components.sanity:DoDelta(FLOWER_SANITY)
	end
end

local function SetFlowerType(inst, name)
	if inst.animname == nil or (name ~= nil and inst.animname ~= name) then
		inst.animname = name or FLOWER_NAMES[math.random(#FLOWER_NAMES)]
		inst.AnimState:PlayAnimation(inst.animname)
	end
end

local function FlowerOnSave(inst, data)
	data.anim = inst.animname
end

local function FlowerOnLoad(inst, data)
	SetFlowerType(inst, data ~= nil and data.anim or nil)
end

local function MakePlant(def)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank("mountain_plants")
		inst.AnimState:SetBuild("mountain_plants")
		inst.AnimState:PlayAnimation(def.anim)
		inst.AnimState:SetRayTestOnBB(true)

		inst:AddTag("plant")

		if def.nameoverride ~= nil then
			inst:SetPrefabNameOverride(def.nameoverride)
		end

		if def.tags ~= nil then
			for _, tag in ipairs(def.tags) do
				inst:AddTag(tag)
			end
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

		inst:AddComponent("inspectable")

		inst:AddComponent("pickable")
		inst.components.pickable.picksound = def.picksound or "dontstarve/wilson/pickup_plants"
		inst.components.pickable:SetUp(def.product, nil, def.num or 1)
		inst.components.pickable.remove_when_picked = true
		inst.components.pickable.quickpick = def.quickpick == true
		inst.components.pickable.onpickedfn = def.onpickedfn

		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		MakeHauntableIgnite(inst)

		return inst
	end

	return Prefab(def.name, fn, assets, { def.product })
end

local function MakeFlower()
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank("mountain_plants")
		inst.AnimState:SetBuild("mountain_plants")
		inst.AnimState:SetRayTestOnBB(true)
		inst.scrapbook_anim = "flower_1"

		inst:AddTag("plant")
		inst:AddTag("flower")
		inst:AddTag("cattoy")

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

		inst:AddComponent("pickable")
		inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
		inst.components.pickable:SetUp("petals", nil, 1)
		inst.components.pickable.remove_when_picked = true
		inst.components.pickable.quickpick = true
		inst.components.pickable.onpickedfn = OnPickedFlower

		MakeSmallBurnable(inst)
		MakeSmallPropagator(inst)
		MakeHauntableIgnite(inst)

		-- Fresh spawn: pick a variant now. World load: wait for OnLoad.
		if not POPULATING then
			SetFlowerType(inst)
		end

		inst.OnSave = FlowerOnSave
		inst.OnLoad = FlowerOnLoad

		return inst
	end

	return Prefab("mountain_plants_flower", fn, assets, { "petals" })
end

local PLANTS =
{
	{
		name = "mountain_plants_bush_1",
		anim = "bush_1",
		product = "twigs",
		num = 1,
		picksound = "dontstarve/wilson/harvest_sticks",
		nameoverride = "mountain_plants_bush",
	},
	{
		name = "mountain_plants_bush_2",
		anim = "bush_2",
		product = "twigs",
		num = 2,
		picksound = "dontstarve/wilson/harvest_sticks",
		nameoverride = "mountain_plants_bush",
	},
	{
		name = "mountain_plants_bush_3",
		anim = "bush_3",
		product = "twigs",
		num = 4,
		picksound = "dontstarve/wilson/harvest_sticks",
		nameoverride = "mountain_plants_bush",
	},
	{
		name = "mountain_plants_tree",
		anim = "tree",
		product = "log",
		num = 1,
		picksound = "dontstarve/wilson/harvest_sticks",
	},
	{
		name = "mountain_plants_grass",
		anim = "grass",
		product = "cutgrass",
		num = 1,
		picksound = "dontstarve/wilson/pickup_reeds",
		quickpick = true,
	},
	{
		name = "mountain_plants_branches",
		anim = "branches",
		product = "twigs",
		num = 1,
		picksound = "dontstarve/wilson/harvest_sticks",
	},
	{
		name = "mountain_plants_pomegranate",
		anim = "pomegranate",
		product = "pomegranate",
		num = 1,
		quickpick = true,
	},
}

local prefabs = { MakeFlower() }
for _, def in ipairs(PLANTS) do
	table.insert(prefabs, MakePlant(def))
end

return unpack(prefabs)
