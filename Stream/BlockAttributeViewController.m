//
//  BlockAttributeViewController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockAttributeViewController.h"
#import "StStream.h"
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

- (void)setRepresentedObject:(id)inRepresentedObject
{
    if( observationsActive == YES )
    {
        StBlock *theBlock = [self representedObject];
        
        if( theBlock != nil )
        {
            [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" context:self];
            [lastFilterAnaylizer removeObserver:self forKeyPath:@"editIndexSet" context:self];
            [lastFilterAnaylizer release];
        }
        
        observationsActive = NO;
    }

    [super setRepresentedObject:inRepresentedObject];
}

- (void) loadView
{
    [super loadView];
    [self reloadView];
}

- (void) reloadView
{
    StBlock *theBlock = [self representedObject];
    NSString *currentMode = [theBlock valueForKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
    blockFormatter.mode = currentMode;
    
//    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
//    [arrayController setSortDescriptors:[NSArray arrayWithObject:sd]];
    
//    NSAssert(observationsActive == NO, @"BlockAttributeView: double observer fault");

//    [theBlock addObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" options:NSKeyValueChangeSetting context:self];
//    lastFilterAnaylizer = (StData *)[[[theBlock getStream] lastFilterAnayliser] retain];
//    [lastFilterAnaylizer addObserver:self forKeyPath:@"editIndexSet" options:NSKeyValueChangeSetting context:self];
    
//    observationsActive = YES;
    [self resumeObservations];
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
    else if( [keyPath isEqualToString:@"editIndexSet"] )
    {
        [tableView setNeedsDisplay];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
//    StAnaylizer *theAna = [self representedObject];
//    theAna.viewController = nil;
    [self suspendObservations];
    
    [super dealloc];
}

- (NSColor *)tableView:(NSTableView *)aTableView backgroundColorForRow:(NSInteger)rowIndex
{
    #pragma unused(aTableView)
    StBlock *theBlock = [self representedObject];
    return [[theBlock subBlockAtIndex:rowIndex] attributeColor];
}

- (void) suspendObservations
{
    if( observationsActive == YES )
    {
        [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" context:self];
        [lastFilterAnaylizer removeObserver:self forKeyPath:@"editIndexSet" context:self];
        [lastFilterAnaylizer release];
        observationsActive = NO;
    }
}

- (void) resumeObservations
{
    if( observationsActive == NO )
    {
        observationsActive = YES;
        StBlock *theBlock = [self representedObject];
        [theBlock addObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" options:NSKeyValueChangeSetting context:self];

        lastFilterAnaylizer = (StData *)[[[theBlock getStream] lastFilterAnayliser] retain];
        [lastFilterAnaylizer addObserver:self forKeyPath:@"editIndexSet" options:NSKeyValueChangeSetting context:self];
    }
}

-(NSString *)nibName
{
    return @"BlockAttributeViewController";
}

@end
