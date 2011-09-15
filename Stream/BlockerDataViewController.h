//
//  BlockerDataViewController.h
//  Stream
//
//  Created by tim lindner on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StBlock.h"

@class BlockerView;

@interface BlockerDataViewController : NSViewController {
    NSView *editorView;
    NSOutlineView *outlineView;
}

@property (assign) IBOutlet NSOutlineView *outlineView;
@property (assign) IBOutlet NSView *editorView;
@property (assign) IBOutlet NSTreeController *treeController;
@property (assign) BOOL observing;
@property (assign) StBlock *observingBlock;
@property (nonatomic, retain) NSViewController *editorViewController;
@property (nonatomic, retain) NSArray *sortDescriptors;

- (void) startObserving;
- (void) stopObserving;
- (void) startObservingBlockEditor:(StBlock *)inBlock;
- (void) stopObservingBlockEditor;

@end
