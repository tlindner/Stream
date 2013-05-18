//
//  HexFiendAnaylizer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendAnaylizer.h"
#import "HexFiendAnaylizerController.h"
#import "StAnaylizer.h"
#import "HFTextView.h"

@implementation HexFiendAnaylizer

@dynamic representedObject;
@synthesize resultingData;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (StAnaylizer *)representedObject
{
    return representedObject;
}

- (void) setRepresentedObject:(StAnaylizer *)inRepresentedObject
{
    representedObject = inRepresentedObject;
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(unsigned char *)byte
{
    NSLog( @"HexFiend Unimplemented: replaceBytesInRange: %@ withByte 0x%x", NSStringFromRange(range), *byte);
}

- (NSData *)anaylizeData:(NSData *)data
{
    self.resultingData = data;
    return data;
}

- (void)dealloc
{
    self.resultingData = nil;
    
    [super dealloc];
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

- (Class)viewControllerClass
{
    return [HexFiendAnaylizerController class];
}

+ (NSString *)anaylizerKey
{
    return @"HexFiendAnaylizerController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", [NSNumber numberWithBool:YES], @"showOffset", @"Hexadecimal", @"offsetBase",[NSArray arrayWithObjects:@"Hexadecimal", @"Decimal", nil], @"offsetBaseOptions", [NSNumber numberWithBool:YES], @"overWriteMode", nil] autorelease];
}


@end
