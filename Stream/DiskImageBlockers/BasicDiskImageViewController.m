//
//  BasicDiskImageViewController.m
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "BasicDiskImageViewController.h"
#import "StAnaylizer.h"
#import "StStream.h"

@interface BasicDiskImageViewController ()

@end

@implementation BasicDiskImageViewController

@synthesize popover;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)showPopover:(NSView *)aView
{
    [popover showRelativeToRect:[aView bounds] ofView:aView preferredEdge:NSMaxYEdge];
}

- (void)popoverWillClose:(NSNotification *)notification
{
#pragma unused (notification)
    StAnaylizer *theAna = self.representedObject;
    [theAna.parentStream regenerateAllBlocks];
}

@end
