local assets =
{
	Asset("ANIM", "anim/mountain_aluminum_axe.zip"),
}

local prefabs =
{
	"mountain_aluminum_axe_projectile",
	"reticulelong",
	"reticulelongping",
}

local projectile_prefabs =
{
	"mountain_aluminum_axe",
}

------------------------------------------------------------------------------------------------------------------------

local function ReticuleTargetFn()
	return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
	if mousepos ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		local dx = mousepos.x - x
		local dz = mousepos.z - z
		local l = dx * dx + dz * dz
		if l <= 0 then
			return inst.components.reticule.targetpos
		end
		l = 6.5 / math.sqrt(l)
		return Vector3(x + dx * l, 0, z + dz * l)
	end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
	local x, y, z = inst.Transform:GetWorldPosition()
	reticule.Transform:SetPosition(x, 0, z)
	local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
	if ease and dt ~= nil then
		local rot0 = reticule.Transform:GetRotation()
		local drot = rot - rot0
		rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
	end
	reticule.Transform:SetRotation(rot)
end

------------------------------------------------------------------------------------------------------------------------

local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_object", "mountain_aluminum_axe", "swap_aluminum_axe")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
end

local function on_uses_finished(inst)
	local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem:GetGrandOwner() or nil
	if owner ~= nil then
		owner:PushEvent("toolbroke", { tool = inst })
	end
	inst:Remove()
end

------------------------------------------------------------------------------------------------------------------------

local function HarvestAppleTree(doer, target)
	if target ~= nil and target:IsValid() and target.HarvestApples ~= nil then
		return target:HarvestApples(doer)
	end
	return false
end

local function ChopTreesAt(doer, x, y, z)
	local efficiency = TUNING.MOUNTAIN_ALUMINUM_AXE.CHOP_EFFICIENCY
	local radius = TUNING.MOUNTAIN_ALUMINUM_AXE.CHOP_RADIUS
	local ents = TheSim:FindEntities(x, y, z, radius, nil, { "INLIMBO", "NOCLICK", "FX", "player", "companion" })
	for _, v in ipairs(ents) do
		if v.components.workable ~= nil
				and v.components.workable:CanBeWorked()
				and v.components.workable:GetWorkAction() == ACTIONS.CHOP then
			v.components.workable:WorkedBy(doer, efficiency)
		end
	end
end

local function PlayChopSound(doer, target)
	if target ~= nil and target.SoundEmitter ~= nil
			and not (doer ~= nil and doer:HasTag("playerghost")) then
		target.SoundEmitter:PlaySound(
			doer ~= nil and doer:HasTag("beaver") and
			"dontstarve/characters/woodie/beaver_chop_tree" or
			"dontstarve/wilson/use_axe_tree"
		)
	end
end

local function ChopMSBush(doer, target)
	if target == nil or not target:IsValid() or target.components.workable == nil then
		return
	end

	PlayChopSound(doer, target)
	target.components.workable:SetWorkable(true)
	target.components.workable:WorkedBy(doer, 1)

	if target:IsValid() and target.components.workable ~= nil then
		target.components.workable:SetWorkable(false)
	end
end


local function ReturnItemToWorld(proj, thrower, do_mine_at, keep_height)
	local item = proj.item
	proj.item = nil

	if item == nil or not item:IsValid() then
		return
	end

	local x, y, z = proj.Transform:GetWorldPosition()
	if not keep_height then
		y = 0
	end
	item.Transform:SetPosition(x, y, z)
  
	item:ReturnToScene()
  
  if y~=0 then
    item.Physics:SetCollisionMask(
      COLLISION.WORLD,
      COLLISION.MS_CLOUDS
    )
    -- So it does not fall into the void.
    LaunchAt(item, item, thrower, math.max(2, 5 - y), math.max(y,3.5), 1)
  end
	if do_mine_at and thrower ~= nil and thrower:IsValid() then
		ChopTreesAt(thrower, x, 0, z)
	end

	if item.components.finiteuses ~= nil then
		item.components.finiteuses:Use(1)
	end
end

local function DropAxe(proj, thrower, target)
	-- 右键 AOE 投掷落地：范围砍树
	ReturnItemToWorld(proj, thrower, true)
	if proj:IsValid() then
		proj:Remove()
	end
end

local function GetThrowDest(target)
	local tx, ty, tz = target.Transform:GetWorldPosition()
	local hit_y = target.throw_hit_height
	if hit_y == nil then
		if target:HasTag("ms_apple_tree") then
			hit_y = ty + TUNING.MOUNTAIN_ALUMINUM_AXE.APPLE_TREE_THROW_OFFSET
		else
			hit_y = ty
		end
	end
	return Vector3(tx, hit_y, tz)
end

-- 左键定向投掷命中：结果期苹果树打落苹果；灌木砍箱
local function OnHit(proj, thrower, target)
	if target ~= nil and target:IsValid() then
		if target:HasTag("ms_apple_harvestable") then
			HarvestAppleTree(thrower, target)
		elseif target:HasTag("mountain_throw_target") then
			ChopMSBush(thrower, target)
		end
	end
	ReturnItemToWorld(proj, thrower, false, true)
	if proj:IsValid() then
		proj:Remove()
	end
end

local function OnMiss(proj, thrower)
	ReturnItemToWorld(proj, thrower, false, true)
	if proj:IsValid() then
		proj:Remove()
	end
end

local function SpellFn(inst, doer, pos)
	local proj = SpawnPrefab("mountain_aluminum_axe_projectile")
	if proj == nil then
		return false
	end

	local x, y, z = doer.Transform:GetWorldPosition()
	proj.Transform:SetPosition(x, y, z)

	if inst.components.inventoryitem ~= nil and inst.components.inventoryitem:IsHeld() then
		inst.components.inventoryitem:RemoveFromOwner(true)
	end
	inst:RemoveFromScene()

	proj.item = inst
	proj.components.aimedprojectile.weapon = inst
	proj.components.aimedprojectile.damage = TUNING.AXE_DAMAGE
		* (doer.components.combat ~= nil and doer.components.combat.damagemultiplier or 1)
	proj.components.aimedprojectile:Throw(doer, pos)

	return true
end

local function ThrowAtBush(inst, doer, target)
	if doer == nil or target == nil or not target:IsValid() then
		return false
	end

	local ok = target:HasTag("ms_apple_harvestable")
		or (target:HasTag("mountain_throw_target") and not target:HasTag("ms_apple_tree"))
	if not ok then
		return false
	end

	local proj = SpawnPrefab("mountain_aluminum_axe_projectile")
	if proj == nil then
		return false
	end

	local x, y, z = doer.Transform:GetWorldPosition()
	proj.Transform:SetPosition(x, y, z)

	if inst.components.inventoryitem ~= nil and inst.components.inventoryitem:IsHeld() then
		inst.components.inventoryitem:RemoveFromOwner(true)
	end
	inst:RemoveFromScene()

	local dest = GetThrowDest(target)

	proj.item = inst
	proj.components.aimedprojectile.weapon = inst
	proj.components.aimedprojectile.damage = 0
	proj.components.aimedprojectile:SetOnHitFn(OnHit)
	proj.components.aimedprojectile:SetOnMissFn(OnMiss)
	proj.components.aimedprojectile:SetHitWorkAction(nil)
	proj.components.aimedprojectile:Throw(doer, dest, { fly_3d = true, target = target })

	return true
end

------------------------------------------------------------------------------------------------------------------------

local function axe_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("mountain_aluminum_axe")
	inst.AnimState:SetBuild("mountain_aluminum_axe")
	inst.AnimState:PlayAnimation("idle")

	inst:AddTag("sharp")
	inst:AddTag("throw_line")
	inst:AddTag("nopunch")
	inst:AddTag("weapon")
	inst:AddTag("ms_aluminum_axe")

	local floater_swap_data = { sym_build = "mountain_aluminum_axe", sym_name = "swap_aluminum_axe" }
	MakeInventoryFloatable(inst, "small", 0.05, { 1.2, 0.75, 1.2 }, true, -11, floater_swap_data)

	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAlwaysValid(true)
	inst.components.aoetargeting:SetAllowRiding(true)
	inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
	inst.components.aoetargeting.reticule.pingprefab = "reticulelongping"
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
	inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
	inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
	inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	local uses = TUNING.MOUNTAIN_ALUMINUM_AXE.USES

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(uses)
	inst.components.finiteuses:SetUses(uses)
	inst.components.finiteuses:SetOnFinished(on_uses_finished)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(TUNING.AXE_DAMAGE)

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = MS_ITEMS_ATLAS
	inst.components.inventoryitem.imagename = "mountain_aluminum_axe"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(SpellFn)

	inst.ThrowAtBush = ThrowAtBush

	MakeHauntableLaunch(inst)

	return inst
end

------------------------------------------------------------------------------------------------------------------------

local function projectile_fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)

	inst.AnimState:SetBank("mountain_aluminum_axe")
	inst.AnimState:SetBuild("mountain_aluminum_axe")
	inst.AnimState:PlayAnimation("spin_loop", true)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("projectile")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst.item = nil

	inst:AddComponent("aimedprojectile")
	inst.components.aimedprojectile:SetSpeed(TUNING.MOUNTAIN_ALUMINUM_AXE.THROW_SPEED)
	inst.components.aimedprojectile:SetRange(TUNING.MOUNTAIN_ALUMINUM_AXE.THROW_RANGE)
	inst.components.aimedprojectile:SetHitDist(TUNING.MOUNTAIN_ALUMINUM_AXE.HIT_DIST)
	inst.components.aimedprojectile:SetOnHitFn(DropAxe)
	inst.components.aimedprojectile:SetOnMissFn(DropAxe)
	inst.components.aimedprojectile:SetHitWorkAction(ACTIONS.CHOP)
	inst.components.aimedprojectile:SetLaunchOffset(Vector3(0.5, 0.75, 0))

	inst:ListenForEvent("onremove", function()
		ReturnItemToWorld(inst, nil)
	end)

	return inst
end

return Prefab("mountain_aluminum_axe", axe_fn, assets, prefabs),
	Prefab("mountain_aluminum_axe_projectile", projectile_fn, assets, projectile_prefabs)
