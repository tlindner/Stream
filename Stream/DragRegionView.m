//
//  DragRegionView.m
//  Stream
//
//  Created by tim lindner on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DragRegionView.h"

@implementation DragRegionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
    [[NSColor keyboardFocusIndicatorColor] set];
    NSRectFill(bounds);
}

@end
