// A simple 2D Color shader to put a single color to various quads that will be drawn
// to the screen.

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef struct
{
    // The [[position]] attribute qualifier of this member indicates this value is
    // the clip space position of the vertex when this structure is returned from
    // the vertex shader
    float4 position [[position]];
    float4 color;

} RasterizerData;

struct metal_game_vertex
{
    float4 position;
    float4 color;
};

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant metal_game_vertex *vertexArray [[ buffer(0) ]])
{

    RasterizerData out;
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;

    // IMPORTANT: (Ted) Viewport size was not passed into the vertex shader.
    //                  This will break if the game runs in any window which does not
    //                  have 1024x1024 as its size!!
    float2 normalizedPosition = (pixelSpacePosition / (1024.0 / 2.0)) - 1;

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    // Z is set to 0.0 and w to 1.0 because this is 2D sample.
    out.position = vector_float4(normalizedPosition.x, normalizedPosition.y, 0.0, 1.0);
    out.color = vertexArray[vertexID].color;

    return out;
}

// Fragment function
fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the interpolated color.
    return in.color;
}
