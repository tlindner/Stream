//
//  GenericArbitraryGroupViewController.m
//  Stream
//
//  Created by tim lindner on 5/10/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "GenericArbitraryGroupViewController.h"
#import "StAnaylizer.h"
#import "StBlock.h"
#import "StStream.h"
#import "GenericArbitraryGroupBlocker.h"

@interface GenericArbitraryGroupViewController ()

@end

@implementation GenericArbitraryGroupViewController

@synthesize allBlockArrayController;
@synthesize sortDescriptors;
@synthesize wholeMoveButton;
@synthesize deleteButton;
@synthesize partialStartTextField;
@synthesize partialLengthTextField;
@synthesize partialMoveButton;
@synthesize AssembledBlocksArrayController;
@synthesize showView;
@synthesize popover;

- (void)showPopover
{
    [popover showRelativeToRect:[self.showView bounds] ofView:self.showView preferredEdge:NSMaxYEdge];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//- (void)setRepresentedObject:(id)representedObject
//{
//    [super setRepresentedObject:representedObject];
//}
//
-(void)loadView
{
    [super loadView];
    
    StAnaylizer *theAna = self.representedObject;
    NSPredicate *pr = [NSPredicate predicateWithFormat:@"(parentStream == %@) AND (anaylizerKind != %@)", theAna.parentStream, [GenericArbitraryGroupBlocker anaylizerKey]];
    [allBlockArrayController setFetchPredicate:pr];
    
    [allBlockArrayController addObserver:self forKeyPath:@"selectionIndexes" options:(NSKeyValueObservingOptionNew) context:self];
    [AssembledBlocksArrayController addObserver:self forKeyPath:@"selectionIndexes" options:(NSKeyValueObservingOptionNew) context:self];
}

- (NSArray *)sortDescriptors
{
    return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        if (object == allBlockArrayController) {
            if ([keyPath isEqualToString:@"selectionIndexes"]) {

                if ([[allBlockArrayController selectionIndexes] count] == 0) {
                    [self.partialStartTextField setEnabled:NO];
                    [self.partialLengthTextField setEnabled:NO];
                    [self.partialMoveButton setEnabled:NO];
                    [self.wholeMoveButton setEnabled:NO];                
                } else if ([[allBlockArrayController selectionIndexes] count] == 1) {
                    [self.partialStartTextField setEnabled:YES];
                    [self.partialLengthTextField setEnabled:YES];
                    [self.partialMoveButton setEnabled:YES];
                    [self.wholeMoveButton setEnabled:YES];
                } else {
                    [self.partialStartTextField setEnabled:NO];
                    [self.partialLengthTextField setEnabled:NO];
                    [self.partialMoveButton setEnabled:NO];
                    [self.wholeMoveButton setEnabled:YES];
                }
            }
        }
        else if (object == AssembledBlocksArrayController) {
            if ([keyPath isEqualToString:@"selectionIndexes"]) {
                if ([[AssembledBlocksArrayController selectionIndexes] count] == 0) {
                    [self.deleteButton setEnabled:NO];
                } else {
                    [self.deleteButton setEnabled:YES];
                }
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
- (void)dealloc
{
    [allBlockArrayController removeObserver:self forKeyPath:@"selectionIndexes" context:self];
    [super dealloc];
}

- (void)popoverWillShow:(NSNotification *)notification
{
#pragma unused (notification)
    madeChange = NO;
}
- (void)popoverWillClose:(NSNotification *)notification
{
#pragma unused (notification)
    if (madeChange) {
        StAnaylizer *theAna = self.representedObject;
        [theAna.parentStream regenerateAllBlocks];
    }
}

- (IBAction)wholeMove:(id)sender {
#pragma unused (sender)
    NSArray *selectedObject = [allBlockArrayController selectedObjects];
    
    for (StBlock *aBlock in selectedObject) {
        [AssembledBlocksArrayController addObject:[namedRange namedRange:[NSValue valueWithRange:NSMakeRange(0, 0)] withName:aBlock.name]];
    }
    
    madeChange = YES;
}

- (IBAction)deleteValue:(id)sender {
#pragma unused (sender)
    [AssembledBlocksArrayController removeObjects:[AssembledBlocksArrayController selectedObjects]];
    
    madeChange = YES;
}

- (IBAction)movePartialBlock:(id)sender {
#pragma unused (sender)
    StBlock *aBlock = [[allBlockArrayController selectedObjects] objectAtIndex:0];
    
    int64_t location = [self.partialStartTextField intValue];
    int64_t length = [self.partialLengthTextField intValue];

    [AssembledBlocksArrayController addObject:[namedRange namedRange:[NSValue valueWithRange:NSMakeRange(location, length)] withName:aBlock.name]];
    
    madeChange = YES;
}

@end
