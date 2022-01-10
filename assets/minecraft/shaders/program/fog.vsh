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

vec2 getControl(int index, vec2 screenSize) {
    return vec2(floor(screenSize.x / 2.0) + float(index) * 2.0 + 0.5, 0.5) / screenSize;
}

void main() {
    vec4 outPos = ProjMat * vec4(Position.xy, 0, 1.0);
    gl_Position = vec4(outPos.xy, 0.2, 1.0);
    texCoord = Position.xy / OutSize;

    vec2 start = getControl(0, OutSize);
    vec2 inc = vec2(2.0 / OutSize.x, 0.0);

    mat4 projMat = mat4(tan(decodeFloat(texture(DataSampler, start + 3.0 * inc).xyz)), decodeFloat(texture(DataSampler, start + 6.0 * inc).xyz), 0.0, 0.0,
            decodeFloat(texture(DataSampler, start + 5.0 * inc).xyz), tan(decodeFloat(texture(DataSampler, start + 4.0 * inc).xyz)), decodeFloat(texture(DataSampler, start + 7.0 * inc).xyz), decodeFloat(texture(DataSampler, start + 8.0 * inc).xyz),
            decodeFloat(texture(DataSampler, start + 9.0 * inc).xyz), decodeFloat(texture(DataSampler, start + 10.0 * inc).xyz), decodeFloat(texture(DataSampler, start + 11.0 * inc).xyz),  decodeFloat(texture(DataSampler, start + 12.0 * inc).xyz),
            decodeFloat(texture(DataSampler, start + 13.0 * inc).xyz), decodeFloat(texture(DataSampler, start + 14.0 * inc).xyz), decodeFloat(texture(DataSampler, start + 15.0 * inc).xyz), 0.0);
            
    projInv = inverse(projMat);

    fogColor = vec4(texture(DataSampler, start + inc * 25.0).rgb, texture(DataSampler, start + inc * 28.0).r);
    fogEnd = decodeFloat(texture(DataSampler, start + inc * 27.0).rgb) * 1000.0;
    fogStart = fogEnd * 0.5;//decodeFloat(texture(DataSampler, start + inc * 26.0).rgb) * 1000.0;
}