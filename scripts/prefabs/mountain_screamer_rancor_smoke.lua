local ANIM_SMOKE_TEXTURE = resolvefilepath("images/rancor_smoke.tex")
local SMOKE_SHADER = "shaders/vfx_particle.ksh"

local COLOUR_ENVELOPE_NAME_SMOKE = "rancor_colourenvelope_smoke"
local SCALE_ENVELOPE_NAME_SMOKE = "rancor_scaleenvelope_smoke"


local EMBER_TEXTURE = "fx/snow.tex"
local EMBER_SHADER = "shaders/vfx_particle_add.ksh"

local assets_fx =
{
	Asset("IMAGE", ANIM_SMOKE_TEXTURE),
	Asset("SHADER", SMOKE_SHADER),
}

local SMOKE_RADIUS = 5
local SMOKE_SIZE = 1
local SMOKE_MAX_LIFETIME = 1.1


local function IntColour(r, g, b, a)
	return { r / 255, g / 255, b / 255, a / 255 }
end

local function InitEnvelope()
	-- SMOKE
	EnvelopeManager:AddColourEnvelope(
		COLOUR_ENVELOPE_NAME_SMOKE,
		{
			{ 0,	IntColour(50, 50, 50, 200) },
			{ .7,	IntColour(50, 50, 50, 100) },
			{ 1,	IntColour(50, 50, 50, 0) },
		}
	)

  local smoke_max_scale = SMOKE_SIZE
	EnvelopeManager:AddVector2Envelope(
		SCALE_ENVELOPE_NAME_SMOKE,
		{
			{ 0, { smoke_max_scale, smoke_max_scale } },
			{ 1, { smoke_max_scale * 0.8, smoke_max_scale * 0.8 } },
		}
	)

	InitEnvelope = nil
	IntColour = nil
end

--------------------------------------------------------------------------



local function emit_smoke_fn(effect, smoke_circle_emitter, angle)
	local ox, oz = smoke_circle_emitter() -- Offset.
  local angle = angle ~=nil and angle or 0
  angle = math.rad(angle)
  local vx, vy, vz = 0, 0, 0
  vx, vy, vz = .01 * UnitRand(), 2 * UnitRand(), .01 * UnitRand()
   
	local lifetime = SMOKE_MAX_LIFETIME -- Do not vary VFX will make it pop on the engine side and we do not want any pops.
  
  local uv_offset = math.random(0, 1) * 0.5

  local direction = Vector3(1, 0.1, 0)
   effect:AddParticleUV(
        0,
        lifetime, -- lifetime
        0.3 *ox * math.cos(angle),0,0.3 * oz * math.sin(angle),
        ---math.cos(angle) + math.random(-1,1)*0.4 * math.sin(angle), 0, math.sin(angle) + math.random(-1,1)*0.4 * -math.cos(-angle), -- position
        math.cos(angle)*0.1 + math.random(-1,1)*0.2 * math.sin(angle), 0.5, math.sin(angle)*0.1 + math.random(-1,1)*0.2 * math.cos(-angle),
        --vx + direction.x * 0.05, vy, vz + direction.z * 0.05, -- velocity
        math.random(0,1)*0.5, math.random(0,1)*0.5 -- uv offset
    )
end

local function ClearParticles(inst)
    local effect = inst.VFXEffect
    effect:ClearAllParticles(0)
end

local function FastForwardParticles(inst, fast_forward)
    local effect = inst.VFXEffect
    effect:FastForward(0, fast_forward)
end

local INSTANT_NUM_SPAWN = 10
local function SetupParticles(inst)
	if InitEnvelope ~= nil then
		InitEnvelope()
	end

	local effect = inst.entity:AddVFXEffect()
	effect:InitEmitters(1)

	-- SMOKE
	effect:SetRenderResources(0, ANIM_SMOKE_TEXTURE, SMOKE_SHADER)
	effect:SetMaxNumParticles(0, 32)
	effect:SetMaxLifetime(0, SMOKE_MAX_LIFETIME)
	effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME_SMOKE)
	effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME_SMOKE)
    effect:SetUVFrameSize(0, 0.5, 0.5)
	effect:SetBlendMode(0, BLENDMODE.Premultiplied)
	effect:SetSortOrder(0, 0)
	effect:SetSortOffset(0, 0)
	effect:SetRadius(0, SMOKE_RADIUS) --only needed on a single emitter
  effect:SetDragCoefficient(0, 0.5)
    inst.ClearParticles = ClearParticles
    inst.FastForwardParticles = FastForwardParticles

	-----------------------------------------------------
    -- Local cache for when FX are emitted.
    local _world = TheWorld
    
    local data = {{-1, 0.5}, {0,1}, {1,0.5}, {0.6, 0}, {-0.6, 0}, {0, -1}}
    local centroid = {0,-1}
    local smoke_circle_emitter = CreateAreaEmitter(data, centroid)
    local ember_sphere_emitter = CreateSphereEmitter(SMOKE_SIZE)

    local num_to_emit = 0
    inst.num = 20
    local ticks_passed = 0
    EmitterManager:AddEmitter(inst, nil, function()
      ticks_passed = ticks_passed + 1
      if ticks_passed == 5 then
        if inst.target and inst.target:IsValid() and TheCamera then
          local angle = inst.target.Transform:GetRotation()
          angle = (-angle + 180) % 360 -- -180 to 180 
          local camangle = TheCamera.heading
          if math.abs(camangle - angle) < 78.75 then
            effect:SetSortOffset(0, inst.num)
          else
            effect:SetSortOffset(0, -inst.num)
          end
          emit_smoke_fn(effect, smoke_circle_emitter, angle)
          
        end
        ticks_passed = 0
      end
    end)
end

--------------------------------------------------------------------------

local function fn_fx()
	local inst = CreateEntity()

  inst.entity:AddTransform()
  inst.entity:AddFollower()
	inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.persists = false

    SetupParticles(inst)

    return inst
end


return Prefab("mountain_screamer_rancor_smoke", fn_fx, assets_fx)
    