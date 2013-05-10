//
//  GenericArbitraryGroupBlocker.m
//  Stream
//
//  Created by tim lindner on 5/10/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "GenericArbitraryGroupBlocker.h"
#import "StStream.h"
#import "StBlock.h"
#import "StAnaylizer.h"

@implementation GenericArbitraryGroupBlocker

+ (NSString *)anayliserName
{
    return @"Generic Arbitrary Group Blocker";
}

+ (NSString *)anaylizerKey
{
    return @"GenericArbitraryGroupBlocker";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"GenericArbitraryGroupViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSMutableArray array], @"blockList", nil];
}

+ (void) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
    NSUInteger blockNumber;
    StBlock *newFileBlock;
    
    blockNumber = 0;
    newFileBlock = nil;
    
    while (newFileBlock == nil) {
        newFileBlock = [stream startNewBlockNamed:[NSString stringWithFormat:@"Block %d", blockNumber] owner:[GenericArbitraryGroupBlocker anaylizerKey]];
        blockNumber++;
    }

    NSMutableDictionary *optionsDictionary = anaylizer.optionsDictionary;
    NSMutableDictionary *myOptions = [optionsDictionary objectForKey:[GenericArbitraryGroupBlocker anaylizerKey]];
    NSMutableArray *myArray = [myOptions valueForKey:@"blockList"];
    
    for (namedRange *nr in myArray) {
        NSRange range = [nr.range rangeValue];
        [newFileBlock addDataRange:nr.name start:range.location length:range.length];
    }
}

@end

@implementation namedRange

@synthesize name;
@synthesize range;

+ (id)namedRange: (NSValue *)aRange withName:(NSString*)aName
{
    namedRange *result = [[[namedRange alloc] init] autorelease];
    result.name = aName;
    result.range = aRange;
    
    return result;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self) {
        self.name = [coder decodeObjectForKey:@"namedRangeName"];
        self.range = [coder decodeObjectForKey:@"namedRangeRange"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.name forKey:@"namedRangeName"];
    [encoder encodeObject:self.range forKey:@"namedRangeRange"];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", self.name, self.range];
}

- (void)dealloc
{
    self.name = nil;
    self.range = nil;
    
    [super dealloc];
}

@end