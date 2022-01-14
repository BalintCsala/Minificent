#version 150

const float FPRECISION = 4000000.0;

in vec4 Position;

uniform mat4 ProjMat;
uniform vec2 OutSize;
uniform sampler2D DataSampler;

out vec2 texCoord;
out vec4 fogColor;
out float fogStart;
out float fogEnd;
out mat4 projInv;

int decodeInt(vec3 ivec) {
    ivec *= 255.0;
    int s = ivec.b >= 128.0 ? -1 : 1;
    return s * (int(ivec.r) + int(ivec.g) * 256 + (int(ivec.b) - 64 + s * 64) * 256 * 256);
}

float decodeFloat(vec3 ivec) {
    return decodeInt(ivec) / FPRECISION;
}

void main() {
    vec4 outPos = ProjMat * vec4(Position.xy, 0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);
    texCoord = Position.xy / OutSize;

    mat4 projMat = mat4(tan(decodeFloat(texelFetch(DataSampler, ivec2(3, 0), 0).xyz)), decodeFloat(texelFetch(DataSampler, ivec2(6, 0), 0).xyz), 0.0, 0.0,
            decodeFloat(texelFetch(DataSampler, ivec2(5, 0), 0).xyz), tan(decodeFloat(texelFetch(DataSampler, ivec2(4, 0), 0).xyz)), decodeFloat(texelFetch(DataSampler, ivec2(7, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(8, 0), 0).xyz),
            decodeFloat(texelFetch(DataSampler, ivec2(9, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(10, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(11, 0), 0).xyz),  decodeFloat(texelFetch(DataSampler, ivec2(12, 0), 0).xyz),
            decodeFloat(texelFetch(DataSampler, ivec2(13, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(14, 0), 0).xyz), decodeFloat(texelFetch(DataSampler, ivec2(15, 0), 0).xyz), 0.0);
            
    projInv = inverse(projMat);

    fogColor = vec4(texelFetch(DataSampler, ivec2(25, 0), 0).rgb, texelFetch(DataSampler, ivec2(28, 0), 0).r);
    fogEnd = decodeFloat(texelFetch(DataSampler, ivec2(27, 0), 0).rgb) * 1000.0;
    fogStart = decodeFloat(texelFetch(DataSampler, ivec2(26, 0), 0).rgb) * 1000.0;
}