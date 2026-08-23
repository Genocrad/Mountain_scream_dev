-- Guard against NaN/Inf rotations (e.g. cave wall decor from atan(y/x) when x==0).
-- Without this, SaveGame aborts with "entity table corruption detected" (-1.#IND).

local function IsBadRotation(rot)
	return type(rot) ~= "number"
		or rot ~= rot
		or rot == math.huge
		or rot == -math.huge
end

local function SanitizeRotation(inst)
	if inst == nil or not inst:IsValid() or inst.Transform == nil then
		return 0
	end
	local rot = inst.Transform:GetRotation()
	if IsBadRotation(rot) then
		inst.Transform:SetRotation(0)
		return 0
	end
	return rot
end

local function SanitizeAllSavedRotations()
	if not TheWorld.ismastersim then
		return
	end
	for _, ent in pairs(Ents) do
		if ent ~= nil and ent:IsValid() and ent.components ~= nil and ent.components.savedrotation ~= nil then
			SanitizeRotation(ent)
		end
	end
end

AddComponentPostInit("savedrotation", function(self)
	local old_onsave = self.OnSave
	function self:OnSave(...)
		SanitizeRotation(self.inst)
		if old_onsave ~= nil then
			return old_onsave(self, ...)
		end
		return { rotation = self.inst.Transform:GetRotation() }
	end

	local old_onload = self.OnLoad
	function self:OnLoad(data, ...)
		if old_onload ~= nil then
			old_onload(self, data, ...)
		elseif data ~= nil and data.rotation ~= nil and not IsBadRotation(data.rotation) then
			self.inst.Transform:SetRotation(data.rotation)
		end
		SanitizeRotation(self.inst)
	end

	self.inst:DoTaskInTime(0, function(inst)
		if inst:IsValid() then
			SanitizeRotation(inst)
		end
	end)
end)

-- Fix entities already in the running world before the next autosave
AddSimPostInit(function()
	if TheWorld ~= nil and TheWorld.ismastersim then
		TheWorld:DoTaskInTime(0, SanitizeAllSavedRotations)
		TheWorld:DoTaskInTime(1, SanitizeAllSavedRotations)
	end
end)
