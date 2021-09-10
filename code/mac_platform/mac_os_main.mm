#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <mach/mach_init.h>
#include <mach/mach_time.h>

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

    MTLViewport Viewport = { 0, 0, 1024.0f, 1024.0f };

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
        [RenderEncoder endEncoding];

        // Schedule a present once the framebuffer is complete using the current drawable
        id<CAMetalDrawable> NextDrawable = [view currentDrawable];
        [CommandBuffer presentDrawable: NextDrawable];

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

    id<MTLRenderPipelineState> SolidColorPipelineState = [MetalDevice newRenderPipelineStateWithDescriptor: SolidColorPipelineDescriptor 
                                                                                                     error: &Error];

    if (Error != NULL)
    {
        [NSException raise: @"Can't Setup Metal" 
                    format: @"Unable to setup rendering pipeline state"];
    }

    MTKView *MetalKitView = [[MTKView alloc] initWithFrame: WindowRectangle
                                                    device: MetalDevice];
    Window.contentView = MetalKitView;

    MetalKitViewDelegate *ViewDelegate = [[MetalKitViewDelegate alloc] init];
    [MetalKitView setDelegate: ViewDelegate];

    [ViewDelegate setCommandQueue: CommandQueue];
    [ViewDelegate configureMetal];

    return NSApplicationMain(argc, argv);
}

// Delegate object?
