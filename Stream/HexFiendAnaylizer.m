//
//  HexFiendAnaylizer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendAnaylizer.h"
#import "HexFiendAnaylizerController.h"

@implementation HexFiendAnaylizer

@dynamic representedObject;

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
    StAnaylizer *theAna = inRepresentedObject;
    [theAna addSubOptionsDictionary:[HexFiendAnaylizer anaylizerKey] withDictionary:[HexFiendAnaylizer defaultOptions]];
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

- (Class)viewController
{
    return [HexFiendAnaylizerController class];
}

+ (NSString *)anaylizerKey;
{
    return @"HexFiendAnaylizerController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"showOffset", @"Hexadecimal", @"offsetBase",[NSArray arrayWithObjects:@"Hexadecimal", @"Decimal", nil], @"offsetBaseOptions", [NSNumber numberWithBool:YES], @"overWriteMode", nil] autorelease];
}


@end
