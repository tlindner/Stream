//
//  HexFiendAnalyzer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendAnalyzer.h"
#import "HexFiendAnalyzerController.h"
#import "StAnalyzer.h"
#import "HFTextView.h"

@implementation HexFiendAnalyzer

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

- (StAnalyzer *)representedObject
{
    return representedObject;
}

- (void) setRepresentedObject:(StAnalyzer *)inRepresentedObject
{
    representedObject = inRepresentedObject;

    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[HexFiendAnalyzer analyzerKey] withDictionary:[HexFiendAnalyzer defaultOptions]];
    }
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(unsigned char *)byte
{
    NSLog( @"HexFiend Unimplemented: replaceBytesInRange: %@ withByte 0x%x", NSStringFromRange(range), *byte);
}

- (void) analyzeData
{
    StData *ro = [self representedObject];
    self.resultingData = ro.resultingData;
}

- (void)dealloc
{
    self.resultingData = nil;
    
    [super dealloc];
}

+ (NSArray *)analyzerUTIs
{
    return [NSArray arrayWithObject:@"public.data"];
}

+ (NSString *)analyzerName
{
    return @"Hex Editor";
}

+ (NSString *)AnalyzerPopoverAccessoryViewNib
{
    return @"HFAccessoryView";
}

- (Class)viewControllerClass
{
    return [HexFiendAnalyzerController class];
}

+ (NSString *)analyzerKey
{
    return @"HexFiendAnalyzerController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", [NSNumber numberWithBool:YES], @"showOffset", @"Hexadecimal", @"offsetBase",[NSArray arrayWithObjects:@"Hexadecimal", @"Decimal", nil], @"offsetBaseOptions", [NSNumber numberWithBool:YES], @"overWriteMode", nil] autorelease];
}


@end
