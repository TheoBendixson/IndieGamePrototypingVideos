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

// NOTE: (Ted)  Move this to the cross-platform game library.
struct game_vertex
{
    float4 position;
    float4 color;
};

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant game_vertex *vertexArray [[ buffer(0) ]])
{

    RasterizerData out;
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    // Z is set to 0.0 and w to 1.0 because this is 2D sample.
    out.position = vector_float4(pixelSpacePosition.x, pixelSpacePosition.y, 0.0, 1.0);
    out.color = vertexArray[vertexID].color;

    return out;
}

// Fragment function
fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    // Return the interpolated color.
    return in.color;
}
