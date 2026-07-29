local AimedProjectile = Class(function(self, inst)
	self.inst = inst
	self.owner = nil
	self.start = nil
	self.dest = nil
	self.weapon = nil
	self.damage = 0

	self.speed = 20
	self.hitdist = 1
	self.range = 15
	self.launchoffset = nil
	self.hit_work_action = nil -- e.g. ACTIONS.CHOP / ACTIONS.MINE；nil 则不碰可工作物

	self.fly_3d = false
	self.preferred_target = nil

	self.onthrown = nil
	self.onhit = nil
	self.onmiss = nil

	inst:AddTag("projectile")
end)

function AimedProjectile:OnRemoveFromEntity()
	self.inst:RemoveTag("projectile")
end

function AimedProjectile:SetSpeed(speed)
	self.speed = speed
end

function AimedProjectile:SetRange(range)
	self.range = range
end

function AimedProjectile:SetHitDist(dist)
	self.hitdist = dist
end

function AimedProjectile:SetOnThrownFn(fn)
	self.onthrown = fn
end

function AimedProjectile:SetOnHitFn(fn)
	self.onhit = fn
end

function AimedProjectile:SetOnMissFn(fn)
	self.onmiss = fn
end

function AimedProjectile:SetLaunchOffset(offset)
	self.launchoffset = offset
end

function AimedProjectile:SetHitWorkAction(action)
	self.hit_work_action = action
end

function AimedProjectile:IsThrown()
	return self.dest ~= nil
end

function AimedProjectile:RotateToTarget(dest)
	local direction = (dest - self.inst:GetPosition()):GetNormalized()
	local angle = math.acos(direction:Dot(Vector3(1, 0, 0))) / DEGREES
	self.inst.Transform:SetRotation(angle)
	self.inst:FacePoint(dest)
end

local function SetFlightVelocity(self)
	local pos = self.inst:GetPosition()
	local dest = self.dest
	if dest == nil then
		return
	end

	local dx = dest.x - pos.x
	local dy = dest.y - pos.y
	local dz = dest.z - pos.z
	local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
	if dist <= 0.001 then
		return
	end

	local s = self.speed
	self.inst.Physics:SetVel(dx / dist * s, dy / dist * s, dz / dist * s)
	self.inst:FacePoint(dest)
end

-- data = { fly_3d = bool, target = ent }
function AimedProjectile:Throw(owner, pos, data)
	self.owner = owner
	self.start = owner:GetPosition()
	self.dest = pos
	self.fly_3d = data ~= nil and data.fly_3d or false
	self.preferred_target = data ~= nil and data.target or nil

	if owner ~= nil and self.launchoffset ~= nil then
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local facing_angle = owner.Transform:GetRotation() * DEGREES
		self.inst.Transform:SetPosition(
			x + self.launchoffset.x * math.cos(facing_angle),
			y + self.launchoffset.y,
			z - self.launchoffset.x * math.sin(facing_angle)
		)
	end

	self:RotateToTarget(self.dest)

	if self.fly_3d then
		self.inst.Physics:Stop()
		SetFlightVelocity(self)
	else
		self.inst.Physics:SetMotorVel(self.speed, 0, 0)
	end

	self.inst:StartUpdatingComponent(self)
	self.inst:PushEvent("onthrown", { thrower = owner })
	if self.onthrown ~= nil then
		self.onthrown(self.inst, owner, pos)
	end
end

function AimedProjectile:Stop()
	self.inst:StopUpdatingComponent(self)
	self.owner = nil
	self.dest = nil
	self.fly_3d = false
	self.preferred_target = nil
end

function AimedProjectile:Miss()
	local attacker = self.owner
	self.inst.Physics:Stop()
	self:Stop()
	if self.onmiss ~= nil then
		self.onmiss(self.inst, attacker)
	end
end

function AimedProjectile:Hit(target)
	local attacker = self.owner
	local weapon = self.weapon or self.inst

	self.inst.Physics:Stop()
	self:Stop()

	if attacker ~= nil
			and attacker.components.combat ~= nil
			and target.components.combat ~= nil
			and not (target:HasTag("player") or target:HasTag("companion")) then
		target.components.combat:GetAttacked(attacker, self.damage, weapon)
	end

	if self.onhit ~= nil then
		self.onhit(self.inst, attacker, target)
	end
end

local EXCLUDE_TAGS = { "player", "companion", "NOCLICK", "FX", "INLIMBO" }

function AimedProjectile:OnUpdate(dt)
	local pos = self.inst:GetPosition()

	if self.fly_3d then
		if self.range ~= nil and self.start ~= nil then
			local dx = pos.x - self.start.x
			local dz = pos.z - self.start.z
			if dx * dx + dz * dz > self.range * self.range then
				self:Miss()
				return
			end
		end

		if self.dest ~= nil then
			local hit_r = math.max(self.hitdist, 0.75)
			if distsq(pos, self.dest) < hit_r * hit_r then
				local target = self.preferred_target
				if target ~= nil and target:IsValid() then
					self:Hit(target)
				else
					self:Miss()
				end
				return
			end
			SetFlightVelocity(self)
		end
		return
	end

	if self.range ~= nil and distsq(self.start, pos) > self.range * self.range then
		self:Miss()
		return
	end

	if self.dest ~= nil and distsq(pos, self.dest) < 0.25 then
		self:Miss()
		return
	end

	local targets = TheSim:FindEntities(pos.x, 0, pos.z, 3, nil, EXCLUDE_TAGS)
	for _, v in ipairs(targets) do
		local can_hit = (v.components.health ~= nil and not v.components.health:IsDead())
			or (self.hit_work_action ~= nil
				and v.components.workable ~= nil
				and v.components.workable:CanBeWorked()
				and v.components.workable:GetWorkAction() == self.hit_work_action)
			or v:HasTag("structure")

		if can_hit then
			local range = v:GetPhysicsRadius(0) + self.hitdist
			if distsq(pos, v:GetPosition()) < range * range then
				self:Hit(v)
				return
			end
		end
	end
end

return AimedProjectile
