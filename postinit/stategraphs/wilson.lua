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

local function EnsureUmbrellaGlideBuild(inst)
  if not inst._ms_umbrella_glide_build then
    inst.AnimState:AddOverrideBuild("player_actions_ms_umbrella_glide")
    inst._ms_umbrella_glide_build = true
  end
end

local function GetEquippedUmbrella(inst)
  local item = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
  if item ~= nil and item:HasTag("umbrella") then
    return item
  end
  return nil
end

local function CanUmbrellaGlide(inst)
  if GetEquippedUmbrella(inst) == nil then
    return false
  end
  local x, y, z = inst.Transform:GetWorldPosition()
  return TheWorld.net.components.dungeonmapoverwatch ~= nil
    and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x, y, z) ~= nil
end

local function ConsumeUmbrellaForGlide(inst)
  local item = GetEquippedUmbrella(inst)
  if item == nil then
    return
  end
  local cost = TUNING.MS_UMBRELLA_GLIDE_COST or 0.25
  if item.components.fueled ~= nil then
    item.components.fueled:SetPercent(math.max(0, item.components.fueled:GetPercent() - cost))
  elseif item.components.perishable ~= nil then
    item.components.perishable:ReducePercent(cost)
  end
end

local function ClearGlideMotor(inst)
  if inst.Physics ~= nil then
    inst.Physics:ClearMotorVelOverride()
    inst.Physics:Stop()
  end
end

local function LandUmbrellaGlide(inst)
  local x, y, z = inst.Transform:GetWorldPosition()
  ClearGlideMotor(inst)
  if inst.Physics ~= nil then
    inst.Physics:Teleport(x, 0, z)
  else
    inst.Transform:SetPosition(x, 0, z)
  end
  ConsumeUmbrellaForGlide(inst)
  inst.sg.statemem.gliding = true
  inst.sg:GoToState("ms_umbrella_glide_pst")
end

-- 下层落地段：从高处播 loop 缓降，落地播 pst。出发仍走 abyss_fall；攀爬绳仍走 abyss_drop。
AddStategraphState("wilson",
  State{
    name = "ms_umbrella_glide",
    tags = { "busy", "nopredict", "nomorph", "noattack", "nointerrupt", "nodangle", "falling" },

    onenter = function(inst)
      EnsureUmbrellaGlideBuild(inst)
      inst.components.locomotor:Stop()
      inst.components.locomotor:Clear()
      inst:ClearBufferedAction()

      inst.AnimState:PlayAnimation("umbrella_glide_loop", true)

      -- 穿过地面下落，由高度判定落地，避免 GROUND 碰撞把人立刻贴地。
      inst.sg.statemem.isphysicstoggle = true
      inst.Physics:ClearCollisionMask()
      inst.Physics:Stop()

      local x, y, z = inst.Transform:GetWorldPosition()
      local height = TUNING.MS_UMBRELLA_GLIDE_HEIGHT or 10
      local speed = TUNING.MS_UMBRELLA_GLIDE_SPEED or 4
      inst.Physics:Teleport(x, height, z)
      inst.Physics:SetMotorVelOverride(0, -speed, 0)
      inst:SnapCamera()

      if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(false)
      end
      inst.components.health:SetInvincible(true)

      inst.sg:SetTimeout(height / math.max(speed, 0.1) + 1)
    end,

    onupdate = function(inst)
      local speed = TUNING.MS_UMBRELLA_GLIDE_SPEED or 4
      inst.Physics:SetMotorVelOverride(0, -speed, 0)
      local x, y, z = inst.Transform:GetWorldPosition()
      if y <= 0.1 then
        LandUmbrellaGlide(inst)
      end
    end,

    ontimeout = function(inst)
      LandUmbrellaGlide(inst)
    end,

    onexit = function(inst)
      ClearGlideMotor(inst)
      if not inst.sg.statemem.gliding then
        if inst.sg.statemem.isphysicstoggle then
          ToggleOnPhysics(inst)
        end
        inst.components.health:SetInvincible(false)
        if inst.components.playercontroller ~= nil then
          inst.components.playercontroller:Enable(true)
        end
      end
    end,
  }
)

AddStategraphState("wilson",
  State{
    name = "ms_umbrella_glide_pst",
    tags = { "busy", "nopredict", "nomorph", "nodangle", "falling" },

    onenter = function(inst)
      EnsureUmbrellaGlideBuild(inst)
      inst.components.locomotor:Stop()
      inst.AnimState:PlayAnimation("umbrella_glide_pst")

      ToggleOnPhysics(inst)
      inst.components.health:SetInvincible(false)
      if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(false)
      end
    end,

    timeline =
    {
      TimeEvent(10 * FRAMES, function(inst)
        inst.sg:RemoveStateTag("busy")
      end),
    },

    events =
    {
      EventHandler("animover", function(inst)
        if inst.AnimState:AnimDone() then
          inst.sg:GoToState("idle")
        end
      end),
    },

    onexit = function(inst)
      if inst.sg.statemem.isphysicstoggle then
        ToggleOnPhysics(inst)
      end
      if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:Enable(true)
      end
    end,
  }
)

AddStategraphPostInit("wilson", function(sg)
  local abyss_fall = sg.states["abyss_fall"]
  if abyss_fall ~= nil then
    local old_onenter = abyss_fall.onenter
    abyss_fall.onenter = function(inst, teleport_pt)
      inst.sg.statemem.ms_umbrella_glide = CanUmbrellaGlide(inst)
      old_onenter(inst, teleport_pt)
    end

    if abyss_fall.timeline ~= nil then
      for _, v in ipairs(abyss_fall.timeline) do
        if v.time == 2.5 then
          local old_fn = v.fn
          v.fn = function(inst)
            if inst.sg.statemem.ms_umbrella_glide then
              inst.sg.statemem.falling = true
              if inst.components.drownable ~= nil then
                inst.components.drownable:Teleport()
              else
                inst:PutBackOnGround()
              end
              inst.sg:GoToState("ms_umbrella_glide")
              return
            end
            old_fn(inst)
          end
        end
      end
    end
  end

  for k, v in pairs(sg.states["abyss_drop"].timeline) do
    if v.time == 0.5 then
      local old_fn = v.fn
      v.fn = function(inst)
        old_fn(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        if TheWorld.net.components.dungeonmapoverwatch and TheWorld.net.components.dungeonmapoverwatch:GetNearestLevel(x,y,z) then
          inst:DoTaskInTime(0.029, function(inst)
            if inst.components.health then
              inst.components.health:DoDelta(-TUNING.MS_FALL_DAMAGE, false, "falling", true, nil, true)
            end
          inst.sg:GoToState("hit")
          end)
        end
      end
    end
  end
end)
