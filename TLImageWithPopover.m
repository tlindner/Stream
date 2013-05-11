//
//  TLImageWithPopover.m
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TLImageWithPopover.h"
#import "MAAttachedWindow.h"

float heightForStringDrawing(NSString *myString, NSFont *myFont, float myWidth);

@implementation TLImageWithPopover

@synthesize delegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSString *message = nil;
    
    if ([delegate respondsToSelector:@selector(representedObject)]) {
        NSObject *ro = [delegate representedObject];
        message = [ro valueForKey:@"errorString"];
    }

    NSFont *font = [NSFont controlContentFontOfSize:0];
    float height = heightForStringDrawing(message, font, 300);
    InsetTextView *errorView = [[InsetTextView alloc] initWithFrame:NSMakeRect(0, 0, 300+20, height+20)];
    [errorView setDrawsBackground:NO];
    [errorView setFont:font];
    
    NSMutableParagraphStyle *mutParaStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    NSAttributedString *whiteMessage = [[NSAttributedString alloc] initWithString:message attributes:[NSDictionary dictionaryWithObjectsAndKeys:mutParaStyle, NSParagraphStyleAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil] ];

    [errorView insertText:whiteMessage];
    
    NSPoint attachPoint = NSMakePoint(NSMidX([self bounds]), NSMaxY([self bounds]));
    attachPoint = [self convertPoint:attachPoint toView:nil];
    NSLog(@"Error popup at: %@: %@", NSStringFromPoint(attachPoint), message);
    
    MAAttachedWindow *attachedWindow = [[MAAttachedWindow alloc] initWithView:errorView attachedToPoint:attachPoint inWindow:[self window] onSide:MAPositionTop atDistance:-15.0];
    [[self window] addChildWindow:attachedWindow ordered:NSWindowAbove];
    
    BOOL keepOn = YES;
    
    while (keepOn)
    {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        
        switch ([theEvent type])
        {
            case NSLeftMouseDragged:
                
                break;
            case NSLeftMouseUp:
                keepOn = NO;
                break;
                
            default:
                break;
        }
    }
    
    [[self window] removeChildWindow:attachedWindow];
    [attachedWindow orderOut:self];
    [attachedWindow release];
    [errorView release];
}

@end

@implementation InsetTextView

- (void)awakeFromNib {
    [super setTextContainerInset:NSMakeSize(10.0f, 10.0f)];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [super setTextContainerInset:NSMakeSize(10.0f, 10.0f)];
    }
    
    return self;
}

- (NSPoint)textContainerOrigin {
    NSPoint origin = [super textContainerOrigin];
    NSPoint newOrigin = NSMakePoint(origin.x + 5.0f, origin.y);
    return newOrigin;
}

@end

float heightForStringDrawing(NSString *myString, NSFont *myFont, float myWidth)
{
    NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString:myString] autorelease];
    NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize: NSMakeSize(myWidth, FLT_MAX)] autorelease];
    NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease]; 
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    [textStorage addAttribute:NSFontAttributeName value:myFont range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:0.0];
    
    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager usedRectForTextContainer:textContainer].size.height;
}
