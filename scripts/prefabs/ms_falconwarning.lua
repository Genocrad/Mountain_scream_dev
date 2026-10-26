local SPAWN_DIST = 10 --hounded.lua::SPAWN_DIST

local function PlayWarningSound(inst, radius, soundoveride)

    inst.entity:SetParent(TheFocalPoint.entity)

    --Everyone gets their own hounds and therefore their own warnings
    local theta = math.random() * TWOPI

    inst.Transform:SetPosition(radius * math.cos(theta), 0, radius * math.sin(theta))
    local sound = "ms_sfx/ms_fx/hawk_distant"
    inst.SoundEmitter:PlaySound(sound)
    inst:Remove()
end

local function makewarning(distance, soundoveride)
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddSoundEmitter()

        inst:AddTag("FX")

        inst:DoTaskInTime(0, function()
            PlayWarningSound(inst, distance, soundoveride)
        end)

        inst.entity:SetCanSleep(false)
        inst.persists = false

        return inst
    end
end

return Prefab("ms_falconwarning", makewarning(SPAWN_DIST))
        