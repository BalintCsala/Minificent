#version 150

in vec2 texCoord;
in vec4 fogColor;
in float fogStart;
in float fogEnd;
in mat4 projInv;

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;

out vec4 fragColor;

vec3 depthToView(float depth) {
    vec4 ndc = vec4(texCoord, depth, 1.0) * 2.0 - 1.0;
    vec4 viewPos = projInv * ndc;
    return viewPos.xyz / viewPos.w;
}

vec4 linear_fog(vec4 inColor, float vertexDistance) {
    if (vertexDistance <= fogStart) {
        return inColor;
    }

    float fogValue = vertexDistance < fogEnd ? smoothstep(fogStart, fogEnd, vertexDistance) : 1.0;
    return vec4(mix(inColor.rgb, fogColor.rgb, fogValue * fogColor.a), inColor.a);
}

void main() {
    vec4 color = texture(DiffuseSampler, texCoord);
    float depth = texture(DiffuseDepthSampler, texCoord).r;

    if (depth < 0.99999) {
        vec3 viewPos = depthToView(depth);
        float dist = length(viewPos);
        color = linear_fog(color, dist);
    }

    fragColor = color;
}