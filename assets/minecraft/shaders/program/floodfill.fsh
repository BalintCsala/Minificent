#version 150

in vec2 texCoord;

uniform vec2 OutSize;

uniform sampler2D DiffuseSampler;
uniform sampler2D DataSampler;
uniform sampler2D DataDepthSampler;
uniform sampler2D ColorSampler;

out vec4 fragColor;

const vec3 SOUL_LIGHT =              vec3(0.03, 0.40, 0.90);
const vec3 FIRE_LIGHT =              vec3(1.00, 0.58, 0.00);
const vec3 NETHER_PORTAL_LIGHT =     vec3(0.42, 0.00, 0.75);
const vec3 ARTIFICAL_LIGHT =         vec3(0.79, 0.92, 1.00);
const vec3 BLACKLIGHT_LIGHT =        vec3(0.13, 0.00, 0.31);
const vec3 UNDERWATER_LIGHT =        vec3(0.72, 1.00, 0.65);
const vec3 BRIGHT_LIGHT =            vec3(1.00, 0.95, 0.30);
const vec3 REDSTONE_LIGHT =          vec3(1.00, 0.20, 0.15);
const vec3 SUBTLE_LIGHT =            vec3(0.29, 0.25, 0.00);
const vec3 CANDLE_LIGHT =            vec3(0.68, 0.59, 0.14);
const vec3 END_LIGHT =               vec3(0.89, 0.45, 1.00);
const vec3 DARK_BLUE_LIGHT =         vec3(0.00, 0.00, 0.40);
const vec3 AMETHYST_LIGHT =          vec3(0.23, 0.00, 0.30);

const vec3 COLORS[] = vec3[](
    SOUL_LIGHT,
    FIRE_LIGHT,
    NETHER_PORTAL_LIGHT,
    ARTIFICAL_LIGHT,
    BLACKLIGHT_LIGHT,
    UNDERWATER_LIGHT,
    BRIGHT_LIGHT,
    REDSTONE_LIGHT,
    SUBTLE_LIGHT,
    CANDLE_LIGHT,
    END_LIGHT,
    DARK_BLUE_LIGHT,
    AMETHYST_LIGHT
);

ivec2 positionToPixel(ivec3 position) {
    ivec2 iScreenSize = ivec2(OutSize);
    int area = iScreenSize.x * iScreenSize.y / 2;
    int side = int(pow(float(area), 1.0 / 3.0));

    if (clamp(position, ivec3(0), ivec3(side - 1)) != position) {
        return ivec2(-1);
    }

    int index = (position.x + position.z * side + position.y * side * side);
    ivec2 result = ivec2(
        (index % (iScreenSize.x / 2)) * 2,
        index / (iScreenSize.x / 2) + 1
    );
    result.x += result.y % 2;

    return result;
}

ivec3 pixelToPosition(ivec2 pixel) {
    ivec2 iScreenSize = ivec2(OutSize);
    int area = iScreenSize.x * iScreenSize.y / 2;
    int side = int(pow(float(area), 1.0 / 3.0));

    pixel.x -= pixel.y % 2;
    int index = pixel.x / 2 + (pixel.y - 1) * (iScreenSize.x / 2);
    return ivec3(index % side, index / (side * side), (index / side) % side);
}

void main() {
    ivec2 pixel = ivec2(gl_FragCoord.xy);
    if ((pixel.x + pixel.y) % 2 == 1) {
        fragColor = vec4(0);
        return;
    }

    float depth = texelFetch(DataDepthSampler, pixel, 0).r;
    vec3 multiplier = vec3(1);
    vec4 base = vec4(0);
    if (depth < 0.001) {
        vec4 data = texelFetch(DataSampler, pixel, 0);
        int id = int(data.b * 255.0);
        int type = (id >> 5) & 3;
        if (type == 0) {
            // Solid
            fragColor = vec4(0);
            return;
        } else if (type == 1) {
            // Translucent
            multiplier = texelFetch(ColorSampler, ivec2(id & 31, 0), 0).rgb;
        } else if (type == 2) {
            // Emissive
            base = vec4(COLORS[id & 31], 1.0);
        }
    }

    ivec3 blockPos = pixelToPosition(pixel);

    vec4 neighbourDown = texelFetch(DiffuseSampler, positionToPixel(blockPos + ivec3(0, -1, 0)), 0);
    vec4 neighbourUp = texelFetch(DiffuseSampler, positionToPixel(blockPos + ivec3(0, 1, 0)), 0);
    vec4 neighbourLeft = texelFetch(DiffuseSampler, positionToPixel(blockPos + ivec3(-1, 0, 0)), 0);
    vec4 neighbourRight = texelFetch(DiffuseSampler, positionToPixel(blockPos + ivec3(1, 0, 0)), 0);
    vec4 neighbourBack = texelFetch(DiffuseSampler, positionToPixel(blockPos + ivec3(0, 0, -1)), 0);
    vec4 neighbourForward = texelFetch(DiffuseSampler, positionToPixel(blockPos + ivec3(0, 0, 1)), 0);

    fragColor = max(
        max(
            max(neighbourDown, neighbourUp),
            max(neighbourLeft, neighbourRight)
        ),
        max(
            max(neighbourBack, neighbourForward),
            base
        )
    );
    fragColor -= 1.0 / 15.0;
    fragColor.rgb *= multiplier;
}