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
@synthesize selectedBlockLevel1;
@synthesize selectedBlockLevel2;
@synthesize selectedBlockLevel3;

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

- (void)setRepresentedObject:(id)inRepresentedObject
{
    if( inRepresentedObject == nil )
    {
        [self stopObserving];
        [self stopObservingBlockEditor];
        [self.editorViewController setRepresentedObject:nil];
        
        /* store selected block away for safe keeping */
        NSIndexPath *ip = [treeController selectionIndexPath];
        NSUInteger paths[3];
        [ip getIndexes:paths];
        NSTreeNode *tn;
        self.selectedBlockLevel1 = nil;
        self.selectedBlockLevel2 = nil;
        self.selectedBlockLevel3 = nil;
        
        if( [ip length] > 0 )
        {
            tn = [[[treeController arrangedObjects] childNodes] objectAtIndex:paths[0]];
            self.selectedBlockLevel1 = [[tn representedObject] valueForKey:@"name"];
            if( [ip length] > 1 )
            {
                tn = [[tn childNodes] objectAtIndex:paths[1]];
                self.selectedBlockLevel2 = [[tn representedObject] valueForKey:@"name"];
                
                if( [ip length] > 2 )
                {
                    tn = [[tn childNodes] objectAtIndex:paths[2]];
                    self.selectedBlockLevel3 = [[tn representedObject] valueForKey:@"name"];
                    
                }
            }
        }
    }

    [super setRepresentedObject:inRepresentedObject];
}

- (void)restoreSelection
{
    NSUInteger paths[3] = {NSNotFound, NSNotFound, NSNotFound};
        
    /* restore selection */
    if( self.selectedBlockLevel1 != nil )
    {
        NSArray *treeArray1 = [[treeController arrangedObjects] childNodes];
        
        paths[0] = [treeArray1 indexOfObjectPassingTest:
                    ^(id obj, NSUInteger idx, BOOL *stop)
                    {
                        if( [[[obj representedObject] valueForKey:@"name"] isEqualToString:self.selectedBlockLevel1] )
                            return YES;
                        
                        return NO;
                    }];
        
        if( paths[0] != NSNotFound )
        {
            if( self.selectedBlockLevel2 != nil )
            {
                NSArray *treeArray2 = [[treeArray1 objectAtIndex:paths[0]] childNodes];
                paths[1] = [treeArray2 indexOfObjectPassingTest:
                            ^(id obj, NSUInteger idx, BOOL *stop)
                            {
                                if( [[[obj representedObject] valueForKey:@"name"] isEqualToString:self.selectedBlockLevel2] )
                                    return YES;
                                
                                return NO;
                            }];
                
                if( paths[1] != NSNotFound )
                {
                    if( self.selectedBlockLevel3 != nil )
                    {
                        NSArray *treeArray3 = [[treeArray2 objectAtIndex:paths[1]] childNodes];
                        paths[2] = [treeArray3 indexOfObjectPassingTest:
                                    ^(id obj, NSUInteger idx, BOOL *stop)
                                    {
                                        if( [[[obj representedObject] valueForKey:@"name"] isEqualToString:self.selectedBlockLevel3] )
                                            return YES;
                                        
                                        return NO;
                                    }];
                    }
                }
            }
        }
    }
    
    self.selectedBlockLevel1 = nil;
    self.selectedBlockLevel2 = nil;
    self.selectedBlockLevel3 = nil;

    NSUInteger length = 0;
    if( paths[0] != NSNotFound ) length++;
    if( paths[1] != NSNotFound ) length++;
    if( paths[2] != NSNotFound ) length++;
    
    if( length > 0 )
    {
        NSIndexPath *ip = [[NSIndexPath alloc] initWithIndexes:paths length:length];
        [treeController setSelectionIndexPath:ip];
        [ip release];
    }
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

    NSAssert(self.observing == NO, @"BlockAttributeView: double observer fault");
    
    [self startObserving];
}

- (void) startObserving
{
    if( self.observing == NO )
    {
        [treeController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueChangeSetting context:self];
        NSLog( @"blockerDataViewController: add observer for editIndexSet: %p" , self );
        lastFilterAnaylizer = [[[[self representedObject] parentStream] lastFilterAnayliser] retain];
        
        [lastFilterAnaylizer addObserver:self forKeyPath:@"editIndexSet" options:NSKeyValueChangeSetting context:self];
    }

    self.observing = YES;
}

- (void) stopObserving;
{
    if( self.observing == YES )
    {
        [treeController removeObserver:self forKeyPath:@"selectedObjects" context:self];
        [lastFilterAnaylizer removeObserver:self forKeyPath:@"editIndexSet" context:self];
        [lastFilterAnaylizer release];
    }
    
    self.observing = NO;
}

- (void) startObservingBlockEditor:(StBlock *)inBlock
{
    if( self.observingBlock != inBlock )
    {
        [self stopObservingBlockEditor];
        self.observingBlock = inBlock;
        [self.observingBlock addObserver:self forKeyPath:@"currentEditorView" options:NSKeyValueChangeSetting context:self];
    }
}

- (void) stopObservingBlockEditor
{
    if( self.observingBlock != nil )
    {
        [observingBlock removeObserver:self forKeyPath:@"currentEditorView" context:self];
        self.observingBlock = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"selectedObjects"] || [keyPath isEqualToString:@"currentEditorView"] )
    {
        if( self.selectedBlockLevel1 != nil )
        {
            [self restoreSelection];
        }
        else //if( [change objectForKey:@"new"] != [NSNull null] )
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
    StAnaylizer *theAna = [self representedObject];
    theAna.viewController = nil;

    [[self.editorViewController view] removeFromSuperview];

    self.selectedBlockLevel1 = nil;
    self.selectedBlockLevel2 = nil;
    self.selectedBlockLevel3 = nil;

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
