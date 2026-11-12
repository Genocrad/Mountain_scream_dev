uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
// The same geometry inputs as Porkland's waterfall: ground X, Z, yaw radians.
uniform vec3 FLOAT_PARAMS;
uniform mat4 COLOUR_XFORM;
uniform vec4 OCEAN_BLEND_PARAMS;

attribute vec4 POS2D_UV;

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;
varying vec4 PS_CLIP_POS;
varying vec3 PS_REVEAL_CENTRE;
varying vec2 PS_NDC_TO_VIEW;
varying vec2 PS_REVEAL_PLANE;
varying vec3 PS_WALL_FADE;

const float REVEAL_HEIGHT = 1.5;
// Match ms_mountain_wall_geometry.lua. ABD and BCD share the same B and D.
const vec3 SLOPE_A = vec3(-2.0, 0.0, 4.0);
const vec3 SLOPE_B = vec3(0.0, 0.0, 0.0);
const vec3 SLOPE_C = vec3(2.0, 0.0, 4.0);
const vec3 SLOPE_D = vec3(0.0, 1536.0 * 0.0033 * 4.0, 4.0);

vec3 RotateY(vec3 p, float angle)
{
    float c = cos(angle), s = sin(angle);
    return vec3(c * p.x + s * p.z, p.y, c * p.z - s * p.x);
}

vec3 SlopeVertex(vec3 native_offset)
{
    // The flat build supplies exactly three vertices per face. After the full
    // native transform their markers are X=-2/0/+2 at the base, and far along
    // ground Z for the tip. Rebuild them explicitly, like WaterfallOffset[].
    if (abs(native_offset.z) > 4.0)
        return SLOPE_D;
    if (native_offset.x < -1.0)
        return SLOPE_A;
    if (native_offset.x > 1.0)
        return SLOPE_C;
    return SLOPE_B;
}

float DecodeOffset(vec3 encoded)
{
    vec3 bytes = floor(encoded * 255.0 + 0.5);
    return (dot(bytes, vec3(65536.0, 256.0, 1.0)) - 8388608.0) / 256.0;
}

void main()
{
    float sampler_index = floor(POS2D_UV.z / 2.0);
    PS_TEXCOORD = vec3(POS2D_UV.z - 2.0 * sampler_index, POS2D_UV.w, sampler_index);

    // Keep MatrixW intact, including all native symbol/animation transforms.
    vec3 native_world = (MatrixW * vec4(POS2D_UV.xy, 0.0, 1.0)).xyz;
    vec3 origin = vec3(FLOAT_PARAMS.x, 0.0, FLOAT_PARAMS.y);
    vec3 native_offset = RotateY(native_world - origin, -FLOAT_PARAMS.z);
    vec3 world_pos = origin + RotateY(SlopeVertex(native_offset), FLOAT_PARAMS.z);

    PS_POS = world_pos;
    vec4 view_pos = MatrixV * vec4(world_pos, 1.0);
    gl_Position = MatrixP * view_pos;
    PS_CLIP_POS = gl_Position;

    // Existing view effects are independent of geometry. The colour channels
    // carry player offsets in 1/256 world units; ocean's scalar carries strength.
    vec3 add_colour = vec3(COLOUR_XFORM[0][3], COLOUR_XFORM[1][3], COLOUR_XFORM[2][3]);
    vec3 mult_colour = vec3(COLOUR_XFORM[0][0], COLOUR_XFORM[1][1], COLOUR_XFORM[2][2]);
    vec2 player_xz = origin.xz + vec2(DecodeOffset(add_colour), DecodeOffset(mult_colour));
    PS_WALL_FADE = vec3(OCEAN_BLEND_PARAMS.x, 1.0, 0.0);

    vec4 centre_view = MatrixV * vec4(player_xz.x, REVEAL_HEIGHT, player_xz.y, 1.0);
    vec4 centre_clip = MatrixP * centre_view;
    PS_REVEAL_CENTRE = vec3(centre_clip.xy / max(centre_clip.w, 0.001), centre_clip.w);
    PS_NDC_TO_VIEW = 1.0 / max(abs(vec2(MatrixP[0][0], MatrixP[1][1])), vec2(0.001));
    float forward_sign = sign(MatrixP[2][3]);
    vec3 plane_normal = vec3(MatrixV[0][2], 0.0, MatrixV[2][2]) * forward_sign;
    vec3 view_normal = (MatrixV * vec4(plane_normal, 0.0)).xyz;
    PS_REVEAL_PLANE = vec2(dot(view_normal, centre_view.xyz), dot(view_normal, view_pos.xyz));
}
