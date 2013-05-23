//
//  BlockerViewOutlineView.m
//  Stream
//
//  Created by tim lindner on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerViewOutlineView.h"
#import "StBlock.h"
#import "BlockerDataViewController.h"

@implementation BlockerViewOutlineView

- (IBAction)makeSubStream:(id)sender
{
#pragma unused(sender)
    BlockerDataViewController *dvc = (BlockerDataViewController *)[self delegate];
    StBlock *observingBlock = [dvc observingBlock];
    [[self nextResponder] tryToPerform:@selector(makeSubStream:) with:observingBlock];
}

- (IBAction)exportBlocks:(id)sender
{
#pragma unused(sender)
    BlockerDataViewController *bdvc = (BlockerDataViewController *)[self delegate];
    NSTreeController *tc = [bdvc treeController];
    NSArray *so = [tc selectedObjects];
    
    [[self nextResponder] tryToPerform:@selector(exportBlocks:) with:so];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(makeSubStream:)) {
        BlockerDataViewController *dvc = (BlockerDataViewController *)[self delegate];
        StBlock *observingBlock = [dvc observingBlock];
        if (observingBlock != nil) {
            return YES;
        }
    }
    else if ([menuItem action] == @selector(exportBlocks:)) {
        BlockerDataViewController *dvc = (BlockerDataViewController *)[self delegate];
        StBlock *observingBlock = [dvc observingBlock];
        if (observingBlock != nil) {
            return YES;
        }
    }

    return NO;
}

@end
