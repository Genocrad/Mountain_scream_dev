local AddStategraphState = AddStategraphState

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local TIMEOUT = 2


AddStategraphState("wilson_client", 
  State{
        name = "ms_door_use_pre",
        tags = { "doing", "busy", "canrotate" },
        server_states = { "ms_door_use_pre", "ms_door_use" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("give")

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("give_pst")
                inst.sg:GoToState("idle", true)
                print(TheFocalPoint, "FOCALPOINT")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("give_pst")
            inst.sg:GoToState("idle", true)
            -- can Focalpoint be nil? idk, but better safe then sorry
            print(TheFocalPoint, "FOCALPOINT")
            if TheFocalPoint then
              TheFocalPoint.components.focalpoint:StartFocusSource(findnearestfloor(inst), "ms_focalpoint_floor", nil, 1000, 1000, 5)
            end
        end,
    })