//
//  BlockAttributeAnaylizer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockAttributeAnaylizer.h"
#import "BlockAttributeViewController.h"

@implementation BlockAttributeAnaylizer

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
    
    if( theAna != nil )
    {
        [theAna addSubOptionsDictionary:[BlockAttributeAnaylizer anaylizerKey] withDictionary:[BlockAttributeAnaylizer defaultOptions]];
    }
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"org.macmess.stream.attribute"];
}

+ (NSString *)anayliserName
{
    return @"Block Attribute View";
}

+ (NSString *)anaylizerKey
{
    return @"BlockAttributeViewController";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"BlockAttributeViewAccessory";
}

- (Class)viewControllerClass
{
    return [BlockAttributeViewController class];
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Hexadecimal", @"numericDisplay", [NSArray arrayWithObjects:@"Hexadecimal", @"Decimal", nil], @"numericDisplayOptions", nil] autorelease];
}

@end
