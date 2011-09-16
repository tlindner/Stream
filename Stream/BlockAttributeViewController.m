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
    if( [self representedObject] == nil )
    {
        if( observationsActive == YES )
        {
            [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" context:self];
            [[[[self representedObject] getStream] lastFilterAnayliser] removeObserver:self forKeyPath:@"editIndexSet" context:self];
            observationsActive = NO;
        }
    }
    
    [super setRepresentedObject:inRepresentedObject];
}

- (void) loadView
{
    [super loadView];
    
    StBlock *theBlock = [self representedObject];
    NSString *currentMode = [theBlock valueForKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
    blockFormatter.mode = currentMode;
    
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
    [arrayController setSortDescriptors:[NSArray arrayWithObject:sd]];
     
    [theBlock addObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" options:NSKeyValueChangeSetting context:self];
    [[[theBlock getStream] lastFilterAnayliser] addObserver:self forKeyPath:@"editIndexSet" options:NSKeyValueChangeSetting context:self];
    
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
    else if( [keyPath isEqualToString:@"editIndexSet"] )
    {
        [tableView setNeedsDisplay];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    StAnaylizer *theAna = [self representedObject];
    theAna.viewController = nil;

    if( observationsActive == YES )
    {
        [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" context:self];
        [[[[self representedObject] getStream] lastFilterAnayliser] removeObserver:self forKeyPath:@"editIndexSet" context:self];
        observationsActive = NO;
    }
    
    [super dealloc];
}

- (NSColor *)tableView:(NSTableView *)aTableView backgroundColorForRow:(NSInteger)rowIndex
{
    StBlock *theBlock = [self representedObject];
    return [[theBlock subBlockAtIndex:rowIndex] attributeColor];
}

-(NSString *)nibName
{
    return @"BlockAttributeViewController";
}

@end
