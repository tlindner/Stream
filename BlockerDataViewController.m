//
//  BlockerDataViewController.m
//  Stream
//
//  Created by tim lindner on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerDataViewController.h"
#import "HFAnaylizer.h"

@implementation BlockerDataViewController
@synthesize parentView;
@synthesize treeController;
@synthesize observing;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//- (void)awakeFromNib
//{
//    [treeController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueChangeSetting context:nil];
//}

- (void) startObserving
{
    if( self.observing == NO )
        [treeController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueChangeSetting context:nil];
    
    self.observing = YES;
}

- (void) stopObserving;
{
    if( self.observing == YES )
        [treeController removeObserver:self forKeyPath:@"selectedObjects"];
    
    self.observing = NO;
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"selectedObjects"] )
    {
        NSArray *selectedObjects = [object selectedObjects];
        
        if( [selectedObjects count] > 0 )
        {
            NSRect theFrame = [[self view] frame];

            [[[self view] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

            HFAnaylizer *hexView = [[HFAnaylizer alloc] initWithFrame:NSMakeRect(0, 0, theFrame.size.width, theFrame.size.height)];
            [[self view] addSubview:hexView];
            [hexView release];
            
            StBlock *theBlock = [selectedObjects objectAtIndex:0];
            
            [hexView setRepresentedObject:theBlock];
        }
    }
}

- (void)dealloc
{
    [self stopObserving];
    [super dealloc];
}
@end
