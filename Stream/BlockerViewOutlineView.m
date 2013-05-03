//
//  BlockerViewOutlineView.m
//  Stream
//
//  Created by tim lindner on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerViewOutlineView.h"
#import "StBlock.h"

@implementation BlockerViewOutlineView

- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect
{
    NSColor *color = [(NSObject *)[self delegate] tableView:self backgroundColorForRow:row];
    
    // ignore any background color if the row is selected
    if (color) // && [self isRowSelected:row] == NO)
    {
        [NSGraphicsContext saveGraphicsState];
        NSRectClip(clipRect);
        NSRect rowRect = [self rectOfRow:row];
        
        // draw over the alternating row color
        [[NSColor whiteColor] setFill];
        NSRectFill(NSIntersectionRect(rowRect, clipRect));
        
        // draw with rounded end caps
        CGFloat radius = NSHeight(rowRect) / 2.0;
        
        // Draw circle over disclosure triangle if selected
        if( [self isRowSelected:row] == YES )
        {
            rowRect.size.width = 20;
            rowRect.origin.x += [self levelForRow:row] * 18;
        }
        
        rowRect.size.height--;
        
        NSBezierPath *p = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rowRect, 1.0, 0.0) xRadius:radius yRadius:radius];
        [color setFill];
        [p fill];
        [NSGraphicsContext restoreGraphicsState];
    }
    
    // draw cells on top of the new row background
    [super drawRow:row clipRect:clipRect];
}

- (IBAction)makeSubStream:(id)sender
{
    #pragma unused(sender)
    [[self nextResponder] tryToPerform:@selector(makeSubStream:) with:[(NSObject *)[self delegate] observingBlock]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(makeSubStream:)) {
        StBlock *observingBlock = [(NSObject *)[self delegate] observingBlock];
        if (observingBlock != nil) {
            return [observingBlock topLevelBlock];
        }
    }
    
    return [super validateMenuItem:menuItem];
}

@end
