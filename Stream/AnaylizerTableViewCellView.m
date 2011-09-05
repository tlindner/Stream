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

@implementation AnaylizerTableViewCellView

@synthesize editorController;
@synthesize newConstraints;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    dragging = NO;
    float newHeight = [[self valueForKeyPath:@"objectValue.anaylizerHeight"] floatValue];
    NSRect ourRect = [self frame];
    ourRect.size.height = newHeight;
    [self setFrame:ourRect];
    self.newConstraints = nil;
}

- (void)awakeFromNib
{
    [self addObserver:self forKeyPath:@"objectValue.currentEditorView" options:NSKeyValueChangeSetting context:nil];
    [self addObserver:self forKeyPath:@"objectValue.collapse" options:NSKeyValueChangeSetting context:nil];
}

- (void)updateConstraints {
    if( newConstraints == nil )
    {
        NSDictionary *views = NSDictionaryOfVariableBindings(_customView, _cgv, dragThumbView);
        self.newConstraints = [[[NSMutableArray alloc] init] autorelease];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[_customView]-0-|" options:0 metrics:nil views:views]];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[_cgv]-0-|" options:0 metrics:nil views:views]];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[dragThumbView]-0-|" options:0 metrics:nil views:views]];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_cgv(==19)]-0-[_customView]-2-[dragThumbView(==6)]-0-|" options:0 metrics:nil views:views]];
        [self removeConstraints:[self constraints]];
        [self addConstraints:newConstraints];
    }
    
    [super updateConstraints];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"objectValue.currentEditorView"])
    {
        // Create sub view editor.
        Class editorViewClass = [[Analyzation sharedInstance] anaylizerClassforName:[change objectForKey:@"new"]];
        
        if( self.editorController != nil )
        {
            //            if( [self.editorSubView class] == editorViewClass )
            //            {
            //                NSLog( @"change, no change editor view" );
            //                return;
            //            }
            
            //teardown existing sub view editor
            [[self.editorController view] removeFromSuperview];
            self.editorController = nil;
        }
        
        
        if (editorViewClass == nil)
            editorViewClass = [HexFiendAnaylizerController class];
        
        //NSLog( @"name: %@, class: %@", [change objectForKey:@"new"], editorViewClass );
        
        NSRect adjustedFrame = [_customView frame];
        adjustedFrame.origin.x = 0;
        adjustedFrame.origin.y = 0;
        self.editorController = [[[editorViewClass alloc] initWithNibName:nil bundle:nil] autorelease];
        [self.editorController setRepresentedObject:self.objectValue];
        [self.editorController loadView];
        [[self.editorController view] setFrame:adjustedFrame];
        
        
        [_customView addSubview:[self.editorController view]];
        
        if( newConstraints != nil )
            [self updateConstraints];
    }
    else if( [keyPath isEqualToString:@"objectValue.collapse"] )
    {
        StAnaylizer *ana = (StAnaylizer *)[self objectValue];

        if( [tlDisclosure intValue] == ana.collapse )
        {
            NSTableView *tv = (NSTableView *)[[self superview] superview];
            
            if( ana.collapse == 1 )
            {
                ana.anaylizerHeight = ana.previousAnaylizerHeight;
                [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
                [_customView setHidden:NO];
             }
            else
            {
                ana.previousAnaylizerHeight = ana.anaylizerHeight;
                ana.anaylizerHeight = 26.0;
                [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
                [_customView setHidden:YES];  
            }
        }
        
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (BOOL)isFlipped {
    return YES;
}

//- (void) mouseDown:(NSEvent *)theEvent
//{
//    NSPoint locationInSelf = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//    NSRect dragThumbFrame = [dragThumbView frame];
//    
//    if( NSPointInRect(locationInSelf, dragThumbFrame) )
//    {
//        dragOffsetIntoGrowBox = NSMakeSize(locationInSelf.x - dragThumbFrame.origin.x, locationInSelf.y - dragThumbFrame.origin.y);
//        dragging = YES;
//    }
//    else
//        [super mouseDown:theEvent];
//}
//
//- (void) mouseDragged:(NSEvent *)theEvent
//{
//    if (dragging)
//    {
//        NSPoint locationInSelf = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//        float distance = locationInSelf.y - dragOffsetIntoGrowBox.height + 6;
//        if( distance < 26 ) distance = 26;
//        [self setValue:[NSNumber numberWithFloat:distance] forKeyPath:@"objectValue.anaylizerHeight"];
//        NSTableView *tv = (NSTableView *)[[self superview] superview];
//        NSAnimationContext *ac = [NSAnimationContext currentContext];
//        [ac setDuration:0.0];
//        [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
//        [_customView layoutSubtreeIfNeeded];
//        
//    } else {
//        [super mouseDragged:theEvent];
//    }
//}
//
//- (void)mouseUp:(NSEvent *)theEvent
//{
//    if (dragging)
//    {
//        dragging = NO;
//    }
//    else
//    {
//        [super mouseUp:theEvent];
//    }
//}

- (void)mouseDown:(NSEvent *)theEvent
{
    float distance;
    BOOL keepOn = YES;
    StAnaylizer *ana = (StAnaylizer *)[self objectValue];
    ana.previousAnaylizerHeight = ana.anaylizerHeight;
    
    while (keepOn)
    {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        NSPoint locationInSelf = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        switch ([theEvent type])
        {
            case NSLeftMouseDragged:
                
                distance = locationInSelf.y - dragOffsetIntoGrowBox.height + 6;
                if( distance < 26.0 )
                {
                    distance = 26.0;
                    [_customView setHidden:YES];  
                    [tlDisclosure setIntValue:0];
                }
                else
                {
                    [_customView setHidden:NO];  
                    [tlDisclosure setIntValue:1];
                }
                
                [self setValue:[NSNumber numberWithFloat:distance] forKeyPath:@"objectValue.anaylizerHeight"];
                NSTableView *tv = (NSTableView *)[[self superview] superview];
                NSAnimationContext *ac = [NSAnimationContext currentContext];
                [ac setDuration:0.0];
                [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
                [_customView layoutSubtreeIfNeeded];
                break;
            case NSLeftMouseUp:
                keepOn = NO;
                break;
            default:
                /* Ignore any other kind of event. */
                break;
        }
        
    };
    
    if( distance <= 26.0 )
        ana.collapse = YES;
    else
        ana.collapse = NO;
    
    return;
}

- (IBAction)collapse:(id)sender
{
    NSButton *triangle = sender;
    StAnaylizer *ana = (StAnaylizer *)[self objectValue];
    NSTableView *tv = (NSTableView *)[[self superview] superview];
    
    if( [triangle intValue] == 1 )
    {
        ana.anaylizerHeight = ana.previousAnaylizerHeight;
        [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
        [_customView setHidden:NO];
        ana.collapse = NO;
    }
    else
    {
        ana.previousAnaylizerHeight = ana.anaylizerHeight;
        ana.anaylizerHeight = 26.0;
        [tv noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[tv rowForView:self]]];
        [_customView setHidden:YES];  
        ana.collapse = YES;
    }
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"objectValue.collapse"];
    [self removeObserver:self forKeyPath:@"objectValue.currentEditorView"];
    
    if( self.editorController != nil )
    {
        [[self.editorController view] removeFromSuperview];
        self.editorController = nil;
    }
    
    self.newConstraints= nil;
    [super dealloc];
}

@end
