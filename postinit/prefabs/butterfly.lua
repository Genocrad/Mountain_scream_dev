-- Option A: vanilla butterflies that would home on mountain flowers are removed.
-- mountainbutterflyspawner is responsible for spawning mountain_butterfly there.

AddPrefabPostInit("butterfly", function(inst)
	if not TheWorld.ismastersim then
		return
	end

	inst:DoTaskInTime(0, function(inst)
		if not inst:IsValid() then
			return
		end

		local home = inst.components.homeseeker ~= nil and inst.components.homeseeker:GetHome() or nil
		if home ~= nil and home:IsValid() and home.prefab == "mountain_plants_flower" then
			if inst.butterflyspawner ~= nil then
				inst.butterflyspawner:StopTracking(inst)
			end
			inst:Remove()
		end
	end)
end)
