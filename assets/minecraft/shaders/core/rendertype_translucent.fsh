#version 150

#moj_import <utils.glsl>
#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform vec3 ChunkOffset;
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
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);;
    } else if (dataFace < 1.5) {
        fragColor = vertexColor;
    } else {
        vec3 storedChunkOffset = mod(ChunkOffset, vec3(16)) / 16.0;
        fragColor = vec4(encodeFloat(storedChunkOffset[int(gl_FragCoord.x)]), 1);
    }
}
