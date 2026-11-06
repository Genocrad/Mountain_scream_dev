uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;

// All draw calls/symbols of this entity share its actual world origin.
uniform vec3 FLOAT_PARAMS;

attribute vec4 POS2D_UV;

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;
varying vec3 PS_FINAL_POS;

void main()
{
    float sampler_index = floor(POS2D_UV.z / 2.0);
    PS_TEXCOORD = vec3(POS2D_UV.z - 2.0 * sampler_index,
                      POS2D_UV.w, sampler_index);

    // Like Porkland's animrotatingbillboard, transform the complete vertex
    // first, then rotate its world offset around an explicit entity origin.
    // MatrixW's translation is not assumed to be that origin.
    vec3 origin = FLOAT_PARAMS;
    vec3 native_world_pos = (MatrixW * vec4(POS2D_UV.xy, 0.0, 1.0)).xyz;
    vec3 view_offset = (MatrixV * vec4(native_world_pos - origin, 0.0)).xyz;

    // Keep the camera's heading, while replacing its pitch and roll with
    // world up. MatrixV's rows contain the camera's world-space axes.
    vec3 axis_y = vec3(0.0, 1.0, 0.0);
    vec3 view_right = vec3(MatrixV[0][0], MatrixV[1][0], MatrixV[2][0]);
    vec3 view_back = vec3(MatrixV[0][2], MatrixV[1][2], MatrixV[2][2]);
    vec3 axis_z = vec3(view_back.x, 0.0, view_back.z);
    if (length(axis_z) < 0.000001)
    {
        // Looking straight up/down: retain the camera's horizontal right.
        axis_z = cross(vec3(view_right.x, 0.0, view_right.z), axis_y);
    }
    axis_z /= max(length(axis_z), 0.000001);
    vec3 axis_x = cross(axis_y, axis_z);
    // Preserve the engine's screen-left/right convention for either handedness.
    if (dot(axis_x, view_right) < 0.0)
    {
        axis_x = -axis_x;
    }

    vec3 world_pos = origin + axis_x * view_offset.x
                            + axis_y * view_offset.y
                            + axis_z * view_offset.z;
    PS_POS = world_pos;
    gl_Position = MatrixP * MatrixV * vec4(world_pos, 1.0);
    PS_FINAL_POS = gl_Position.xyz;
}
