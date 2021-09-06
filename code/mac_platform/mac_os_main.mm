#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>

@interface
GameWindowDelegate: NSObject<NSWindowDelegate>
@end

@implementation GameWindowDelegate
- (void)windowWillClose:(NSNotification *)notification 
{
    [NSApp terminate: nil];
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

    MTKView *MetalKitView = [[MTKView alloc] initWithFrame: WindowRectangle
                                                    device: MetalDevice];
    Window.contentView = MetalKitView;



    return NSApplicationMain(argc, argv);
}

// View class hierarchy
// NSView (all views inherit from this)
//  |
// MTKView (subclass)

// Views / View Hierarchy
// Hierarchical

// Root View --> A list of instructions for the GPU
//   |
//   Child View
//  |      |
//  CV    CV

// Two types of space of GPU
// 1. Vertex buffers
// 2. Texture memory

// Stuff that needs to get drawn

//  View can contain other views

// Windows 
// NSView
