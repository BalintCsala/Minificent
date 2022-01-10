#version 150

in vec2 texCoord;
in vec3 sunDir;
in mat4 projMat;
in mat4 modelViewMat;
in vec3 chunkOffset;
in vec3 rayDir;
in float near;
in float far;
in mat4 projInv;

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D DataSampler;
uniform sampler2D DataDepthSampler;
uniform sampler2D LightmapSampler;
uniform sampler2D ColorSampler;

uniform vec2 OutSize;

out vec4 fragColor;

int imod(int val, int modulo) {
    return val - val / modulo * modulo;
}

ivec2 positionToPixel(vec3 position, vec2 ScreenSize, out bool inside, int discardModulo) {
    inside = true;
    ivec2 iScreenSize = ivec2(ScreenSize);
    ivec3 iPosition = ivec3(floor(position));
    int area = iScreenSize.x * iScreenSize.y / 2;
    ivec3 sides = ivec3(int(pow(float(area), 1.0 / 3.0)));

    iPosition += sides / 2;

    if (clamp(iPosition, ivec3(0), sides - 1) != iPosition) {
        inside = false;
        return ivec2(-1);
    }

    int index = iPosition.x + iPosition.z * sides.x + iPosition.y * sides.x * sides.z;
    ivec2 result = ivec2(
        imod(index, iScreenSize.x / 2) * 2,
        index / (iScreenSize.x / 2) + 1
    );
    result.x += imod(result.y, 2);

    return result;
}

vec3 depthToView(vec2 texCoord, float depth, mat4 projInv) {
    vec4 ndc = vec4(texCoord, depth, 1) * 2 - 1;
    vec4 viewPos = projInv * ndc;
    return viewPos.xyz / viewPos.w;
}

void main() {
    float depth = texture(DiffuseDepthSampler, texCoord).r;
    vec3 viewPos = depthToView(texCoord, depth, projInv) * 0.9999;    

    fragColor = texture(DiffuseSampler, texCoord);
    vec3 blockPos = floor(viewPos - fract(chunkOffset));

    bool inside;
    ivec2 pixel = positionToPixel(blockPos, OutSize, inside, 0);
    /*if (inside) {
        float dataDepth = texelFetch(DataDepthSampler, pixel, 0).r;
        if (dataDepth > 0.001)
            return;
    }*/

    float shadow = 1.0;
    vec3 p = viewPos - fract(chunkOffset) + sunDir * 0.03;

    vec4 data = texelFetch(DataSampler, pixel, 0);

    /*for (int i = 0; i < 200; i++) {
        ivec2 pix = positionToPixel(floor(p), OutSize, inside, 0);

        if (inside && texelFetch(DataDepthSampler, pix, 0).r < 0.001) {
            float scale = pow(float(i) + 1, 0.5);
            shadow -= 50.0 / (200 * scale);
        }
        p += sunDir * exp(float(i) / 48) * 0.02;
    }   
    fragColor.rgb *= max(shadow, 0.5);*/
    vec4 lightmapData = texelFetch(LightmapSampler, pixel, 0);
    fragColor.rgb += mix(vec3(0), lightmapData.rgb, lightmapData.a) / 1.5;
}