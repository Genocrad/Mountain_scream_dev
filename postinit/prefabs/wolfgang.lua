

AddPrefabPostInit("wolfgang", function(inst)
  if inst.components.workmultiplier then
    local oldfn = inst.components.workmultiplier.specialfn 
    if oldfn then
      inst.components.workmultiplier.specialfn = function(inst, action, target, tool, numworks, recoil)
        local result = oldfn(inst, action, target, tool, numworks, recoil)
        if result and target:HasTag("ms_ignorespecialwork") then
          return 90
        end
        return result
      end
    end
  end
end)
