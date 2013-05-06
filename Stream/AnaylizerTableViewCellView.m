//
//  AnaylizerTableViewCellView.m
//  Stream
//
//  Created by tim lindner on 7/30/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "AnaylizerTableViewCellView.h"
#import "HexFiendAnaylizerController.h"
#import "Analyzation.h"
#import "StAnaylizer.h"
#import "MyDocument.h"

#define MINIMUM_HEIGHT 26.0

@implementation AnaylizerTableViewCellView

@synthesize editorController;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self addObserver:self forKeyPath:@"objectValue.currentEditorView" options:NSKeyValueChangeSetting | NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"objectValue.collapse" options:NSKeyValueChangeSetting context:nil];
    [self addObserver:self forKeyPath:@"objectValue.anaylizerHeight" options:NSKeyValueChangeSetting context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"objectValue.currentEditorView"])
    {
        id newAnaylizer, oldAnaylizer;
        newAnaylizer = [change objectForKey:@"new"];
        oldAnaylizer = [change objectForKey:@"old"];
        Boolean tearDown = NO, buildNew = NO;
        StAnaylizer *theAna = [self objectValue];
//        NSObject *anaylizerObject = [theAna anaylizerObject];
//        Class anaylizerClass = [anaylizerObject viewController];
//        Class currentClass = [self.editorController class];
        
        NSLog( @"self: %p, new: %@, old:%@", self, newAnaylizer, oldAnaylizer );
//        NSLog( @"self: %p, anaylizer class: %@, current class: %@\r", self, NSStringFromClass(anaylizerClass), NSStringFromClass(currentClass) );

        if ([[newAnaylizer class] isSubclassOfClass:[NSNull class]])
        {
            tearDown = YES;
        }
        else if (![newAnaylizer isEqualToString:oldAnaylizer])
        {
            tearDown = YES;
            buildNew = YES;
        }

        if (tearDown) {
            [[self.editorController view] removeFromSuperview];
            [self.editorController setRepresentedObject:nil];
            self.editorController = nil;
        }

        if (buildNew) {
            [[[theAna managedObjectContext] undoManager] setActionName:[NSString stringWithFormat:@"Set Stream Anaylizer “%@”", [theAna valueForKey:@"currentEditorView"]]];

            NSObject *anaylizerObject = [theAna anaylizerObject];

            NSRect adjustedFrame = [_customView frame];
            adjustedFrame.origin.x = 0;
            adjustedFrame.origin.y = 0;
            self.editorController = [[[[anaylizerObject viewController] alloc] initWithNibName:nil bundle:nil] autorelease];
//            theAna.viewController = self.editorController;
            [self.editorController setRepresentedObject:self.objectValue];
            [self.editorController loadView];
            [[self.editorController view] setFrame:adjustedFrame];
            [_customView addSubview:[self.editorController view]];

            //ignoreEvent = YES;

            NSTableView *tv = (NSTableView *)[[self superview] superview];
            [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];

        }
    }
    else if( [keyPath isEqualToString:@"objectValue.collapse"] )
    {
        if( ignoreEvent == NO )
        {
            NSTableView *tv = (NSTableView *)[[self superview] superview];
            [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
        }
    }
    else if( [keyPath isEqualToString:@"objectValue.anaylizerHeight"] )
    {
        if( ignoreEvent == NO)
        {
            NSTableView *tv = (NSTableView *)[[self superview] superview];
            [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    CGFloat start, distance = 0, offset;
    BOOL keepOn = YES;
    StAnaylizer *ana = (StAnaylizer *)[self objectValue];
    float startAnaylizerHeight = ana.anaylizerHeight;
    start = [theEvent locationInWindow].y;
    offset = [self bounds].size.height;
    
    while (keepOn)
    {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        
        switch ([theEvent type])
        {
            case NSLeftMouseDragged:
                
                ignoreEvent = YES;
                distance = start - [theEvent locationInWindow].y;
                distance += offset;
                
                if( distance < MINIMUM_HEIGHT )
                {
                    distance = MINIMUM_HEIGHT;
                    ana.collapse = NO;
                }
                else
                    ana.collapse = YES;
                
                ana.anaylizerHeight = distance;
                NSTableView *tv = (NSTableView *)[[self superview] superview];
                NSAnimationContext *ac = [NSAnimationContext currentContext];
                [ac setDuration:0.0];
                [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
                [_customView layoutSubtreeIfNeeded];
                break;
                
            case NSLeftMouseUp:
                
                ignoreEvent = YES;
                
                if( startAnaylizerHeight == ana.anaylizerHeight )
                {
                    [[[self objectValue] managedObjectContext] processPendingChanges];
                }
                else
                {
                    if( distance <= MINIMUM_HEIGHT )
                    {
                        ana.collapse = NO;
                        ana.anaylizerHeight = startAnaylizerHeight;
                        [[[[self objectValue] managedObjectContext] undoManager] setActionName:@"Collapse"];
                    }
                    else
                    {
                        ana.collapse = YES;
                        [[[[self objectValue] managedObjectContext] undoManager] setActionName:@"Set Height"];
                    }
                }
                
                keepOn = NO;
                ignoreEvent = NO;
                break;
                
            default:
                /* Ignore any other kind of event. */
                break;
        }
    }
    
}

//- (void) viewWillMoveToSuperview:(NSView *)newSuperview
//{
//    if( newSuperview == nil )
//    {
//        [editorController setRepresentedObject:nil];
//    }
//}
//

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    NSLog( @"self: %p, AnaylizerTableViewCellView: viewWillMoveToSuperview: %@", self, newSuperview );
    [super viewWillMoveToSuperview:newSuperview];
}

- (IBAction)removeAnaylizer:(id)sender
{
    MyDocument *ourPerstantDocument = [[[self window] windowController] document];
    [ourPerstantDocument removeAnaylizer:[self objectValue]];
}

-(void)dealloc
{
    NSLog( @"self: %p, AnaylizerTableViewCellView: dealloc", self );
    
    [self removeObserver:self forKeyPath:@"objectValue.collapse"];
    [self removeObserver:self forKeyPath:@"objectValue.currentEditorView"];
    [self removeObserver:self forKeyPath:@"objectValue.anaylizerHeight"];
    
    if( self.editorController != nil )
    {
        [[self.editorController view] removeFromSuperview];
        self.editorController = nil;
    }
    
    [super dealloc];
}

@end
