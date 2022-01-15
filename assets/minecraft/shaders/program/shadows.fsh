#version 150

const float EPSILON = 0.001;
const bool SMOOTH_LIGHTING = true;
const bool BETTER_AO = true;

in vec2 texCoord;
in vec3 sunDir;
in mat4 projMat;
in mat4 modelViewMat;
in vec3 chunkOffset;
in float near;
in float far;
in mat4 mvpInv;

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D DataSampler;
uniform sampler2D DataDepthSampler;
uniform sampler2D LightmapSampler;
uniform sampler2D ColorSampler;

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

vec3 depthToPlayer(float depth) {
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

void main() {
    fragColor = texture(DiffuseSampler, texCoord);

    float depth = texture(DiffuseDepthSampler, texCoord).r;
    vec3 playerPos = depthToPlayer(depth); 
    vec3 normal = normalize(cross(
        dFdx(playerPos),
        dFdy(playerPos)
    ));

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
    fragColor.rgb += mix(vec3(0), lighting.rgb, lighting.a) / 1.5;

    if (BETTER_AO) {
        ivec3 cell = ivec3(floor(samplePos));
        
        ivec2 iScreenSize = ivec2(OutSize);
        int area = iScreenSize.x * iScreenSize.y / 2;
        ivec3 sides = ivec3(int(pow(float(area), 1.0 / 3.0)));
        if (all(lessThan(abs(cell), sides / 2 - 1))) {
            float bottom = float(isSolid(cell + ivec3(0, -1, 0)));
            float top = float(isSolid(cell + ivec3(0, 1, 0)));
            float left = float(isSolid(cell + ivec3(-1, 0, 0)));
            float right = float(isSolid(cell + ivec3(1, 0, 0)));
            float back = float(isSolid(cell + ivec3(0, 0, -1)));
            float forward = float(isSolid(cell + ivec3(0, 0, 1)));

            float bottomLeft = float(isSolid(cell + ivec3(-1, -1, 0)));
            float bottomRight = float(isSolid(cell + ivec3(1, -1, 0)));
            float bottomBack = float(isSolid(cell + ivec3(0, -1, -1)));
            float bottomForward = float(isSolid(cell + ivec3(0, -1, 1)));
            float topLeft = float(isSolid(cell + ivec3(-1, 1, 0)));
            float topRight = float(isSolid(cell + ivec3(1, 1, 0)));
            float topBack = float(isSolid(cell + ivec3(0, 1, -1)));
            float topForward = float(isSolid(cell + ivec3(0, 1, 1)));

            float leftBack = float(isSolid(cell + ivec3(-1, 0, -1)));
            float leftForward = float(isSolid(cell + ivec3(-1, 0, 1)));
            float rightBack = float(isSolid(cell + ivec3(1, 0, -1)));
            float rightForward = float(isSolid(cell + ivec3(1, 0, 1)));

            float bottomLeftLight = 1.0; 
            float bottomRightLight = 1.0;
            float topLeftLight = 1.0;
            float topRightLight = 1.0;
            vec2 facePosition = vec2(0);
            if (abs(normal.x) > 0.2) {
                bottomLeftLight =    1.0 - (bottom + back + bottomBack) / 3.0;
                bottomRightLight =   1.0 - (bottom + forward + bottomForward) / 3.0;
                topLeftLight =       1.0 - (top + back + topBack) / 3.0;
                topRightLight =      1.0 - (top + forward + topForward) / 3.0;
                facePosition = samplePos.zy;
            } else if (abs(normal.y) > 0.2) {
                bottomLeftLight =    1.0 - (left + back + leftBack) / 3.0;
                bottomRightLight =   1.0 - (right + back + rightBack) / 3.0;
                topLeftLight =       1.0 - (left + forward + leftForward) / 3.0;
                topRightLight =      1.0 - (right + forward + rightForward) / 3.0;
                facePosition = samplePos.xz;
            } else if (abs(normal.z) > 0.2) {
                bottomLeftLight =    1.0 - (bottom + left + bottomLeft) / 3.0;
                bottomRightLight =   1.0 - (bottom + right + bottomRight) / 3.0;
                topLeftLight =       1.0 - (top + left + topLeft) / 3.0;
                topRightLight =      1.0 - (top + right + topRight) / 3.0;
                facePosition = samplePos.xy;
            }
            vec2 fractPos = fract(facePosition);
            float ao = mix(
                mix(bottomLeftLight, bottomRightLight, fractPos.x),
                mix(topLeftLight, topRightLight, fractPos.x),
                fractPos.y
            );
            fragColor.rgb *= max(dot(normal, normalize(vec3(1, 3, 2))), 0.0) * 1.25 * ao * 0.6 + 0.4;
        }
    }
    
}