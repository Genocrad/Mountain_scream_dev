local AddStategraphState = AddStategraphState

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local TIMEOUT = 2


local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
	inst.Physics:SetCollisionMask(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
	inst.Physics:SetCollisionMask(
		COLLISION.WORLD,
		COLLISION.OBSTACLES,
		COLLISION.SMALLOBSTACLES,
		COLLISION.CHARACTERS,
		COLLISION.GIANTS,
    COLLISION.MS_CLOUDS
	)
end

AddStategraphState("wilson", 
  State{
    name = "ms_door_use_pre",
    tags = { "doing", "busy", "canrotate" },

    onenter = function(inst)
      inst.components.locomotor:Stop()
      inst.AnimState:PlayAnimation("give")
      inst.AnimState:PushAnimation("give_pst", false)
      inst.sg:SetTimeout(14 * FRAMES)
    end,

    ontimeout = function(inst)
      --give_pst should still be playing
      inst.sg:GoToState("idle", true)
    end,

    timeline =
    {
      TimeEvent(12 * FRAMES, function(inst)
          if inst.bufferedaction ~= nil and inst:PerformBufferedAction() then
            -- Do nothing let the action control the stategraph.
          else
            inst.sg:GoToState("idle")
          end
        end),
    },
  })

AddStategraphState("wilson", 
  State{
    name = "ms_door_use",
    tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },

    onenter = function(inst, data)
      ToggleOffPhysics(inst)
      inst.components.locomotor:Stop()

      inst.sg.statemem.target = data.teleporter
      inst.sg.statemem.heavy = inst.components.inventory:IsHeavyLifting()
      inst._isusingmsdoor:set(1)
      local pos = nil
      if data.teleporter ~= nil and data.teleporter.components.teleporter ~= nil then
        data.teleporter.components.teleporter:RegisterTeleportee(inst)
        pos = data.teleporter:GetPosition()
      end
      inst.sg.statemem.teleporterexit = data.teleporterexit -- Can be nil.

    end,

    events =
    {
      EventHandler("animover", function(inst)
          if inst.AnimState:AnimDone() then
            local x, y, z = inst.Transform:GetWorldPosition()
            local should_teleport = false
            if inst.sg.statemem.target ~= nil and
            inst.sg.statemem.target:IsValid() and
            inst.sg.statemem.target.components.teleporter ~= nil then
              --Unregister first before actually teleporting
              inst.sg.statemem.target.components.teleporter:UnregisterTeleportee(inst)
              local teleporterexit = inst.sg.statemem.teleporterexit
              if teleporterexit then
                if not teleporterexit:IsValid() then
                  teleporterexit = teleporterexit.overtakenhole
                  --this is just for an overtaken tentacle_pillar, otherwise nil
                end
                if inst.sg.statemem.target.components.teleporter:UseTemporaryExit(inst, teleporterexit) then
                  should_teleport = true
                end
              else
                if inst.sg.statemem.target.components.teleporter:Activate(inst) then
                  should_teleport = true
                  
                end
              end
            end
            if should_teleport then
              SpawnPrefab("dirt_puff").Transform:SetPosition(x, y, z)
              inst.sg.statemem.isteleporting = true
              inst.components.health:SetInvincible(true)
              if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
              end
              inst:Hide()
              inst.DynamicShadow:Enable(false)
              inst._isusingmsdoor:set(2)
              
              return
            end
            inst.sg:GoToState("idle")
          end
        end),
    },

    onexit = function(inst)
      if inst.sg.statemem.isphysicstoggle then
        ToggleOnPhysics(inst)
      end
      inst.Physics:Stop()

      if inst.sg.statemem.isteleporting then
        inst.components.health:SetInvincible(false)
        if inst.components.playercontroller ~= nil then
          inst.components.playercontroller:Enable(true)
        end
        inst:Show()
        inst.DynamicShadow:Enable(true)
      elseif inst.sg.statemem.target ~= nil
      and inst.sg.statemem.target:IsValid()
      and inst.sg.statemem.target.components.teleporter ~= nil then
        inst.sg.statemem.target.components.teleporter:UnregisterTeleportee(inst)
      end
 
    end,
  }
)