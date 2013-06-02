//
//  DragRegionView.m
//  Stream
//
//  Created by tim lindner on 8/2/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "DragRegionView.h"
#import "AnalyzerListViewItem.h"
#import "StAnalyzer.h"

#define MINIMUM_HEIGHT 26.0

@implementation DragRegionView

@synthesize viewOwner;
@synthesize doingLiveResize;

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
    StAnalyzer *ana = [viewOwner representedObject];
    BOOL keepOn = YES;
    float startAnalyzerHeight = ana.analyzerHeight;
    BOOL startPaneExpanded = ana.paneExpanded;
    start = [theEvent locationInWindow].y;
    offset = [[self superview] bounds].size.height;
    
    [viewOwner setLiveResize:YES];
    self.doingLiveResize = YES;
    
    while (keepOn)
    {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        
        switch ([theEvent type])
        {
            case NSLeftMouseDragged:
                
//                ignoreEvent = YES;
                distance = start - [theEvent locationInWindow].y;
                distance += offset;
                
                if (distance <= (MINIMUM_HEIGHT + 80) && retainView == nil) {
                    [self swapOut: [[customView subviews] objectAtIndex:0]];
                }
                
                if (distance > (MINIMUM_HEIGHT + 80) && retainView != nil) {
                    [self swapIn];
                }
                
                if( distance < MINIMUM_HEIGHT )
                {
                    distance = MINIMUM_HEIGHT;
                }
                
                ana.analyzerHeight = distance;
                [viewOwner noteViewHeightChanged];
                break;
                
            case NSLeftMouseUp:
                
//                ignoreEvent = YES;
                
                if( startAnalyzerHeight == ana.analyzerHeight )
                {
                }
                else
                {
                    if( distance <= MINIMUM_HEIGHT+ 80 )
                    {
                        if( startPaneExpanded == YES ) ana.paneExpanded = NO;
                        ana.analyzerHeight = startAnalyzerHeight;
                    }
                    else
                    {
                        if( startPaneExpanded == NO ) ana.paneExpanded = YES;
                    }

                    self.doingLiveResize = NO;
                    [viewOwner noteViewHeightChanged];
                }
                
                keepOn = NO;
//                ignoreEvent = NO;
                self.doingLiveResize = NO;
               
                break;
                
            default:
                /* Ignore any other kind of event. */
                break;
        }
    }
    
    [viewOwner setLiveResize:NO];
}

- (void)swapOut:(NSView *)theView
{
    retainView = [theView retain];
    NSSize mySize = retainView.bounds.size;
    NSSize imgSize = NSMakeSize(mySize.width, mySize.height);
    
    NSBitmapImageRep *bmp = [retainView bitmapImageRepForCachingDisplayInRect:[retainView bounds]];
    [bmp setSize:imgSize];
    [retainView cacheDisplayInRect:[retainView bounds] toBitmapImageRep:bmp];
    
    NSArray *theSubViews = [customView subviews];
    if (theSubViews != nil && [theSubViews count] > 0) {
        [[theSubViews objectAtIndex:0] removeFromSuperview];
    }
    
    NSImage *image = [[[NSImage alloc] initWithSize:imgSize] autorelease];
    [image addRepresentation:bmp];
    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:[customView bounds]] autorelease];
    [imageView setImage:image];
    [customView addSubview:imageView];    
}

- (void)swapIn
{
    if ([[customView subviews] count] > 0) {
        NSImageView *imageView = [[customView subviews] objectAtIndex:0];
        [imageView removeFromSuperview];
        [retainView setFrameSize:[customView frame].size];
        [customView addSubview:retainView];
        [retainView release];
        retainView = nil;
    }
}

- (void)setCustomSubView:(NSView *)theView paneExpanded:(BOOL)paneExpanded
{
    if (paneExpanded) {
        if (theView == nil) {
            [self swapIn];
        }
        else
            [customView addSubview:theView];
    }
    else {
        if (theView == nil) {
            theView = [[customView subviews] objectAtIndex:0];
        }

        [self swapOut:theView];
    }
}

@end
