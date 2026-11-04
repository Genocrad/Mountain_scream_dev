uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;



attribute vec4 POS2D_UV;

uniform vec4 TIMEPARAMS;

varying vec3 PS_TEXCOORD;
varying vec3 PS_POS;
varying vec3 PS_FINAL_POS;
uniform vec3 FLOAT_PARAMS;
uniform mat4 COLOUR_XFORM;
uniform sampler2D SAMPLER[5];
uniform vec3 PARAMS;

#define ALPHA_TEST PARAMS.x
#define LIGHT_OVERRIDE PARAMS.y
#define BLOOM_TOGGLE PARAMS.z


void main()
{







    vec3 POSITION = vec3(POS2D_UV.xy, 0);

    float samplerIndex = floor(POS2D_UV.z/2.0);

    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0*samplerIndex, POS2D_UV.w, samplerIndex);



    PS_TEXCOORD = TEXCOORD0;

    vec3 object_pos = POSITION.xyz;




	vec4 world_pos = MatrixW * vec4( object_pos, 1.0 );



    mat4 Transmat = mat4(MatrixW[0][0], MatrixW[0][1], MatrixW[0][2], MatrixW[0][3],  // 1. column
                      step(0.2, MatrixW[1][0]), -0.005, step(0.2, MatrixW[1][2]), MatrixW[1][3],  // 2. column
                      MatrixW[2][0], MatrixW[2][1], MatrixW[2][2], MatrixW[2][3],  // 3. column
                      MatrixW[3][0], MatrixW[3][1], MatrixW[3][2], 1.0);

   // world_pos *= trans_z;


    mat4 mtxPV = MatrixP * MatrixV * Transmat;
    vec4 middlelayer = Transmat * vec4( object_pos.x, object_pos.y, 0.0, 1.0);
    PS_POS = middlelayer.xyz;
    gl_Position = mtxPV * vec4( object_pos.x, object_pos.y, 0.0, 1.0) ;
    PS_FINAL_POS = gl_Position.xyz;






}
