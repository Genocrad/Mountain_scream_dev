
local assets =
{
	Asset("ANIM", "anim/ms_snowpile.zip"),
}

local prefabs =
{
	"mountain_snowball",
	"ice",
}


local STAGE =
{
	[9] =
	{
		idle = "idle_9",
		next = "8",
		radius = 1.5,
	},
	[8] =
	{
		idle = "idle_8",
		next = "7",
		radius = 1.5,
	},
  [7] =
	{
		idle = "idle_7",
		next = "6",
		radius = 1.5,
	},
  [6] =
	{
		idle = "idle_6",
		next = "5",
		radius = 1.5,
	},
  [5] =
	{
		idle = "idle_5",
		dig = "idle_5",
		next = "4",
		radius = 1.5,
	},
  [4] =
	{
		idle = "idle_4",
		next = "3",
		radius = 1.5,
	},
  [3] =
	{
		idle = "idle_3",
		next = "2",
		radius = 1.5,
	},
  [2] =
	{
		idle = "idle_2",
		next = "1",
		radius = 1.5,
	},
  [1] =
	{
		idle = "idle_1",
		next = 0,
		radius = 1.5,
	},
  [0] =
	{
		idle = "idle_1",
		next = nil,
		radius = 0,
	}
}

SetSharedLootTable("mountain_snowpile",
{
	{ "mountain_snowball", 0.2 },
	{ "rocks", 0.05 },
	{ "ice", 0.05 },
})

local FALL_DAMAGE_RADIUS = 1.5
local FALL_DAMAGE_TAGS = { "player" }
local FALL_DAMAGE_CANT_TAGS = { "INLIMBO", "playerghost", "FX" }

------------------------------------------------------------------------------------------------------------------------

local function SpawnFxAtPoint(inst, x, y, z)
  local snow_fx = SpawnPrefab("ms_snowpile_fx")
  if x and y and z then
    snow_fx.Transform:SetPosition(x,y,z)
  else
    x,y,z = inst.Transform:GetWorldPosition()
    snow_fx.Transform:SetPosition(x,y,z)
  end
end

local function GetStageConfig(inst)
	return STAGE[inst.pile_stage]
end


local function BeginTransition(inst)
  inst:Show()
	local cfg = GetStageConfig(inst)
	if cfg == nil then
		return
	end
  if inst.pile_stage > 0 then
    inst.components.workable:SetWorkLeft(inst.pile_stage)
  end
  inst.Physics:SetCapsule(cfg.radius, 2)
	inst.AnimState:PlayAnimation(cfg.idle)
end

local COLLAPSIBLE_WORK_ACTIONS =
{
	CHOP = true,
	DIG = true,
	HAMMER = true,
	MINE = true,
}
local COLLAPSIBLE_TAGS = { "_combat", "pickable", "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
	table.insert(COLLAPSIBLE_TAGS, k.."_workable")
end
local NON_COLLAPSIBLE_TAGS = { "FX", --[["NOCLICK",]] "DECOR", "INLIMBO", "snowpile" }
local AOE_RADIUS = 3
local PHYSICS_PADDING = 3

local function KeepTargetFn()
	return false
end

local function BreakAndAbsorb(inst)
  inst:Show()
  local combat = inst.components.combat
  
  local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, AOE_RADIUS + PHYSICS_PADDING, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
	for i, v in ipairs(ents) do
		if v:IsValid() and not v:IsInLimbo() and not (v.components.health and v.components.health:IsDead()) then
			local r = AOE_RADIUS + v:GetPhysicsRadius(0.5)
			local x1, y1, z1 = v.Transform:GetWorldPosition()
			if distsq(x, z, x1, z1) < r * r then
				local isworkable = false
				if v.components.workable then
					local work_action = v.components.workable:GetWorkAction()
					--V2C: nil action for NPC_workable (e.g. campfires)
					isworkable =
						(   work_action == nil and v:HasTag("NPC_workable") ) or
						(   work_action and
							v.components.workable:CanBeWorked() and
							COLLAPSIBLE_WORK_ACTIONS[work_action.id] and
							(   work_action ~= ACTIONS.DIG or
								not (v.components.spawner or v.components.childspawner)
							)
						)
				end
				if isworkable then
					v.components.workable:WorkedBy(inst, 3)
					if inst.formpile and v:IsValid() and v:HasTag("stump") then
						v:Remove()
					end
				elseif v.components.pickable and v.components.pickable:CanBePicked() and not v:HasTag("intense") then
					v.components.pickable:Pick(inst)
				elseif combat:CanTarget(v) then
						combat:DoAttack(v)
        end
				end
			end
		end

	local totoss = TheSim:FindEntities(x, 0, z, AOE_RADIUS + PHYSICS_PADDING, { "_inventoryitem" }, { "locomotor", "INLIMBO" })
	for i, v in ipairs(totoss) do
		local rsq = AOE_RADIUS + v:GetPhysicsRadius(.5)
		rsq = rsq * rsq
		local x1, y1, z1 = v.Transform:GetWorldPosition()
		local dx, dz = x1 - x, z1 - z
		local dsq = dx * dx + dz * dz
		if dsq < rsq and y1 < 0.2 then
      if math.random()> 0.5 then
        DeactivateInventoryItemBeforeLaunch(v)
        if not v.components.inventoryitem.nobounce and v.Physics and v.Physics:IsActive() then
          local angle
          if dsq > 0 then
            local dist = math.sqrt(dsq)
            angle = math.atan2(dz / dist, dx / dist) + (math.random() * 20 - 10) * DEGREES
          else
            angle = PI2 * math.random()
          end
          local sina, cosa = math.sin(angle), math.cos(angle)
          local speed = 2.25 - dsq / rsq + math.random()
          v.Physics:Teleport(x1, .1, z1)
          v.Physics:SetVel(cosa * speed, speed * 2 + math.random() * 2, sina * speed)
        end
      else
        if v.components.inventoryitem.canbepickedup and v.components.inventoryitem.cangoincontainer then
          inst.components.inventory:GiveItem(v)
        end
      end
		end
	end
end

local function OnDig(inst, worker)
  inst.pile_stage = inst.pile_stage - 1
  inst:BeginTransition()
  inst:SpawnFxAtPoint()
	if worker ~= nil and not worker:HasTag("playerghost") then
		inst.SoundEmitter:PlaySound("dontstarve/creatures/together/lavae/sizzle_snow")
	end
  if inst.components.inventory then
    local item = inst.components.inventory:GetFirstItemInAnySlot()
    if item then
      inst.components.inventory:DropItem(item, false)
    end
    local pt = inst:GetPosition()
    inst.components.lootdropper:DropLoot(pt)
  end
end

local function OnDigFinish(inst)
	inst.components.inventory:DropEverything(true)
  inst:Remove()
end

local function OnSave(inst, data)
	data.pile_stage = inst.pile_stage
  data.workleft = inst.components.workable.workleft
end

local function OnLoad(inst, data)
	if data ~= nil and data.pile_stage ~= nil and STAGE[data.pile_stage] ~= nil then
    inst.pile_stage = data.pile_stage
		inst:BeginTransition()
	end
  if data and data.workleft then 
    inst.components.workable.workleft = data.workleft 
  end
end

local function OnLoadPostPass(inst)
  inst:BeginTransition()
end

------------------------------------------------------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()

	MakeObstaclePhysics(inst, STAGE[1].radius)

	inst.AnimState:SetBank("ms_snowpile")
	inst.AnimState:SetBuild("ms_snowpile")
  inst.AnimState:PlayAnimation("idle_1")
	
	inst.MiniMapEntity:SetIcon("mountain_snowpile.tex")

	inst:AddTag("snowpile")
	inst:AddTag("structure")
	-- 原版仆从只挖掘带 stump/grave/farm_debris 的目标，加 grave 让其主动铲雪堆
	inst:AddTag("grave")

  inst:Hide()
  
	inst.scrapbook_anim = "idle_full"

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.pile_stage = 1
  
	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.DIG)
	inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnWorkCallback(OnDig)
	inst.components.workable:SetOnFinishCallback(OnDigFinish)
	inst.components.workable:SetWorkable(true)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("mountain_snowpile")
  
  inst:AddComponent("inventory")
  
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.MOUNTAIN_SNOWPILE.FALL_DAMAGE)
	inst.components.combat:SetRange(AOE_RADIUS)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
  
	MakeHauntableWork(inst)
  
  inst.SpawnFxAtPoint = SpawnFxAtPoint
  inst.BreakAndAbsorb = BreakAndAbsorb
  inst.BeginTransition = BeginTransition
	inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	inst.OnLoadPostPass = OnLoadPostPass
	return inst
end

return Prefab("avalanche_snowpile", fn, assets, prefabs)
