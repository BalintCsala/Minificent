#version 150

const float EPSILON = 0.001;
const bool SMOOTH_LIGHTING = true;
const bool BETTER_AO = true;
const float NORMAL_CALCULATION = 1.0;

in vec2 texCoord;
in vec3 sunDir;
in mat4 projMat;
in mat4 modelViewMat;
in vec3 chunkOffset;
in float near;
in float far;
in mat4 mvpInv;
in float fogStart;
in float fogEnd;

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D DataSampler;
uniform sampler2D DataDepthSampler;
uniform sampler2D LightmapSampler;

uniform vec2 OutSize;

out vec4 fragColor;

ivec2 positionToPixel(ivec3 cell) {
    ivec2 iScreenSize = ivec2(OutSize);
    int area = iScreenSize.x * iScreenSize.y / 2;
    ivec3 sides = ivec3(int(pow(float(area), 1.0 / 3.0)));

    cell += sides / 2;

    if (clamp(cell, ivec3(0), sides - 1) != cell) {
        return ivec2(-1);
    }

    int index = cell.x + cell.z * sides.x + cell.y * sides.x * sides.z;
    ivec2 result = ivec2(
        (index % (iScreenSize.x / 2)) * 2,
        index / (iScreenSize.x / 2) + 1
    );
    result.x += result.y % 2;

    return result;
}

vec3 depthToPlayer(vec2 texCoord, float depth) {
    vec4 ndc = vec4(texCoord, depth, 1) * 2 - 1;
    vec4 playerPos = mvpInv * ndc;
    return playerPos.xyz / playerPos.w;
}

bool isSolid(ivec3 cell) {
    ivec2 pixel = positionToPixel(cell);
    float depth = texelFetch(DataDepthSampler, pixel, 0).r;
    if (depth > EPSILON)
        return false;
    vec4 data = texelFetch(DataSampler, pixel, 0);
    int id = int(data.b * 255.0);
    int type = (id >> 5) & 3;
    return type == 0;
}

float cylindricalDistance(vec3 playerPos) {
    float distXZ = length(playerPos.xz);
    float distY = playerPos.y;
    return max(distXZ, distY);
}

float linearFogFade(float vertexDistance) {
    if (vertexDistance <= fogStart) {
        return 1.0;
    } else if (vertexDistance >= fogEnd) {
        return 0.0;
    }

    return smoothstep(fogEnd, fogStart, vertexDistance);
}

void main() {
    fragColor = texture(DiffuseSampler, texCoord);

    float depth = texture(DiffuseDepthSampler, texCoord).r;
    vec3 playerPos = depthToPlayer(texCoord, depth);
    float cylDist = cylindricalDistance(playerPos);
    float fadeAmount = linearFogFade(cylDist);
    vec3 normal;
    
    if (NORMAL_CALCULATION > 0.5) {
        ivec2 uv = ivec2(texCoord * OutSize);
        float depthDown = texelFetch(DiffuseDepthSampler, uv + ivec2(0, -1), 0).r;
        float depthUp = texelFetch(DiffuseDepthSampler, uv + ivec2(0, 1), 0).r;
        float depthLeft = texelFetch(DiffuseDepthSampler, uv + ivec2(-1, 0), 0).r;
        float depthRight = texelFetch(DiffuseDepthSampler, uv + ivec2(1, 0), 0).r;

        vec2 texelSize = 1.0 / OutSize;
        vec3 normalPosX1, normalPosX2, normalPosY1, normalPosY2;
        if (abs(depthLeft - depth) < abs(depthRight - depth)) {
            normalPosX1 = depthToPlayer(texCoord + vec2(-1, 0) * texelSize, depthLeft);
            normalPosX2 = depthToPlayer(texCoord, depth);
        } else {
            normalPosX1 = depthToPlayer(texCoord, depth);
            normalPosX2 = depthToPlayer(texCoord + vec2(1, 0) * texelSize, depthRight);
        }
        if (abs(depthDown - depth) < abs(depthUp - depth)) {
            normalPosY1 = depthToPlayer(texCoord + vec2(0, -1) * texelSize, depthDown);
            normalPosY2 = depthToPlayer(texCoord, depth);
        } else {
            normalPosY1 = depthToPlayer(texCoord, depth);
            normalPosY2 = depthToPlayer(texCoord + vec2(0, 1) * texelSize, depthUp);
        }
        normal = normalize(cross(
            normalPosX2 - normalPosX1,
            normalPosY2 - normalPosY1
        ));
    } else {
        normal = normalize(cross(
            dFdx(playerPos),
            dFdy(playerPos)
        ));
    }

    vec3 samplePos = playerPos + normal * 0.01 - fract(chunkOffset);
    samplePos = mix(samplePos, floor(samplePos) + 0.5, abs(normal));
    vec4 lighting;
    if (SMOOTH_LIGHTING) { 
        ivec3 minCell = ivec3(floor(samplePos - 0.499));
        ivec3 maxCell = ivec3(ceil(samplePos - 0.501));
        vec4 bottomLeftBack =       texelFetch(LightmapSampler, positionToPixel(minCell), 0);
        vec4 bottomLeftForward =    texelFetch(LightmapSampler, positionToPixel(ivec3(minCell.x, minCell.y, maxCell.z)), 0);
        vec4 bottomRightBack =      texelFetch(LightmapSampler, positionToPixel(ivec3(maxCell.x, minCell.y, minCell.z)), 0);
        vec4 bottomRightForward =   texelFetch(LightmapSampler, positionToPixel(ivec3(maxCell.x, minCell.y, maxCell.z)), 0);
        vec4 topLeftBack =          texelFetch(LightmapSampler, positionToPixel(ivec3(minCell.x, maxCell.y, minCell.z)), 0);
        vec4 topLeftForward =       texelFetch(LightmapSampler, positionToPixel(ivec3(minCell.x, maxCell.y, maxCell.z)), 0);
        vec4 topRightBack =         texelFetch(LightmapSampler, positionToPixel(ivec3(maxCell.x, maxCell.y, minCell.z)), 0);
        vec4 topRightForward =      texelFetch(LightmapSampler, positionToPixel(maxCell), 0);

        lighting = mix(
            mix(
                mix(bottomLeftBack, bottomLeftForward, fract(samplePos.z - 0.5)),
                mix(bottomRightBack, bottomRightForward, fract(samplePos.z - 0.5)),
                fract(samplePos.x - 0.5)
            ),
            mix(
                mix(topLeftBack, topLeftForward, fract(samplePos.z - 0.5)),
                mix(topRightBack, topRightForward, fract(samplePos.z - 0.5)),
                fract(samplePos.x - 0.5)
            ),
            fract(samplePos.y - 0.5)
        );
    } else {
        ivec3 cell = ivec3(floor(samplePos));
        ivec2 pixel = positionToPixel(cell);
        lighting = texelFetch(LightmapSampler, pixel, 0);
    }
    fragColor.rgb += mix(vec3(0), lighting.rgb, lighting.a) / 1.5 * fadeAmount;

    if (BETTER_AO) {
        ivec3 cell = ivec3(floor(samplePos));
        
        ivec2 iScreenSize = ivec2(OutSize);
        int area = iScreenSize.x * iScreenSize.y / 2;
        ivec3 sides = ivec3(int(pow(float(area), 1.0 / 3.0)));
        if (all(lessThan(abs(cell), sides / 2 - 1))) {
            const ivec3[] OFFSETS = ivec3[](
                // X dir
                ivec3(0, -1, 0),
                ivec3(0, 0, -1),
                ivec3(0, -1, -1),
                ivec3(0, 0, 1),
                ivec3(0, -1, 1),
                ivec3(0, 1, 0),
                ivec3(0, 1, -1),
                ivec3(0, 1, 1),
                // Y dir
                ivec3(0, 0, -1),
                ivec3(-1, 0, 0),
                ivec3(-1, 0, -1),
                ivec3(1, 0, 0),
                ivec3(1, 0, -1),
                ivec3(0, 0, 1),
                ivec3(-1, 0, 1),
                ivec3(1, 0, 1),
                // Z dir
                ivec3(0, -1, 0),
                ivec3(-1, 0, 0),
                ivec3(-1, -1, 0),
                ivec3(1, 0, 0),
                ivec3(1, -1, 0),
                ivec3(0, 1, 0),
                ivec3(-1, 1, 0),
                ivec3(1, 1, 0)
            );

            vec2 facePosition = vec2(0);
            int index = 0;
            if (abs(normal.x) > 0.2) {
                facePosition = samplePos.zy;
                index = 0;
            } else if (abs(normal.y) > 0.2) {
                facePosition = samplePos.xz;
                index = 8;
            } else if (abs(normal.z) > 0.2) {
                facePosition = samplePos.xy;
                index = 16;
            }

            float pos1 = float(isSolid(cell + OFFSETS[index + 0]));
            float pos2 = float(isSolid(cell + OFFSETS[index + 1]));
            float pos3 = float(isSolid(cell + OFFSETS[index + 2]));
            float pos4 = float(isSolid(cell + OFFSETS[index + 3]));
            float pos5 = float(isSolid(cell + OFFSETS[index + 4]));
            float pos6 = float(isSolid(cell + OFFSETS[index + 5]));
            float pos7 = float(isSolid(cell + OFFSETS[index + 6]));
            float pos8 = float(isSolid(cell + OFFSETS[index + 7]));
            
            float bottomLeftLight =  1.0 - (pos1 + pos2 + pos3) / 3.0;
            float bottomRightLight = 1.0 - (pos1 + pos4 + pos5) / 3.0;
            float topLeftLight =     1.0 - (pos6 + pos2 + pos7) / 3.0;
            float topRightLight =    1.0 - (pos6 + pos4 + pos8) / 3.0;
            vec2 fractPos = fract(facePosition);
            float ao = mix(
                mix(bottomLeftLight, bottomRightLight, fractPos.x),
                mix(topLeftLight, topRightLight, fractPos.x),
                fractPos.y
            );
            float lightingMult = max(dot(normal, normalize(vec3(1, 3, 2))), 0.0) * 1.25 * ao * 0.6 + 0.4;
            fragColor.rgb *= mix(1.0, lightingMult, fadeAmount);
        }
    }
}