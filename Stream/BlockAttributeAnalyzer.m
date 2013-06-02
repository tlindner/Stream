//
//  BlockAttributeAnalyzer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockAttributeAnalyzer.h"
#import "BlockAttributeViewController.h"

@implementation BlockAttributeAnalyzer

@dynamic representedObject;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (StAnalyzer *)representedObject
{
    return representedObject;
}

- (void) setRepresentedObject:(StAnalyzer *)inRepresentedObject
{
    representedObject = inRepresentedObject;
    StAnalyzer *theAna = inRepresentedObject;
    
    if( theAna != nil )
    {
        [theAna addSubOptionsDictionary:[BlockAttributeAnalyzer analyzerKey] withDictionary:[BlockAttributeAnalyzer defaultOptions]];
    }
}

+ (NSArray *)analyzerUTIs
{
    return [NSArray arrayWithObject:@"org.macmess.stream.attribute"];
}

+ (NSString *)analyzerName
{
    return @"Block Attribute View";
}

+ (NSString *)analyzerKey
{
    return @"BlockAttributeViewController";
}

+ (NSString *)AnalyzerPopoverAccessoryViewNib
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
