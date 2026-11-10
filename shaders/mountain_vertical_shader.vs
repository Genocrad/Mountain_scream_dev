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
varying vec4 PS_CAMERA;

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
    gl_Position = MatrixP * MatrixV * world_pos;
    // Interpolate homogeneous positions, then divide by W in the fragment
    // stage. Dividing at the vertices would distort the mask on slanted walls.
    PS_CLIP_POS = gl_Position;

    vec4 centre_clip = MatrixP * MatrixV * vec4(FLOAT_PARAMS.x, REVEAL_HEIGHT, FLOAT_PARAMS.y, 1.0);
    PS_REVEAL_CENTRE = vec3(centre_clip.xy / max(centre_clip.w, 0.001), centre_clip.w);

    // Convert NDC offsets to view units at depth 1, correcting display aspect ratio.
    PS_NDC_TO_VIEW = 1.0 / max(abs(vec2(MatrixP[0][0], MatrixP[1][1])), vec2(0.001));

    // Camera position, and the depth of the ground at the screen centre where
    // the camera is focused. The camera always looks down, which settles the
    // sign of its view axis for either handedness.
    vec3 view_translation = MatrixV[3].xyz;
    vec3 camera_pos = -vec3(dot(MatrixV[0].xyz, view_translation),
                            dot(MatrixV[1].xyz, view_translation),
                            dot(MatrixV[2].xyz, view_translation));
    PS_CAMERA = vec4(camera_pos, camera_pos.y / max(abs(MatrixV[1][2]), 0.2));
}
