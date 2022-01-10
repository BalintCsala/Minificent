#version 150

in vec2 texCoord;

uniform vec2 OutSize;

uniform sampler2D DiffuseSampler;
uniform sampler2D DataSampler;
uniform sampler2D DataDepthSampler;
uniform sampler2D ColorSampler;

out vec4 fragColor;

const vec3 COLORS[] = vec3[](
    vec3(1, 0, 0), // Glowstone
    vec3(0, 1, 0), // Sea lantern
    vec3(0, 0, 1)  // Redstone lamp on
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
            multiplier = texelFetch(ColorSampler, ivec2(id & 31, 1), 0).rgb;
        } else if (type == 2) {
            // Emissive
            base = texelFetch(ColorSampler, ivec2(id & 31, 0), 0) - 1.0 / 15.0;
            base.a = 1.0;
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