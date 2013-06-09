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
BOOL NilOrEmptyString( NSString *string );

@implementation TLImageWithPopover

@synthesize errorMessage = _errorMessage;
@synthesize errorMessage2 = _errorMessage2;

+ (void)initialize
{
    if ( self == [TLImageWithPopover class] )
    {
        [self exposeBinding:@"errorMessage"];
        [self exposeBinding:@"errorMessage2"];
    }
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self updateHidden];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self updateHidden];
}

- (NSString *)errorMessage
{
    return _errorMessage;
}

- (NSString *)errorMessage2
{
    return _errorMessage2;
}

- (void)setErrorMessage:(NSString *)aString
{
    _errorMessage = aString;
    [self updateHidden];
}

- (void)setErrorMessage2:(NSString *)aString
{
    _errorMessage2 = aString;
    [self updateHidden];
}
   
- (void)updateHidden
{
    if (NilOrEmptyString(self.errorMessage) && NilOrEmptyString(self.errorMessage2)) {
        [self setHidden:YES];
    } else {
        [self setHidden:NO];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSFont *font = [NSFont controlContentFontOfSize:0];
    float width, height, ratio;
    NSString *message;
    
    if (NilOrEmptyString(self.errorMessage) && NilOrEmptyString(self.errorMessage2)) {
        message = @"No Message";
    } else if (!NilOrEmptyString(self.errorMessage) && NilOrEmptyString(self.errorMessage2)) {
        message = self.errorMessage;
    } else if (NilOrEmptyString(self.errorMessage) && !NilOrEmptyString(self.errorMessage2)) {
        message = self.errorMessage2;
    } else {
        message = [NSString stringWithFormat:@"%@\n\n%@", self.errorMessage, self.errorMessage2];
    }

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    NSAttributedString *attributedMessage = [[[NSAttributedString alloc] initWithString:message attributes:attributes] autorelease];
    width = [attributedMessage size].width + 20.0;
    height = heightForStringDrawing(message, font, width);
    
    if (width > 300) {
        for (width = 10; width < 800; width += 10) {
            height = heightForStringDrawing(message, font, width);
            
            ratio = width/height;
            
            if (ratio > 1.61803398875) {
                break;
            }
        }
    }
    
    InsetTextView *errorView = [[InsetTextView alloc] initWithFrame:NSMakeRect(0, 0, width+20, height+20)];
    [errorView setDrawsBackground:NO];
    [errorView setFont:font];
    
    NSMutableParagraphStyle *mutParaStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    NSAttributedString *whiteMessage = [[[NSAttributedString alloc] initWithString:message attributes:[NSDictionary dictionaryWithObjectsAndKeys:mutParaStyle, NSParagraphStyleAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil]] autorelease];

    [errorView insertText:whiteMessage];
    
    NSPoint attachPoint = NSMakePoint(NSMidX([self bounds]), NSMinY([self bounds]));
    attachPoint = [self convertPoint:attachPoint toView:nil];
    
    MAAttachedWindow *attachedWindow = [[MAAttachedWindow alloc] initWithView:errorView attachedToPoint:attachPoint inWindow:[self window] onSide:MAPositionBottom atDistance:-15.0];
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

BOOL NilOrEmptyString( NSString *string )
{
    if (string == nil) return YES;
    if ([string isEqualToString:@""]) return YES;
    
    return NO;
}