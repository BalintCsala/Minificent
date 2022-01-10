#version 150

in vec2 texCoord;

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;

out vec4 fragColor;

void main() {
    fragColor = vec4(0);
    gl_FragDepth = 1.0;

    ivec2 pixel = ivec2(gl_FragCoord.xy);
    if ((pixel.x + pixel.y) % 2 == 1) {
        fragColor = vec4(0);
        return;
    }

    float depthSolid = texture(DiffuseDepthSampler, texCoord).r;
    float depthTranslucent = texture(TranslucentDepthSampler, texCoord).r;

    if (depthSolid < 0.001) {
        fragColor = texture(DiffuseSampler, texCoord);
        gl_FragDepth = depthSolid;
    } else if (depthTranslucent < 0.001) {
        fragColor = texture(TranslucentSampler, texCoord);
        gl_FragDepth = depthTranslucent;
    }
}