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
    NSArrayController *popupArrayController;
}

// Define the variables as properties
@property(nonatomic, retain) NSMutableArray *newConstraints;
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(nonatomic, retain) NSNib *actionPopOverNib;
@property(nonatomic, retain) NSArrayController *popupArrayController;
@property(nonatomic, retain) NSManagedObjectContext *subMOC;
@property(nonatomic, retain) NSManagedObject *subObjectValue;
@property(assign) int angle;

- (IBAction)doPopOver:(id)sender;
- (IBAction)popOverOK:(id)sender;
- (IBAction)popOverCancel:(id)sender;
@end