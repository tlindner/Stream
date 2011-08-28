//
//  BlockerDataViewController.h
//  Stream
//
//  Created by tim lindner on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BlockerView.h"
#import "StBlock.h"

@class BlockerView;

@interface BlockerDataViewController : NSViewController {
    BlockerView *parentView;
    NSTreeController *treeController;
}

@property (assign) IBOutlet BlockerView *parentView;
@property (assign) IBOutlet NSTreeController *treeController;
@property (assign) BOOL observing;

- (void) startObserving;
- (void) stopObserving;

@end
