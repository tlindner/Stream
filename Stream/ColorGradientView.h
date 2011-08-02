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
    
    NSNib *actionPopOverNib;
    IBOutlet NSPopUpButton *editorPopup;
    IBOutlet NSTextField *utiTextField;
    IBOutlet NSPopover *actionPopOver;
    NSArray *nibTopLevelObjects;
}

// Define the variables as properties
@property(nonatomic, retain) NSMutableArray *newConstraints;
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(nonatomic, retain) NSNib *actionPopOverNib;
@property(assign) int angle;

- (IBAction)doPopOver:(id)sender;

@end