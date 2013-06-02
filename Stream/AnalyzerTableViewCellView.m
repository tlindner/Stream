//
//  AnalyzerTableViewCellView.m
//  Stream
//
//  Created by tim lindner on 7/30/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "AnalyzerTableViewCellView.h"
#import "HexFiendAnalyzerController.h"
#import "Analyzation.h"
#import "StAnalyzer.h"
#import "MyDocument.h"

#define MINIMUM_HEIGHT 26.0

@implementation AnalyzerTableViewCellView

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
    [self addObserver:self forKeyPath:@"objectValue.paneExpanded" options:NSKeyValueChangeSetting context:nil];
    [self addObserver:self forKeyPath:@"objectValue.analyzerHeight" options:NSKeyValueChangeSetting context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"objectValue.currentEditorView"])
    {
        id newAnalyzer, oldAnalyzer;
        newAnalyzer = [change objectForKey:@"new"];
        oldAnalyzer = [change objectForKey:@"old"];
        Boolean tearDown = NO, buildNew = NO;
        StAnalyzer *theAna = [self objectValue];
//        NSObject *analyzerObject = [theAna analyzerObject];
//        Class analyzerClass = [analyzerObject viewController];
//        Class currentClass = [self.editorController class];
        
        NSLog( @"self: %p, new: %@, old:%@", self, newAnalyzer, oldAnalyzer );
//        NSLog( @"self: %p, analyzer class: %@, current class: %@\r", self, NSStringFromClass(analyzerClass), NSStringFromClass(currentClass) );

        if ([[newAnalyzer class] isSubclassOfClass:[NSNull class]])
        {
            tearDown = YES;
        }
        else if (![newAnalyzer isEqualToString:oldAnalyzer])
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
            [[[theAna managedObjectContext] undoManager] setActionName:[NSString stringWithFormat:@"Set Stream Analyzer “%@”", [theAna valueForKey:@"currentEditorView"]]];

            NSObject *analyzerObject = [theAna analyzerObject];

            NSRect adjustedFrame = [_customView frame];
            adjustedFrame.origin.x = 0;
            adjustedFrame.origin.y = 0;
            self.editorController = [[[[analyzerObject viewController] alloc] initWithNibName:nil bundle:nil] autorelease];
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
    else if( [keyPath isEqualToString:@"objectValue.paneExpanded"] )
    {
        if( ignoreEvent == NO )
        {
            NSTableView *tv = (NSTableView *)[[self superview] superview];
            [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
        }
    }
    else if( [keyPath isEqualToString:@"objectValue.analyzerHeight"] )
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
    StAnalyzer *ana = (StAnalyzer *)[self objectValue];
    float startAnalyzerHeight = ana.analyzerHeight;
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
                    ana.paneExpanded = NO;
                }
                else
                    ana.paneExpanded = YES;
                
                ana.analyzerHeight = distance;
                NSTableView *tv = (NSTableView *)[[self superview] superview];
                NSAnimationContext *ac = [NSAnimationContext currentContext];
                [ac setDuration:0.0];
                [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
                [_customView layoutSubtreeIfNeeded];
                break;
                
            case NSLeftMouseUp:
                
                ignoreEvent = YES;
                
                if( startAnalyzerHeight == ana.analyzerHeight )
                {
                    [[[self objectValue] managedObjectContext] processPendingChanges];
                }
                else
                {
                    if( distance <= MINIMUM_HEIGHT )
                    {
                        ana.paneExpanded = NO;
                        ana.analyzerHeight = startAnalyzerHeight;
                        [[[[self objectValue] managedObjectContext] undoManager] setActionName:@"paneExpanded"];
                    }
                    else
                    {
                        ana.paneExpanded = YES;
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
    NSLog( @"self: %p, AnalyzerTableViewCellView: viewWillMoveToSuperview: %@", self, newSuperview );
    [super viewWillMoveToSuperview:newSuperview];
}

- (IBAction)removeAnalyzer:(id)sender
{
    MyDocument *ourPerstantDocument = [[[self window] windowController] document];
    [ourPerstantDocument removeAnalyzer:[self objectValue]];
}

-(void)dealloc
{
    NSLog( @"self: %p, AnalyzerTableViewCellView: dealloc", self );
    
    [self removeObserver:self forKeyPath:@"objectValue.paneExpanded"];
    [self removeObserver:self forKeyPath:@"objectValue.currentEditorView"];
    [self removeObserver:self forKeyPath:@"objectValue.analyzerHeight"];
    
    if( self.editorController != nil )
    {
        [[self.editorController view] removeFromSuperview];
        self.editorController = nil;
    }
    
    [super dealloc];
}

@end
