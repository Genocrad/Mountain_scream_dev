local function FinalOffset1(inst)
    inst.AnimState:SetFinalOffset(1)
end

local function FinalOffset2(inst)
    inst.AnimState:SetFinalOffset(2)
end

local function FinalOffset3(inst)
    inst.AnimState:SetFinalOffset(3)
end

local function FinalOffsetNegative1(inst)
    inst.AnimState:SetFinalOffset(-1)
end
local function FinalOffsetNegative2(inst)
    inst.AnimState:SetFinalOffset(-2)
end
local function FinalOffsetNegative3(inst)
    print("am i doing something")
    inst.AnimState:SetFinalOffset(-3)
    inst.AnimState:SetSortWorldOffset(0, -1, 0)
end

local function UsePointFiltering(inst)
	inst.AnimState:UsePointFiltering(true)
end

local function GroundOrientation(inst)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
end

local function Bloom(inst)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)
end

local function OceanTreeLeafFxFallUpdate(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.Transform:SetPosition(x, y - inst.fall_speed * FRAMES, z)
end

local fx =
{
    {
        name = "furnace_firesplash_fx",
        bank = "furnace_firesplash_fx",
        build = "furnace_firesplash_fx",
        anim = "idle",
        bloom = true,
        fn = FinalOffsetNegative2,
    },
}

FinalOffset1 = nil
FinalOffset2 = nil
FinalOffset3 = nil

return fx
