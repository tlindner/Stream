//
//  HFAnaylizer.m
//  Stream
//
//  Created by tim lindner on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HFAnaylizer.h"
#import "StAnaylizer.h"
#import "StBlock.h"

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
    
    if( [self.objectValue isKindOfClass:[StAnaylizer class]] )
    {
        StAnaylizer *object = self.objectValue;
        [hexView setData:[object.parentStream valueForKey:@"bytesCache"]];      
        
        if( [[object valueForKey:@"initializedOD"] boolValue] == YES )
        {
        }
        else
        {
        }
    }
    else if( [self.objectValue isKindOfClass:[StBlock class]] )
    {
        StBlock *theBlock = self.objectValue;
        NSData *theData = [theBlock getData];
        [hexView setData:theData];
    }
    else if( [self.objectValue isKindOfClass:[NSData class]] )
    {
        NSData *theData = self.objectValue;
        [hexView setData:theData];
    }
    else
        NSLog( @"HFAnaylizer: Unknown type of represented object" );
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
