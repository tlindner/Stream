//
//  AudioAnaScrollView.m
//  Stream
//
//  Created by tim lindner on 8/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AudioAnaScrollView.h"

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
    /* Scale horizontal scrollwheel events, pass up vertical scroll wheel events */
    CGFloat scale = [[self contentView] bounds].size.width / [[self contentView] frame].size.width;
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
