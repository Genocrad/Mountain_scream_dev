local AddStategraphState = AddStategraphState
local AddStategraphPostInit = AddStategraphPostInit
local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local TIMEOUT = 2

local SNOW_TOWNPORTAL_FX = "ms_teleportsnowcoffin_fx"

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
	inst.Physics:SetCollisionMask(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
  if enable_collision_for_player then
    inst.Physics:SetCollisionMask(
      COLLISION.WORLD,
      COLLISION.OBSTACLES,
      COLLISION.SMALLOBSTACLES,
      COLLISION.CHARACTERS,
      COLLISION.GIANTS,
      COLLISION.MS_CLOUDS
    )
  else
    inst.Physics:SetCollisionMask(
      COLLISION.WORLD,
      COLLISION.OBSTACLES,
      COLLISION.SMALLOBSTACLES,
      COLLISION.CHARACTERS,
      COLLISION.GIANTS
    )
  end
end

-- 竞技场传送：自写进出状态，直接生成雪特效（不碰官方 entertownportal）
AddStategraphState("wilson",
	State{
		name = "ms_entertownportal",
		tags = { "doing", "busy", "nopredict", "nomorph", "nodangle" },

		onenter = function(inst, data)
			ToggleOffPhysics(inst)
			inst.Physics:Stop()
			inst.components.locomotor:Stop()

			inst.sg.statemem.target = data.teleporter
			inst.sg.statemem.teleportarrivestate = "ms_exittownportal_pre"

			inst.AnimState:PlayAnimation("townportal_enter_pre")

			inst.sg.statemem.fx = SpawnPrefab(SNOW_TOWNPORTAL_FX)
			inst.sg.statemem.fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
		end,

		timeline =
		{
			TimeEvent(8 * FRAMES, function(inst)
				inst.sg.statemem.isteleporting = true
				inst.components.health:SetInvincible(true)
				if inst.components.playercontroller ~= nil then
					inst.components.playercontroller:Enable(false)
				end
				inst.DynamicShadow:Enable(false)
			end),
			TimeEvent(18 * FRAMES, function(inst)
				inst:Hide()
			end),
			TimeEvent(26 * FRAMES, function(inst)
				if inst.sg.statemem.target ~= nil and
					inst.sg.statemem.target.components.teleporter ~= nil and
					inst.sg.statemem.target.components.teleporter:Activate(inst) then
					inst:Hide()
					inst.sg.statemem.fx:KillFX()
				else
					inst.sg:GoToState("exittownportal")
				end
			end),
		},

		onexit = function(inst)
			inst.sg.statemem.fx:KillFX()

			if inst.sg.statemem.isphysicstoggle then
				ToggleOnPhysics(inst)
			end

			if inst.sg.statemem.isteleporting then
				inst.components.health:SetInvincible(false)
				if inst.components.playercontroller ~= nil then
					inst.components.playercontroller:Enable(true)
				end
				inst:Show()
				inst.DynamicShadow:Enable(true)
			end
		end,
	}
)

AddStategraphState("wilson",
	State{
		name = "ms_exittownportal_pre",
		tags = { "doing", "busy", "nopredict", "nomorph", "nodangle" },

		onenter = function(inst)
			ToggleOffPhysics(inst)
			inst.components.locomotor:Stop()

			inst.sg.statemem.fx = SpawnPrefab(SNOW_TOWNPORTAL_FX)
			inst.sg.statemem.fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

			inst:Hide()
			inst.components.health:SetInvincible(true)
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:Enable(false)
			end
			inst.DynamicShadow:Enable(false)

			inst.sg:SetTimeout(32 * FRAMES)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("exittownportal")
		end,

		onexit = function(inst)
			inst.sg.statemem.fx:KillFX()

			if inst.sg.statemem.isphysicstoggle then
				ToggleOnPhysics(inst)
			end

			inst:Show()
			inst.components.health:SetInvincible(false)
			if inst.components.playercontroller ~= nil then
				inst.components.playercontroller:Enable(true)
			end
			inst.DynamicShadow:Enable(true)
		end,
	}
)

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

AddStategraphPostInit("wilson", function(sg)
  for k, v in pairs(sg.states["abyss_drop"].timeline) do
    if v.time == 0.5 then 
      local old_fn = v.fn
      v.fn = function(inst)
        old_fn(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if TheWorld.net.components.dungeonmapoverwatch and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) then
          if inst.components.health then
            inst.components.health:DoDelta(-TUNING.MS_FALL_DAMAGE, false, "falling", true, nil, true)
          end
        end
      end
    end
  end
end)
