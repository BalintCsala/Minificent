#version 150

const float PROJNEAR = 0.05;
const float FPRECISION = 4000000.0;
const float EPSILON = 0.001;

in vec4 Position;

uniform mat4 ProjMat;
uniform vec2 OutSize;
uniform sampler2D DataSampler;
uniform float Time;

out vec2 texCoord;
out vec3 sunDir;
out mat4 projMat;
out mat4 modelViewMat;
out vec3 chunkOffset;
out vec3 rayDir;
out float near;
out float far;
out mat4 mvpInv;
out float fogStart;
out float fogEnd;

int decodeInt(vec3 ivec) {
    ivec *= 255.0;
    int s = ivec.b >= 128.0 ? -1 : 1;
    return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}

float decodeFloat(vec3 ivec) {
    return decodeInt(ivec) / FPRECISION;
}

vec2 getControl(int index, vec2 screenSize) {
    return vec2(floor(screenSize.x / 2.0) + float(index) * 2.0 + 0.5, 0.5) / screenSize;
}

void main() {
    vec4 outPos = ProjMat * vec4(Position.xy, 0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);
    texCoord = Position.xy / OutSize;

    //simply decoding all the control data and constructing the sunDir, ProjMat, ModelViewMat
    vec2 start = getControl(0, OutSize);
    vec2 inc = vec2(2.0 / OutSize.x, 0.0);

    // ProjMat constructed assuming no translation or rotation matrices applied (aka no view bobbing).
    projMat = mat4(tan(decodeFloat(texelFetch(DataSampler, ivec2(3, 0), 0).xyz)), decodeFloat(texelFetch(DataSampler, ivec2(6, 0), 0).xyz), 0.0, 0.0,
            decodeFloat(texelFetch(DataSampler, ivec2(5, 0), 0).xyz), tan(decodeFloat(texelFetch(DataSampler, ivec2(4, 0), 0).xyz)), decodeFloat(texelFetch(DataSampler, ivec2(7, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(8, 0), 0).xyz),
            decodeFloat(texelFetch(DataSampler, ivec2(9, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(10, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(11, 0), 0).xyz),  decodeFloat(texelFetch(DataSampler, ivec2(12, 0), 0).xyz),
            decodeFloat(texelFetch(DataSampler, ivec2(13, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(14, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(15, 0), 0).xyz), 0.0);

    modelViewMat = mat4(decodeFloat(texelFetch(DataSampler, ivec2(16, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(17, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(18, 0), 0).xyz), 0.0,
            decodeFloat(texelFetch(DataSampler, ivec2(19, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(20, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(21, 0), 0).xyz), 0.0,
            decodeFloat(texelFetch(DataSampler, ivec2(22, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(23, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(24, 0), 0).xyz), 0.0,
            0.0, 0.0, 0.0, 1.0);

    near = PROJNEAR;
    far = projMat[3][2] * near / (projMat[3][2] + 2.0 * near);

    chunkOffset = vec3(
            decodeFloat(texelFetch(DataSampler, ivec2(0, 0), 0).xyz),
            decodeFloat(texelFetch(DataSampler, ivec2(1, 0), 0).xyz),
            decodeFloat(texelFetch(DataSampler, ivec2(2, 0), 0).xyz)
    ) * 16;

    sunDir = (inverse(modelViewMat) * vec4(
            decodeFloat(texture(DataSampler, start).xyz),
            decodeFloat(texture(DataSampler, start + inc).xyz),
            decodeFloat(texture(DataSampler, start + 2.0 * inc).xyz),
            1)).xyz;

    sunDir = normalize(sunDir + vec3(0, 0, 0.5));

    mvpInv = inverse(projMat * modelViewMat);

    fogEnd = decodeFloat(texelFetch(DataSampler, ivec2(27, 0), 0).rgb) * 1000.0;
    fogStart = decodeFloat(texelFetch(DataSampler, ivec2(26, 0), 0).rgb) * 1000.0;
}