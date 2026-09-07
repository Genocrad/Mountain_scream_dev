-- Bronze gear repair: hold ms_bronze_detail, right-click damaged bronze items (+50%).

local function OnBronzeRepair(self, target, doer)
	local pct = TUNING.MS_BRONZE_REPAIR_PERCENT or 0.5
	local success = false

	if target.components.armor ~= nil then
		if target.components.armor:IsDamaged() then
			target.components.armor:SetPercent(math.min(1, target.components.armor:GetPercent() + pct))
			success = true
		end
	elseif target.components.finiteuses ~= nil then
		if target.components.finiteuses:GetPercent() < 1 then
			target.components.finiteuses:SetPercent(math.min(1, target.components.finiteuses:GetPercent() + pct))
			success = true
		end
	end

	if not success then
		return
	end

	if self.inst.components.stackable ~= nil then
		self.inst.components.stackable:Get():Remove()
	else
		self.inst:Remove()
	end

	if self.onrepaired ~= nil then
		self.onrepaired(self.inst, target, doer)
	end

	if doer ~= nil then
		doer:PushEvent("repair")
	end
	return true
end

local function MakeBronzeRepairKit(inst)
	inst:AddComponent("forgerepair")
	inst.components.forgerepair:SetRepairMaterial(FORGEMATERIALS.MS_BRONZE)
	inst.components.forgerepair.OnRepair = OnBronzeRepair
end

local function MakeBronzeRepairable(inst)
	inst:AddComponent("forgerepairable")
	inst.components.forgerepairable:SetRepairMaterial(FORGEMATERIALS.MS_BRONZE)

	-- Constructor only auto-syncs armor/fueled; finiteuses needs an initial pass.
	if inst.components.armor ~= nil then
		inst.components.forgerepairable:SetRepairable(inst.components.armor:IsDamaged())
	elseif inst.components.finiteuses ~= nil then
		inst.components.forgerepairable:SetRepairable(inst.components.finiteuses:GetPercent() < 1)
	end
end

return {
	MakeBronzeRepairKit = MakeBronzeRepairKit,
	MakeBronzeRepairable = MakeBronzeRepairable,
}
