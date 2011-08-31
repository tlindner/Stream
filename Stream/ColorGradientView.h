#import <Cocoa/Cocoa.h>
#import "AnaylizerSettingPopOverAccessoryViewController.h"

#import "StAnaylizer.h"

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
    IBOutlet NSView *accessoryView;
    NSArrayController *popupArrayController;
    NSTextField *labelUTI;
    NSTextField *labelEditor;

    id observableEditorView;
    id observableSourceUTI;
}

@property (assign) IBOutlet NSTextField *labelUTI;
@property (assign) IBOutlet NSTextField *labelEditor;

// Define the variables as properties
@property(nonatomic, retain) NSMutableArray *newConstraints;
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(nonatomic, retain) NSNib *actionPopOverNib;
@property(nonatomic, retain) NSArrayController *popupArrayController;
//@property(nonatomic, retain) NSManagedObjectContext *subMOC;
//@property(nonatomic, retain) StAnaylizer *subObjectValue;
@property(nonatomic, retain) AnaylizerSettingPopOverAccessoryViewController *avc;
@property(assign) int angle;

- (IBAction)doPopOver:(id)sender;
- (IBAction)popOverOK:(id)sender;
- (IBAction)popOverCancel:(id)sender;
@end