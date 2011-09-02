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
}

@property (assign) IBOutlet NSTreeController *treeController;
@property (assign) BOOL observing;
@property (assign) StBlock *observingBlock;
@property (readonly) NSManagedObjectContext *managedObjectContext;

- (void) startObserving;
- (void) stopObserving;
- (void) startObservingBlockEditor:(StBlock *)inBlock;
- (void) stopObservingBlockEditor;

@end
