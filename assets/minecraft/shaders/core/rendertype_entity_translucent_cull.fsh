#version 150

#moj_import <utils.glsl>

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;

uniform vec4 ColorModulator;
uniform float FogEnd;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec2 texCoord1;
in vec4 normal;
in vec4 glpos;

out vec4 fragColor;

void main() {
    if (vertexDistance < FogEnd) discardControlGLPos(gl_FragCoord.xy, glpos);
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1 || distance(color.rgb, vec3(1, 0, 1)) < 0.01) {
        discard;
    }
    fragColor = color * vertexColor * ColorModulator;
}
