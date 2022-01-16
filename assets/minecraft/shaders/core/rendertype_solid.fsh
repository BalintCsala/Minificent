#version 150

#moj_import <utils.glsl>
#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float GameTime;
uniform vec3 ChunkOffset;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in vec4 vertexColor;
in vec2 texCoord0;
in vec4 normal;
in float dataFace;
in float blockLight;
in float vertexDistance;

out vec4 fragColor;

void main() {
    if (dataFace < 0.5) {
        vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
    } else if (dataFace < 1.5) {
        fragColor = vertexColor;
    } else {
        int index = int(gl_FragCoord.x);
        if (index <= 2) {
            vec3 storedChunkOffset = mod(ChunkOffset, vec3(16)) / 16.0;
            fragColor = vec4(encodeFloat(storedChunkOffset[index]), 1);
        } else if (index >= 5 && index <= 15) {
            int c = (index - 5) / 4;
            int r = (index - 5) - c * 4;
            c = (c == 0 && r == 1) ? c : c + 1;
            fragColor = vec4(encodeFloat(ProjMat[c][r]), 1.0);
        } else if (index >= 16 && index <= 24) {
            int c = (index - 16) / 3;
            int r = (index - 16) - c * 3;
            fragColor = vec4(encodeFloat(ModelViewMat[c][r]), 1.0);
        } else if (index >= 3 && index <= 4) {
            fragColor = vec4(encodeFloat(atan(ProjMat[index - 3][index - 3])), 1.0);
        } else if (index == 25) {
            fragColor = FogColor;
        } else if (index == 26) {
            fragColor = vec4(encodeFloat(FogStart / 1000.0), 1.0);
        } else if (index == 27) {
            fragColor = vec4(encodeFloat(FogEnd / 1000.0), 1.0);
        } else if (index == 28) {
            fragColor = vec4(FogColor.aaa, 1.0);
        } else {
            fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }
}
