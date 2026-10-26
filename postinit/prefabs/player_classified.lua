local AddPrefabPostInit = AddPrefabPostInit

local ENV = env
GLOBAL.setfenv(1, GLOBAL)



AddPrefabPostInit("player_classified", function(inst)
  inst:DoStaticTaskInTime(1, function(inst)
    if inst.event_listeners["houndwarningdirty"][inst][1] then
      local old_houndwarning = inst.event_listeners["houndwarningdirty"][inst][1]
      
      local function OnHoundWarningDirty(inst)
        if inst._parent ~= nil and inst._parent.HUD ~= nil then
          print(inst._parent, inst._parent.Transform:GetWorldPosition())
          if IsInstInMSOverWorld(inst._parent) then    
            local soundprefab = "ms_falconwarning"            
      
            if soundprefab then
              local sound = SpawnPrefab(soundprefab)
            end
          end
        else
          old_houndwarning(inst)
        end
      end
      
      inst.event_listeners["houndwarningdirty"][inst][1] = OnHoundWarningDirty
    end
  end)
end)
