//
//  BlockerView.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StAnaylizer.h"
#import "StBlock.h"
#import "BlockerDataViewController.h"

@class BlockerDataViewController;

@interface BlockerView : NSView {
    NSView *baseView;
    NSTreeController *treeController;
    BlockerDataViewController *dataViewController;
}

@property (assign) IBOutlet BlockerDataViewController *dataViewController;
@property (assign) IBOutlet NSTreeController *treeController;
@property (assign) IBOutlet NSView *baseView;
@property (assign) StAnaylizer *objectValue;
@property (readonly) NSManagedObjectContext *managedObjectContext;

@end

