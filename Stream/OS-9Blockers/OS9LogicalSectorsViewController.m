//
//  OS9LogicalSectorsViewController.m
//  Stream
//
//  Created by tim lindner on 5/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "OS9LogicalSectorsViewController.h"
#import "StAnalyzer.h"
#import "StStream.h"

@interface OS9LogicalSectorsViewController ()

@end

@implementation OS9LogicalSectorsViewController

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
    StAnalyzer *theAna = self.representedObject;
    [theAna.parentStream regenerateAllBlocks];
}

@end
