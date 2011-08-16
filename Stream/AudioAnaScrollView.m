//
//  AudioAnaScrollView.m
//  Stream
//
//  Created by tim lindner on 8/8/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "AudioAnaScrollView.h"
#import "AudioAnaylizer.h"

@implementation AudioAnaScrollView

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    CGFloat scale = [[self contentView] bounds].size.width / [[self contentView] frame].size.width;
    NSUInteger flags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    if( flags == NSAlternateKeyMask )
    {
        if ([theEvent respondsToSelector:@selector(hasPreciseScrollingDeltas)] && [theEvent hasPreciseScrollingDeltas])
        {
            [(AudioAnaylizer *)[self superview] deltaSlider:round(theEvent.scrollingDeltaY * scale)*-1.0 fromPoint:theEvent.locationInWindow];
        }
        else
        {
            [(AudioAnaylizer *)[self superview] deltaSlider:theEvent.deltaY * scale * -1.0 fromPoint:theEvent.locationInWindow];
        }
        
        return;
    }
    
    /* Scale horizontal scrollwheel events, pass up vertical scroll wheel events */
    NSPoint currentScrollPosition=[[self contentView] bounds].origin;

    CGFloat deltaX, deltaY;
    
    if ([theEvent respondsToSelector:@selector(hasPreciseScrollingDeltas)] && [theEvent hasPreciseScrollingDeltas])
    {
        deltaX = round(theEvent.scrollingDeltaX * scale);
        deltaY = round(theEvent.scrollingDeltaY * scale);
    }
    else
    {
        deltaX = theEvent.deltaX * scale;
        deltaY = theEvent.deltaY * scale;
    }
    
    currentScrollPosition.x -= deltaX;
    currentScrollPosition.y += deltaY;

    [[self documentView] scrollPoint:currentScrollPosition];
}

@end
