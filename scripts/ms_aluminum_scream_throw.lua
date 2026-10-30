-- 铝器对尖啸者：右键飞向面部（3D），用于打断尖啸；与水平点地投掷区分

local FACE_STIMULI = "ms_aluminum_face_throw"

local function GetProjectilePrefab(inst)
	if inst:HasTag("ms_aluminum_pickaxe") then
		return "mountain_aluminum_pickaxe_projectile"
	elseif inst:HasTag("ms_aluminum_axe") then
		return "mountain_aluminum_axe_projectile"
	end
	return "mountain_aluminum_dagger_projectile"
end

local function GetThrowDamage(inst, doer)
	local base
	if inst:HasTag("ms_aluminum_pickaxe") then
		base = TUNING.PICK_DAMAGE
	elseif inst:HasTag("ms_aluminum_axe") then
		base = TUNING.AXE_DAMAGE
	else
		base = TUNING.MOUNTAIN_ALUMINUM_DAGGER.THROW_DAMAGE
	end
	local mult = doer.components.combat ~= nil and doer.components.combat.damagemultiplier or 1
	return base * mult
end

local function ThrowAtScreamerFace(inst, doer, target)
	if doer == nil or target == nil or not target:IsValid() then
		return false
	end
	if not target:HasTag("mountain_screamer") then
		return false
	end
	if target.components.health ~= nil and target.components.health:IsDead() then
		return false
	end

	local proj = SpawnPrefab(GetProjectilePrefab(inst))
	if proj == nil then
		return false
	end

	local x, y, z = doer.Transform:GetWorldPosition()
	proj.Transform:SetPosition(x, y, z)

	if inst.components.inventoryitem ~= nil and inst.components.inventoryitem:IsHeld() then
		inst.components.inventoryitem:RemoveFromOwner(true)
	end
	inst:RemoveFromScene()

	local tx, ty, tz = target.Transform:GetWorldPosition()
	local face_y = TUNING.MOUNTAIN_SCREAMER.SCREAM_FACE_HIT_HEIGHT or 3
	local dest = Vector3(tx, face_y, tz)

	proj.item = inst
	proj.ms_face_throw_stimuli = FACE_STIMULI
	proj.components.aimedprojectile.weapon = inst
	proj.components.aimedprojectile.damage = GetThrowDamage(inst, doer)
	proj.components.aimedprojectile:SetHitWorkAction(nil)
	proj.components.aimedprojectile:Throw(doer, dest, { fly_3d = true, target = target })

	return true
end

return {
	FACE_STIMULI = FACE_STIMULI,
	ThrowAtScreamerFace = ThrowAtScreamerFace,
}
