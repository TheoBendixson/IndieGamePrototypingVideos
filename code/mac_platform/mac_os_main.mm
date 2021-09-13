#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <mach/mach_init.h>
#include <mach/mach_time.h>


#include "../game_library/base_types.h"
#include <simd/simd.h>
#include "../game_library/game_renderer.h"

struct game_vertex_buffer
{
    game_vertex *Vertices;
    u32 DrawCount;
};

struct game_render_commands
{
    u32 CurrentFrameIndex;
    game_vertex_buffer VertexBuffers[3];
};

@interface
GameWindowDelegate: NSObject<NSWindowDelegate>
@end

@implementation GameWindowDelegate
- (void)windowWillClose:(NSNotification *)notification 
{
    [NSApp terminate: nil];
}
@end

@interface
MetalKitViewDelegate: NSObject<MTKViewDelegate>
@property (retain) id<MTLCommandQueue> CommandQueue;
@property (retain) NSMutableArray *MacVertexBuffers;
@property game_render_commands RenderCommands;
@property (retain) id<MTLRenderPipelineState> SolidColorPipelineState;
@end

static const NSUInteger kMaxInflightBuffers = 3;

@implementation MetalKitViewDelegate
{
    dispatch_semaphore_t _frameBoundarySemaphore;
    NSUInteger _currentFrameIndex;
}

// Vertex buffers for game object geometry

// What if you only had one vertex buffer?

// One buffer? Two buffers?

// Triple Buffering..

// NOTE: (Ted)   This is the game's render loop
- (void)configureMetal
{
    _frameBoundarySemaphore = dispatch_semaphore_create(kMaxInflightBuffers);
    _currentFrameIndex = 0;
}

// Vertical sync

// IMPORTANT: (Ted) This needs to be really really fast!!!
- (void)drawInMTKView:(MTKView *)view
{
    dispatch_semaphore_wait(_frameBoundarySemaphore, DISPATCH_TIME_FOREVER);

    MTLViewport Viewport = { 0, 0, 2048.0f, 2048.0f };

    u32 FrameIndex = _currentFrameIndex;

    game_vertex *Vertices = _RenderCommands.VertexBuffers[FrameIndex].Vertices;
    
    game_vertex V1 = { { -1.0f, 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 1.0f, 1.0f } };
    Vertices[0] = V1;

    game_vertex V2 = { { 1.0f, 0.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 1.0f, 1.0f } };
    Vertices[1] = V2;

    game_vertex V3 = { { 0.0f, -1.0f, 0.0f, 0.0f }, { 0.0f, 0.0f, 1.0f, 1.0f } };
    Vertices[2] = V3;

    @autoreleasepool 
    {
        id<MTLCommandBuffer> CommandBuffer = [[self CommandQueue] commandBuffer];

        MTLRenderPassDescriptor *RenderPassDescriptor = [view currentRenderPassDescriptor];
        RenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;

        MTLClearColor MetalClearColor = MTLClearColorMake(0.0f, 1.0f, 0.0f, 1.0f);
        RenderPassDescriptor.colorAttachments[0].clearColor = MetalClearColor;

        // MTLRenderCommandEncoder
        id<MTLRenderCommandEncoder> RenderEncoder = [CommandBuffer renderCommandEncoderWithDescriptor: RenderPassDescriptor];
        [RenderEncoder setViewport: Viewport];
        [RenderEncoder setRenderPipelineState: [self SolidColorPipelineState]];

        // NOTE: (Ted)  Preparing to render
        id<MTLBuffer> MacVertexBuffer = [[self MacVertexBuffers] objectAtIndex: _currentFrameIndex];

        [RenderEncoder setVertexBuffer: MacVertexBuffer  
                                offset: 0 
                               atIndex: 0];

        [RenderEncoder drawPrimitives: MTLPrimitiveTypeTriangle
                          vertexStart: 0 
                          vertexCount: 3];

        [RenderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable
        id<CAMetalDrawable> NextDrawable = [view currentDrawable];
        [CommandBuffer presentDrawable: NextDrawable];

        u32 NextIndex = _currentFrameIndex + 1;

        if (NextIndex > 2)
        {
            NextIndex = 0;
        }

        _currentFrameIndex = NextIndex;

        __block dispatch_semaphore_t semaphore = _frameBoundarySemaphore;

        [CommandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
            dispatch_semaphore_signal(semaphore);
        }];

        [CommandBuffer commit];
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{

}

@end

int main(int argc, const char * argv[]) 
{
    NSLog(@"Mooselutions is running!");    

    NSRect WindowRectangle = NSMakeRect(0.0f, 0.0f, 1024.0f, 1024.f);

    NSWindow *Window = [[NSWindow alloc] initWithContentRect: WindowRectangle 
                                                   styleMask: (NSWindowStyleMaskTitled |
                                                               NSWindowStyleMaskClosable)
                                                     backing: NSBackingStoreBuffered 
                                                       defer: NO];

    GameWindowDelegate *WindowDelegate = [[GameWindowDelegate alloc] init];
    [Window setDelegate: WindowDelegate];

    [Window setBackgroundColor: [NSColor redColor]];
    [Window setTitle: @"Mooselutions"];
    [Window makeKeyAndOrderFront: nil];

    id<MTLDevice> MetalDevice = MTLCreateSystemDefaultDevice();
    id<MTLCommandQueue> CommandQueue = [MetalDevice newCommandQueue];

    MTKView *MetalKitView = [[MTKView alloc] initWithFrame: WindowRectangle
                                                    device: MetalDevice];
    Window.contentView = MetalKitView;

    // Setup the Metal Library with vertex shader and fragment shaders....
    NSError *Error = NULL;

    NSString *ShaderLibraryFilepath = [[NSBundle mainBundle] pathForResource: @"Shaders" ofType: @"metallib"];
    id<MTLLibrary> ShaderLibrary = [MetalDevice newLibraryWithFile: ShaderLibraryFilepath 
                                                             error: &Error];
    id<MTLFunction> VertexShader = [ShaderLibrary newFunctionWithName: @"vertexShader"];
    id<MTLFunction> FragmentShader = [ShaderLibrary newFunctionWithName: @"fragmentShader"];

    if (Error != NULL)
    {
        [NSException raise: @"Can't Setup Metal" 
                    format: @"Unable to shader libraries"];
    }

    // Setup Render Pipeline States
    MTLRenderPipelineDescriptor *SolidColorPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    [SolidColorPipelineDescriptor setVertexFunction: VertexShader];
    [SolidColorPipelineDescriptor setFragmentFunction: FragmentShader];
    SolidColorPipelineDescriptor.colorAttachments[0].pixelFormat = MetalKitView.colorPixelFormat;

    id<MTLRenderPipelineState> SolidColorPipelineState = [MetalDevice newRenderPipelineStateWithDescriptor: SolidColorPipelineDescriptor 
                                                                                                     error: &Error];

    if (Error != NULL)
    {
        [NSException raise: @"Can't Setup Metal" 
                    format: @"Unable to setup rendering pipeline state"];
    }


    u32 PageSize = getpagesize();
    u32 VertexBufferSize = PageSize*1000;

    game_render_commands RenderCommands = {};

    NSMutableArray *MacVertexBuffers = [[NSMutableArray alloc] init];

    for (u32 FrameIndex = 0;
         FrameIndex < 3;
         FrameIndex++)
     {
        game_vertex_buffer GameVertexBuffer = {};
        GameVertexBuffer.Vertices = (game_vertex *)mmap(0, VertexBufferSize, PROT_READ | PROT_WRITE,
                                                        MAP_PRIVATE | MAP_ANON, -1, 0);
        RenderCommands.VertexBuffers[FrameIndex] = GameVertexBuffer;

        id<MTLBuffer> MetalVertexBuffer = [MetalDevice newBufferWithBytesNoCopy: GameVertexBuffer.Vertices
                                                                         length: VertexBufferSize 
                                                                        options: MTLResourceStorageModeShared
                                                                    deallocator: nil];
        [MacVertexBuffers addObject: MetalVertexBuffer];
     }

    MetalKitViewDelegate *ViewDelegate = [[MetalKitViewDelegate alloc] init];
    [MetalKitView setDelegate: ViewDelegate];

    [ViewDelegate setMacVertexBuffers: MacVertexBuffers];
    [ViewDelegate setRenderCommands: RenderCommands];
    [ViewDelegate setSolidColorPipelineState: SolidColorPipelineState];
    [ViewDelegate setCommandQueue: CommandQueue];
    [ViewDelegate configureMetal];

    return NSApplicationMain(argc, argv);
}

// Delegate object?
