uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
// Local player ground XZ, then 0 = effect off or 1 + player-hidden strength.
uniform vec3 FLOAT_PARAMS;
uniform mat4 COLOUR_XFORM;
uniform vec3 PARAMS;

attribute vec4 POS2D_UV;

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;
varying vec4 PS_CLIP_POS;
varying vec3 PS_REVEAL_CENTRE;
varying vec2 PS_NDC_TO_VIEW;
varying vec2 PS_REVEAL_PLANE;

// Keep in sync with ms_wall_occlusion.lua.
const float REVEAL_HEIGHT = 1.5;

#define LIGHT_OVERRIDE PARAMS.y

void main()
{
    float sampler_index = floor(POS2D_UV.z / 2.0);
    PS_TEXCOORD = vec3(POS2D_UV.z - 2.0 * sampler_index,
                      POS2D_UV.w, sampler_index);

    vec4 object_pos = vec4(POS2D_UV.xy, 0.0, 1.0);
    mat4 world_matrix = MatrixW;
    if (COLOUR_XFORM[0][3] != 1.0)
    {
        // Preserve the existing wall/slope geometry and symbol parameters.
        world_matrix = mat4(
            MatrixW[0],
            vec4(MatrixW[2][0], MatrixW[2][1] * -0.0033, MatrixW[2][2], MatrixW[1][3]),
            vec4(MatrixW[1][0], MatrixW[1][1], MatrixW[1][2], MatrixW[2][3]),
            vec4(MatrixW[3].xyz, 1.0));
        object_pos.z = COLOUR_XFORM[2][3] * COLOUR_XFORM[0][3] * 4.0 * object_pos.y
                     + (COLOUR_XFORM[2][3] - 1.0) * COLOUR_XFORM[0][3] * 4.0 * object_pos.y
                     + LIGHT_OVERRIDE * COLOUR_XFORM[1][3] * 4.0 * object_pos.x
                     + (LIGHT_OVERRIDE - 1.0) * COLOUR_XFORM[1][3] * 4.0 * object_pos.x;
    }

    vec4 world_pos = world_matrix * object_pos;
    PS_POS = world_pos.xyz;
    vec4 view_pos = MatrixV * world_pos;
    gl_Position = MatrixP * view_pos;
    // Interpolate homogeneous positions, then divide by W in the fragment
    // stage. Dividing at the vertices would distort the mask on slanted walls.
    PS_CLIP_POS = gl_Position;

    vec4 centre_view = MatrixV * vec4(FLOAT_PARAMS.x, REVEAL_HEIGHT, FLOAT_PARAMS.y, 1.0);
    vec4 centre_clip = MatrixP * centre_view;
    PS_REVEAL_CENTRE = vec3(centre_clip.xy / max(centre_clip.w, 0.001), centre_clip.w);

    // Convert NDC offsets to view units at depth 1, correcting display aspect ratio.
    PS_NDC_TO_VIEW = 1.0 / max(abs(vec2(MatrixP[0][0], MatrixP[1][1])), vec2(0.001));

    // Project the screen ellipse along its view rays onto an upright plane
    // through the player. Its normal follows camera heading, not camera pitch.
    // Clip W is positive view depth for either projection handedness.
    float forward_sign = sign(MatrixP[2][3]);
    vec3 plane_normal = vec3(MatrixV[0][2], 0.0, MatrixV[2][2]) * forward_sign;
    vec3 view_normal = (MatrixV * vec4(plane_normal, 0.0)).xyz;
    // The second value varies across the wall. Perspective interpolation
    // keeps it equal to the fragment's horizontal distance along the normal.
    PS_REVEAL_PLANE = vec2(dot(view_normal, centre_view.xyz),
                           dot(view_normal, view_pos.xyz));
}
