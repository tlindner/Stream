//
//  AnaylizerTableViewCellView.h
//  Stream
//
//  Created by tim lindner on 7/30/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "ColorGradientView.h"

@interface AnaylizerTableViewCellView : NSTableCellView
{
    IBOutlet ColorGradientView *_cgv;
    IBOutlet NSView *_customView;
    IBOutlet NSView *dragThumbView;
    IBOutlet NSButton *tlDisclosure;
    NSViewController *editorController;
    NSMutableArray *newConstraints;
    NSSize dragOffsetIntoGrowBox;
    BOOL dragging;
    BOOL ignoreEvent;
    float rowHeight;
}

@property(nonatomic, retain) NSViewController *editorController;
@property(nonatomic, retain) NSMutableArray *newConstraints;

- (IBAction)removeAnaylizer:(id)sender;

@end
