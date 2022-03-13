#version 150

#moj_import <light.glsl>
#moj_import <voxelization.glsl>
#moj_import <fog.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;
uniform vec2 ScreenSize;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
out vec4 normal;
out float dataFace;
out vec4 glpos;

const vec2[] OFFSETS = vec2[](
    vec2(0, 0),
    vec2(1, 0),
    vec2(1, 1),
    vec2(0, 1)
);

const bool BETTER_AO = true;

void main() {
    
    vec4 pos = vec4(Position + ChunkOffset, 1.0);
    vec4 textureColor = texture(Sampler0, UV0);
    if (distance(textureColor.rgb, vec3(1, 0, 1)) < 0.01) {
        if (Normal.y > 0) {
            // Data face used for voxelization
            dataFace = 1.0;
            bool inside;
            // TODO: Add gametime
            ivec2 pixel = positionToPixel(floor(Position + floor(ChunkOffset)), ScreenSize, inside);
            if (!inside) {
                gl_Position = vec4(5, 5, 0, 1);
                return;
            }
            gl_Position = vec4(
                (vec2(pixel) + OFFSETS[imod(gl_VertexID, 4)]) / ScreenSize * 2.0 - 1.0,
                -1,
                1
            );
            vertexColor = vec4(floor(Position.xz) / 16, textureColor.a, 1);
        } else {
            // Data face used for chunk offset storage
            gl_Position = vec4(
                OFFSETS[imod(gl_VertexID, 4)] * vec2(29, 1) / ScreenSize * 2.0 - 1.0,
                -1,
                1
            );
            dataFace = 2.0;
        }
    } else {
        vec4 color = Color;
        if (BETTER_AO) {
            ivec3 cell = ivec3(floor(Position + floor(ChunkOffset)));
            ivec2 iScreenSize = ivec2(ScreenSize);
            int area = iScreenSize.x * iScreenSize.y / 2;
            ivec3 sides = ivec3(int(pow(float(area), 1.0 / 3.0)));
            if (all(lessThan(abs(cell), sides / 2 - 1))) {
                color.rgb /= color.g;
            }
        }
        dataFace = 0.0;
        gl_Position = ProjMat * ModelViewMat * pos;

        vertexDistance = cylindrical_distance(ModelViewMat, pos.xyz);
        vertexColor = color * minecraft_sample_lightmap(Sampler2, UV2);
        texCoord0 = UV0;
        normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
    }
}
