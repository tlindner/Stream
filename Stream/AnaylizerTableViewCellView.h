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
    NSViewController *editorController;
    NSMutableArray *newConstraints;
    NSSize dragOffsetIntoGrowBox;
    BOOL dragging;
    float rowHeight;
}

@property(nonatomic, retain) NSViewController *editorController;
@property(nonatomic, retain) NSMutableArray *newConstraints;



@end
