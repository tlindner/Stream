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
#import "StAnaylizer.h"

@implementation BlockerDataViewController
@synthesize treeController;
@synthesize observing;
@synthesize observingBlock;
@dynamic managedObjectContext;

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
    [super setRepresentedObject:representedObject];
    
    if( [[representedObject valueForKey:@"optionsDictionary.BlockerDataViewController.initializedOD"] boolValue] == YES )
    {
    }
    else
    {
        Class <BlockerProtocol> class = NSClassFromString([representedObject valueForKey:@"anaylizerKind"]);
        
        if (class != nil )
        {
            StAnaylizer *theAna = representedObject;
            [class makeBlocks:theAna.parentStream];
            [theAna setValue:[NSNumber numberWithBool:YES] forKeyPath:@"optionsDictionary.BlockerDataViewController.initializedOD"];
            NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
            NSArray *sortDescriptors = [NSArray arrayWithObject:nameDescriptor];
            [treeController setSortDescriptors:(NSArray *)sortDescriptors];
            [treeController prepareContent];
            [self startObserving];
        }
        else
            NSLog( @"Could not create class: %@", [representedObject valueForKey:@"anaylizerKind"] );
        
    }
}

- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *result = [(NSPersistentDocument *)[[[[self view] window] windowController] document] managedObjectContext];
    return result;
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
        
        if( [selectedObjects count] > 0 )
        {
            StBlock *theBlock = [selectedObjects objectAtIndex:0];
//            NSRect theFrame = [[self view] frame];
            
            [[[self view] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:theBlock.currentEditorView];
            
            if( anaClass == nil )
                anaClass = [HexFiendAnaylizerController class];
            
//            NSViewController *editorController = [[anaClass alloc] initWithNibName:nil bundle:nil];
//            [editorController setRepresentedObject:theBlock];
//            
//            
//            NSViewController *editorController = [[anaClass alloc] initWithFrame:NSMakeRect(0, 0, theFrame.size.width, theFrame.size.height)];
//            [[self view] addSubview:editorView];
//            [editorView release];
//            
//            [editorView setRepresentedObject:theBlock];
//            [self startObservingBlockEditor:theBlock];
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    [self stopObserving];
    [self stopObservingBlockEditor];
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
