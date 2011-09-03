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
@synthesize editorView;
@synthesize editorViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    
    if( [[[self representedObject] valueForKeyPath:@"optionsDictionary.BlockerDataViewController.initializedOD"] boolValue] == YES )
    {
    }
    else
    {
        Class <BlockerProtocol> blockerClass = NSClassFromString([[self representedObject] valueForKey:@"anaylizerKind"]);
        
        if (blockerClass != nil )
        {
            StAnaylizer *theAna = [self representedObject];
            [blockerClass makeBlocks:theAna.parentStream];
            [theAna setValue:[NSNumber numberWithBool:YES] forKeyPath:@"optionsDictionary.BlockerDataViewController.initializedOD"];

            [treeController setContent:[theAna.parentStream blocksWithKey:[blockerClass anaylizerKey]]];
            [self startObserving];
        }
        else
            NSLog( @"Could not create class: %@", [[self representedObject] valueForKey:@"anaylizerKind"] );
    }
}

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
        NSArray *selectedObjects = [object selectedObjects];
        [self stopObservingBlockEditor];
        
        if( [selectedObjects count] > 0 )
        {
            StBlock *theBlock = [selectedObjects objectAtIndex:0];
            NSRect theFrame = [self.editorView frame];
            
            if( self.editorViewController != nil )
            {
                [[self.editorViewController view] removeFromSuperview];
                self.editorViewController = nil;
            }
             
            Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:theBlock.currentEditorView];
            
            if( anaClass == nil )
                anaClass = [HexFiendAnaylizerController class];
             
            theFrame.origin.y = theFrame.origin.x = 0;
            self.editorViewController = [[[anaClass alloc] initWithNibName:nil bundle:nil] autorelease];
            [self.editorViewController setRepresentedObject:theBlock];
            [self.editorViewController loadView];
            [[self.editorViewController view] setFrame:theFrame];
            [self.editorView addSubview:[self.editorViewController view]];
            [self startObservingBlockEditor:theBlock];
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    [self stopObserving];
    [self stopObservingBlockEditor];
    self.editorViewController = nil;
    [super dealloc];
}
+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.data"];
}

+ (NSString *)anayliserName
{
    return @"Blocker View";
}

/* Used for KVC and KVO in anaylizer options dictionary */
+ (NSString *)anaylizerKey;
{
    return @"BlockerDataViewController";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"BlockerViewAccessory";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"initializedOD", nil] autorelease];
}

-(NSString *)nibName
{
    return @"BlockerDataViewController";
}

@end
