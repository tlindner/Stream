//
//  DragRegionView.m
//  Stream
//
//  Created by tim lindner on 8/2/11.
//  Copyright 2011 org.macmess. All rights reserved.
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
    NSGradient* aGradient = [[[NSGradient alloc]
                              initWithStartingColor:[NSColor grayColor]
                              endingColor:[NSColor lightGrayColor]] autorelease];
    [aGradient drawInRect:[self bounds] angle:90.0];
}

@end
