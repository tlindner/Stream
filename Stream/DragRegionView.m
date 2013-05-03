//
//  DragRegionView.m
//  Stream
//
//  Created by tim lindner on 8/2/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "DragRegionView.h"
#import "AnaylizerListViewItem.h"
#import "StAnaylizer.h"

#define MINIMUM_HEIGHT 26.0

@implementation DragRegionView

@synthesize viewOwner;

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}

- (void)drawRect:(NSRect)dirtyRect
{
    #pragma unused(dirtyRect)
    NSGradient* aGradient = [[[NSGradient alloc]
                              initWithStartingColor:[NSColor grayColor]
                              endingColor:[NSColor lightGrayColor]] autorelease];
    [aGradient drawInRect:[self bounds] angle:90.0];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    CGFloat start, distance = 0, offset;
    StAnaylizer *ana = [viewOwner representedObject];
    BOOL keepOn = YES;
    float startAnaylizerHeight = ana.anaylizerHeight;
    BOOL startCollaspe = ana.collapse;
    start = [theEvent locationInWindow].y;
    offset = [[self superview] bounds].size.height;
    
    [viewOwner setLiveResize:YES];
    
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
//                    ana.collapse = NO;
                }
                else {
//                    ana.collapse = YES;
                }
                
                ana.anaylizerHeight = distance;
                [viewOwner noteViewHeightChanged];
                break;
                
            case NSLeftMouseUp:
                
                ignoreEvent = YES;
                
                if( startAnaylizerHeight == ana.anaylizerHeight )
                {
                }
                else
                {
                    if( distance <= MINIMUM_HEIGHT )
                    {
                        if( startCollaspe == YES ) ana.collapse = NO;
                        ana.anaylizerHeight = startAnaylizerHeight;
                    }
                    else
                    {
                        if( startCollaspe == NO ) ana.collapse = YES;
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
    
    [viewOwner setLiveResize:NO];
}

@end
