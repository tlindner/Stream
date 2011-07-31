#import <Cocoa/Cocoa.h>

@interface ColorGradientView : NSView
{
    NSColor *startingColor;
    NSColor *endingColor;
    int angle;
    NSMutableArray *newConstraints;
    IBOutlet NSButton *tlDisclosure;
    IBOutlet NSButton *tlTitle;
    IBOutlet NSButton *tlAction;
}

// Define the variables as properties
@property(nonatomic, retain) NSMutableArray *newConstraints;
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(assign) int angle;

@end