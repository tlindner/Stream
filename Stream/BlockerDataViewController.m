//
//  BlockerDataViewController.m
//  Stream
//
//  Created by tim lindner on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerDataViewController.h"
#import "AppDelegate.h"
#import "HexFiendAnaylizerController.h"
#import "Analyzation.h"
#import "StStream.h"
#import "StAnaylizer.h"

@implementation BlockerDataViewController
@synthesize treeController;
@synthesize observing;
@synthesize observingBlock;
@synthesize outlineView;
@synthesize editorView;
@synthesize editorViewController;
@synthesize sortDescriptors;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
        self.sortDescriptors = [NSArray arrayWithObject:sd];
    }
    
    return self;
}

- (void)setRepresentedObject:(id)representedObject
{
    if( representedObject == nil )
    {
        [self stopObserving];
        [self stopObservingBlockEditor];
        [self.editorViewController setRepresentedObject:nil];
    }
    
    [super setRepresentedObject:representedObject];
}

- (void)loadView
{
    [super loadView];

    StAnaylizer *theAna = [self representedObject];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(parentStream == %@) AND (parentBlock == nil) AND (anaylizerKind == %@)", theAna.parentStream, theAna.anaylizerKind ];
    [treeController setFetchPredicate:predicate];

    if( [[[self representedObject] valueForKeyPath:@"optionsDictionary.BlockerDataViewController.initializedOD"] boolValue] == YES )
    {
    }
    else
    {
        Class <BlockerProtocol> blockerClass = NSClassFromString([[self representedObject] valueForKey:@"anaylizerKind"]);
        
        if (blockerClass != nil )
        {
            [blockerClass makeBlocks:theAna.parentStream];
            [theAna setValue:[NSNumber numberWithBool:YES] forKeyPath:@"optionsDictionary.BlockerDataViewController.initializedOD"];
        }
        else
            NSLog( @"Could not create class: %@", [[self representedObject] valueForKey:@"anaylizerKind"] );
    }
    
    [self startObserving];
}

- (void) startObserving
{
    if( self.observing == NO )
    {
        [treeController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueChangeSetting context:nil];
        [[[[self representedObject] parentStream] lastFilterAnayliser] addObserver:self forKeyPath:@"editIndexSet" options:NSKeyValueChangeSetting context:nil];
    }

    self.observing = YES;
}

- (void) stopObserving;
{
    if( self.observing == YES )
    {
        [treeController removeObserver:self forKeyPath:@"selectedObjects"];
        [[[[self representedObject] parentStream] lastFilterAnayliser] removeObserver:self forKeyPath:@"editIndexSet"];
    }
    
    self.observing = NO;
}

- (void) startObservingBlockEditor:(StBlock *)inBlock
{
    if( self.observingBlock != inBlock )
    {
        [self stopObservingBlockEditor];
        self.observingBlock = inBlock;
        [self.observingBlock addObserver:self forKeyPath:@"currentEditorView" options:NSKeyValueChangeSetting context:nil];
    }
}

- (void) stopObservingBlockEditor
{
    if( self.observingBlock != nil )
    {
        [observingBlock removeObserver:self forKeyPath:@"currentEditorView"];
        self.observingBlock = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"selectedObjects"] || [keyPath isEqualToString:@"currentEditorView"] )
    {
        NSArray *selectedObjects = [[self treeController] selectedObjects];
        [self stopObservingBlockEditor];
        
        if( [selectedObjects count] > 0 )
        {
            StBlock *theBlock = [selectedObjects objectAtIndex:0];
            NSRect theFrame = [self.editorView frame];
            
            if( self.editorViewController != nil )
            {
                [self.editorViewController setRepresentedObject:nil];
                [[self.editorViewController view] removeFromSuperview];
                self.editorViewController = nil;
            }
             
//            Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:theBlock.currentEditorView];
//            
//            if( anaClass == nil )
//                anaClass = [HexFiendAnaylizerController class];
             
            Class anaClass = [[theBlock anaylizerObject] viewController];
            theFrame.origin.y = theFrame.origin.x = 0;
            self.editorViewController = [[[anaClass alloc] initWithNibName:nil bundle:nil] autorelease];
            [self.editorViewController setRepresentedObject:theBlock];
            [self.editorViewController loadView];
            [[self.editorViewController view] setFrame:theFrame];
            [self.editorView addSubview:[self.editorViewController view]];
            [self startObservingBlockEditor:theBlock];
        }
    }
    else if( [keyPath isEqualToString:@"editIndexSet"] )
    {
        [outlineView setNeedsDisplay];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    [[self.editorViewController view] removeFromSuperview];

    [self stopObserving];
    [self stopObservingBlockEditor];
    self.editorViewController = nil;
    self.sortDescriptors = nil;
    [super dealloc];
}

- (NSColor *)tableView:(NSOutlineView *)aTableView backgroundColorForRow:(NSInteger)rowIndex
{
    return [[[aTableView itemAtRow:rowIndex] representedObject] attributeColor];
}

-(NSString *)nibName
{
    return @"BlockerDataViewController";
}

@end
