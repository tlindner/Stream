//
//  GenericArbitraryGroupViewController.h
//  Stream
//
//  Created by tim lindner on 5/10/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GenericArbitraryGroupViewController : NSViewController
{
    BOOL madeChange;
}
@property (assign) IBOutlet NSArrayController *allBlockArrayController;
@property (readonly) NSArray *sortDescriptors;
@property (assign) IBOutlet NSButton *wholeMoveButton;
@property (assign) IBOutlet NSButton *deleteButton;
@property (assign) IBOutlet NSTextField *partialStartTextField;
@property (assign) IBOutlet NSTextField *partialLengthTextField;
@property (assign) IBOutlet NSButton *partialMoveButton;
@property (assign) IBOutlet NSArrayController *AssembledBlocksArrayController;
@property (assign) IBOutlet NSPopover *popover;

@property (assign) NSView *showView;

- (IBAction)wholeMove:(id)sender;
- (IBAction)deleteValue:(id)sender;
- (IBAction)movePartialBlock:(id)sender;
@end
