//
//  AnaylizerListViewItem.h
//  Stream
//
//  Created by tim lindner on 4/21/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "SDListViewItem.h"

@class DragRegionView, ColorGradientView, TLImageWithPopover, StBlock;

@interface AnaylizerListViewItem : SDListViewItem
{
    NSViewController  *editorController;
}

@property (assign) IBOutlet DragRegionView *dragView;
@property (assign) IBOutlet NSButton *disclosureTriangle;
@property (assign) IBOutlet NSView *customView;
@property (retain) NSViewController *editorController;
@property (assign) IBOutlet ColorGradientView *colorGradientView;
@property (assign) IBOutlet NSButton *blockSettingsButton;
@property (assign) IBOutlet NSButton *anaylizerErrorButton;
@property (assign) IBOutlet NSViewController *blockSettingsViewController;
@property (assign) IBOutlet TLImageWithPopover *imageWithPopover;
@property (assign) NSTreeController *blockTreeController;
@property (assign) StBlock *previousBoundBlock;

- (IBAction)removeAnaylizer:(id)sender;
- (IBAction)collapse:(id)sender;
- (IBAction)blockSetttings:(id)sender;
- (void)loadStreamEditor;

@end
