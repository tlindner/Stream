//
//  AnaylizerListViewItem.h
//  Stream
//
//  Created by tim lindner on 4/21/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "SDListViewItem.h"

@class DragRegionView;
@class ColorGradientView;

@interface AnaylizerListViewItem : SDListViewItem
{
    NSViewController *editorController;
    BOOL ignoreEvent;
}

@property (assign) IBOutlet DragRegionView *dragView;
@property (assign) IBOutlet NSButton *disclosureTriangle;
@property (assign) IBOutlet NSView *customView;
@property (retain) NSViewController *editorController;
@property (assign) IBOutlet ColorGradientView *colorGradientView;

- (IBAction)removeAnaylizer:(id)sender;
- (IBAction)collapse:(id)sender;

- (void)loadStreamEditor;

@end
