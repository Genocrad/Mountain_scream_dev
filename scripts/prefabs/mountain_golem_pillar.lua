local assets =
{
	Asset("ANIM", "anim/mountain_golem.zip"),
	Asset("MINIMAP_IMAGE", "mountain_golem_pillar"),
}

local prefabs =
{
	"mountain_golem",
}

local SUMMON_DAMAGE_MUST_TAGS = { "_combat" }
local SUMMON_DAMAGE_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack", "FX", "DECOR", "playerghost" }

local function OnEntityWake_Pathfinding(inst)
	if inst._pfx == nil and inst:GetCurrentPlatform() == nil then
		local _
		inst._pfx, _, inst._pfz = inst.Transform:GetWorldPosition()
		for dx = -1, 1 do
			for dz = -1, 1 do
				TheWorld.Pathfinder:AddWall(inst._pfx + dx, 0, inst._pfz + dz)
			end
		end
	end
end

local function OnRemoveEntity_Pathfinding(inst)
	if inst._pfx then
		for dx = -1, 1 do
			for dz = -1, 1 do
				TheWorld.Pathfinder:RemoveWall(inst._pfx + dx, 0, inst._pfz + dz)
			end
		end
		inst._pfx, inst._pfz = nil, nil
	end
end

local function ActivateMountainGolem(inst)
	inst = ReplacePrefab(inst, "mountain_golem")
	inst.sg:GoToState("activate")
	return inst
end

local function OnHammerFinished(inst, worker)
	ActivateMountainGolem(inst)
end

local function DoSummonDamage(inst)
	local cfg = TUNING.MOUNTAIN_GOLEM.PILLAR_SUMMON
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, cfg.RADIUS, SUMMON_DAMAGE_MUST_TAGS, SUMMON_DAMAGE_CANT_TAGS)
	for _, v in ipairs(ents) do
		if v ~= inst and v:IsValid() and not v:IsInLimbo()
			and not (v.components.health ~= nil and v.components.health:IsDead())
			and v.components.combat ~= nil
		then
			local damage = v:HasTag("player") and cfg.PLAYER_DAMAGE or cfg.DAMAGE
			v.components.combat:GetAttacked(inst, damage)
		end
	end
end

local function FinishSummon(inst)
	inst:RemoveEventCallback("animover", inst._OnSummonAnimOver)
	inst._OnSummonAnimOver = nil
	inst.AnimState:PlayAnimation("pillar_idle", true)
	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkable(true)
	end
end

local function OnSummonAnimOver(inst)
	if not inst.AnimState:AnimDone() then
		return
	end

	if inst.AnimState:IsCurrentAnimation("construction_small_place") then
		inst.AnimState:PlayAnimation("construction_small_to_med")
		inst.SoundEmitter:PlaySound("dontstarve/common/together/rocks/move", nil, 0.5)
	elseif inst.AnimState:IsCurrentAnimation("construction_small_to_med") then
		inst.AnimState:PlayAnimation("construction_med_to_large")
		inst.SoundEmitter:PlaySound("dontstarve/common/together/rocks/move", nil, 0.5)
	elseif inst.AnimState:IsCurrentAnimation("construction_med_to_large") then
		FinishSummon(inst)
	end
end

local function StartSummon(inst)
	if inst.components.workable ~= nil then
		inst.components.workable:SetWorkable(false)
	end

	if inst:IsAsleep() then
		DoSummonDamage(inst)
		inst.AnimState:PlayAnimation("pillar_idle", true)
		if inst.components.workable ~= nil then
			inst.components.workable:SetWorkable(true)
		end
		return
	end

	inst._OnSummonAnimOver = OnSummonAnimOver
	inst:ListenForEvent("animover", OnSummonAnimOver)
	inst.AnimState:PlayAnimation("construction_small_place")
	-- 魔像重砸音效：比普通 rocks/place 更有冲击感
	inst.SoundEmitter:PlaySound("daywalker/action/attack_slam_down")
	inst.SoundEmitter:PlaySound("daywalker/pillar/hit")
	DoSummonDamage(inst)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	inst.MiniMapEntity:SetIcon("mountain_golem_pillar.tex")

	inst.AnimState:SetBank("mountain_golem")
	inst.AnimState:SetBuild("mountain_golem")
	inst.AnimState:PlayAnimation("pillar_idle")

	inst:SetDeploySmartRadius(1.5)
	inst:SetPhysicsRadiusOverride(1.3)
	MakeObstaclePhysics(inst, inst.physicsradiusoverride)
	inst.Physics:SetDontRemoveOnSleep(true)

	inst:AddTag("nomagic")
	inst:AddTag("nohighlight")
	inst:AddTag("mountain_golem_pillar")

	inst.OnEntityWake = OnEntityWake_Pathfinding

	inst.OnRemoveEntity = function(inst)
		OnRemoveEntity_Pathfinding(inst)
		if TheWorld.ismastersim then
			local ctrl = TheWorld.components.mountain_golem_platformctrl
			if ctrl ~= nil then
				ctrl:NotifySummonRemoved()
			end
		end
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(TUNING.MOUNTAIN_GOLEM.PILLAR_HAMMER_WORK)
	inst.components.workable:SetOnFinishCallback(OnHammerFinished)

	inst.ActivateMountainGolem = ActivateMountainGolem
	inst.StartSummon = StartSummon

	local ctrl = TheWorld.components.mountain_golem_platformctrl
	if ctrl ~= nil then
		ctrl:NotifySummonSpawned()
	end

	return inst
end

return Prefab("mountain_golem_pillar", fn, assets, prefabs)
