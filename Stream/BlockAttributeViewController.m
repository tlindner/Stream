//
//  BlockAttributeViewController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockAttributeViewController.h"
#import "StBlock.h"

@implementation BlockAttributeViewController
@synthesize tableView;
@synthesize arrayController;
@synthesize blockFormatter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setRepresentedObject:(id)representedObject
{
    if( representedObject == nil )
    {
        if( observationsActive == YES )
        {
            [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
            observationsActive = NO;
        }
    }
    
    [super setRepresentedObject:representedObject];
}

- (void) loadView
{
    [super loadView];
    
    StBlock *theBlock = [self representedObject];
    NSString *currentMode = [theBlock valueForKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
    blockFormatter.mode = currentMode;
    
    [theBlock addObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" options:NSKeyValueChangeSetting context:nil];
    observationsActive = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"optionsDictionary.BlockAttributeViewController.numericDisplay"] )
    {
        StBlock *theBlock = [self representedObject];
        NSString *currentMode = [theBlock valueForKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
        blockFormatter.mode = currentMode;
        [tableView reloadData];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    if( observationsActive == YES )
    {
        [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
        observationsActive = NO;
    }
    
    [super dealloc];
}

-(NSString *)nibName
{
    return @"BlockAttributeViewController";
}

@end
