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

    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[HexFiendAnaylizer anaylizerKey] withDictionary:[HexFiendAnaylizer defaultOptions]];
    }
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(unsigned char *)byte
{
    NSLog( @"HexFiend Unimplemented: replaceBytesInRange: %@ withByte 0x%x", NSStringFromRange(range), *byte);
}

- (void) anaylizeData
{
    if( [[self representedObject] isKindOfClass:[StAnaylizer class]] )
    {
        StAnaylizer *object = [self representedObject];
        self.resultingData = object.sourceData;
    }
    else if( [[self representedObject] isKindOfClass:[StBlock class]] )
    {
        StBlock *theBlock = (StBlock *)[self representedObject];
        self.resultingData = [theBlock resultingData];
    }
    else if( [[self representedObject] isKindOfClass:[NSData class]] )
    {
        self.resultingData = (NSData *)[self representedObject];
    }
    else
        NSLog( @"HexFiendAnaylizer: Unknown type of represented object" );
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
