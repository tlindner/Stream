//
//  HFAnaylizer.m
//  Stream
//
//  Created by tim lindner on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HFAnaylizer.h"

@implementation HFAnaylizer

@synthesize objectValue;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setAutoresizesSubviews:YES];
        [self setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];

        hexView = [[HFTextView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:hexView];
        [hexView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
        [hexView release];
    }
    
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

- (void)setRepresentedObject:(id)representedObject
{
    self.objectValue = representedObject;
    
    [hexView setData:[objectValue.parentStream valueForKey:@"bytesCache"]];      

    if( [[self.objectValue valueForKey:@"initializedOD"] boolValue] == YES )
    {
    }
    else
    {
    }
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.data"];
}

+ (NSString *)anayliserName
{
    return @"Hex Editor";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"HFAccessoryView";
}

+ (NSString *)anaylizerKey;
{
    return @"HFHexEditor";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"showOffset", nil] autorelease];
}


@end
