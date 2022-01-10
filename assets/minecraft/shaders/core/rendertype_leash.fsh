#version 150

#moj_import <utils.glsl>

flat in vec4 vertexColor;
in vec4 glpos;

out vec4 fragColor;

void main() {
    discardControlGLPos(gl_FragCoord.xy, glpos);
    fragColor = vertexColor;
}
