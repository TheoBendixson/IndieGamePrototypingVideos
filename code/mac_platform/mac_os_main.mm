#import <AppKit/AppKit.h>

#if 0
struct window
{
    // the data...
    float X, Y;
    float Width, Height;
    uint_32 BackgroundColor;
};

class NSWindow {

    // properties not directly accessible.

    // there is a struct in here!
    struct window
    {
        // the data...
        float X, Y;
        float Width, Height;
        uint_32 BackgroundColor;
    };

    // Initializers
    

    // Constructors
    // Destructors

    @property float Width;

    // Getters and Setters (A.K.A. "accessors")
    - (float) GetWidth {
        return _Width;
    }


    // Because you don't have direct access to the data!!

    /*
    real32 X, Y;
    real32 Width, Height;
    uint32 BackgroundColor;*/
}

struct window
{
    NSRect WindowRect;
    styleMask;
    backingStoreType;
    deferFlag;
    NSColor BackgroundColor;
    NSString Title;
}
#endif

int main(int argc, const char * argv[]) 
{
    NSLog(@"Mooselutions is running!");    

    NSRect WindowRectangle = NSMakeRect(0.0f, 0.0f, 1024.0f, 1024.f);

    NSWindow *Window = [[NSWindow alloc] initWithContentRect: WindowRectangle 
                                                   styleMask: (NSWindowStyleMaskTitled |
                                                               NSWindowStyleMaskClosable)
                                                     backing: NSBackingStoreBuffered 
                                                       defer: NO];

    [Window setBackgroundColor: [NSColor redColor]];
    [Window setTitle: @"Mooselutions"];
    [Window makeKeyAndOrderFront: nil];

    return NSApplicationMain(argc, argv);
}

