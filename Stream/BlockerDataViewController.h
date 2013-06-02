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
    NSManagedObject *lastFilterAnalyzer;
}

@property (assign) IBOutlet NSOutlineView *outlineView;
@property (assign) IBOutlet NSView *editorView;
@property (assign) IBOutlet NSTreeController *treeController;
@property (assign) BOOL observing;
@property (assign) StBlock *observingBlock;
@property (nonatomic, retain) NSViewController *editorViewController;
@property (nonatomic, retain) NSArray *sortDescriptors;

@property (nonatomic, retain )  NSString *selectedBlockLevel1;
@property (nonatomic, retain )  NSString *selectedBlockLevel2;
@property (nonatomic, retain )  NSString *selectedBlockLevel3;

- (void) startObserving;
- (void) stopObserving;
- (void) startObservingBlockEditor:(StBlock *)inBlock;
- (void) stopObservingBlockEditor;
- (void) removeViewController;
- (void) restoreSelection;
- (void) notifyOfImpendingDeletion:(NSArray *)blocks;
- (void) reloadView;
- (void) doubleClick:(id)nid;

- (void) suspendObservations;
- (void) resumeObservations;

@end

@interface NSTreeNode (OrderedExtension)
- (NSArray *) childrenArray;
@end