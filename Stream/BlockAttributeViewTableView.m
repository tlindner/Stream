//
//  BlockAttributeViewTableView.m
//  Stream
//
//  Created by tim lindner on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockAttributeViewTableView.h"

@implementation BlockAttributeViewTableView

- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect
{
    NSColor *color = [(NSObject *)[self delegate] tableView:self backgroundColorForRow:row];
    
    // ignore any background color if the row is selected
    if (color && [self isRowSelected:row] == NO)
    {
        [NSGraphicsContext saveGraphicsState];
        NSRectClip(clipRect);
        NSRect rowRect = [self rectOfRow:row];

        // draw over the alternating row color
        [[NSColor whiteColor] setFill];
        NSRectFill(NSIntersectionRect(rowRect, clipRect));

        // draw with rounded end caps
        CGFloat radius = NSHeight(rowRect) / 2.0;
        NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rowRect, 1.0, 0.0) xRadius:radius yRadius:radius];
        [color setFill];
        [p fill];
        [NSGraphicsContext restoreGraphicsState];
    }

    // draw cells on top of the new row background
    [super drawRow:row clipRect:clipRect];
}

@end
