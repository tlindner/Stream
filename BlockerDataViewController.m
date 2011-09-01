//
//  BlockerDataViewController.m
//  Stream
//
//  Created by tim lindner on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerDataViewController.h"
#import "HFAnaylizer.h"
#import "Analyzation.h"

@implementation BlockerDataViewController
@synthesize parentView;
@synthesize treeController;
@synthesize observing;
@synthesize observingBlock;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
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
                anaClass = [HFAnaylizer class];
            
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
@end
