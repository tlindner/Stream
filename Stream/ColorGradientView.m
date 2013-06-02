//
//  MyClass.m
//  Stream
//
//  Created by tim lindner on 7/28/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "ColorGradientView.h"
#import "BlockerDataViewController.h"
#import "Analyzation.h"
#import "StAnalyzer.h"
#import "StBlock.h"
#import "AnalyzerListViewItem.h"
#import "DragRegionView.h"


@implementation ColorGradientView

// Automatically create accessor methods
@synthesize startingColor;
@synthesize endingColor;
@synthesize angle;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        self.startingColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
        self.endingColor = nil;
        [self setAngle:270];
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.startingColor = [NSColor colorWithCalibratedRed:0.92f green:0.93f blue:0.98f alpha:1.0f];
    self.endingColor = [NSColor colorWithCalibratedRed:0.74f green:0.76f blue:0.83f alpha:1.0f];
    [self setAngle:270];
    [super awakeFromNib];
}

- (BOOL)isOpaque
{
    return true;
}

- (void)drawRect:(NSRect)rect
{
    if (endingColor == nil || [startingColor isEqual:endingColor])
    {
        // Fill view with a standard background color
        [startingColor set];
        NSRectFill(rect);
    }
    else
    {
        // Fill view with a top-down gradient
        // from startingColor to endingColor
        NSGradient* aGradient = [[[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor] autorelease];
        [aGradient drawInRect:[self bounds] angle:angle];
    }
}

- (void)dealloc
{
    self.startingColor = nil;
    self.endingColor = nil;
    [super dealloc];
}

@end

