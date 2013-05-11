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

+ (NSString *)blockerName
{
    return @"Generic Arbitrary Group Blocker";
}

+ (NSString *)blockerKey
{
    return @"GenericArbitraryGroupBlocker";
}

+ (NSString *)blockerPopoverAccessoryViewNib
{
    return @"GenericArbitraryGroupViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSMutableArray array], @"blockList", nil] autorelease];
}

+(NSString *)blockerGroup
{
    return @"Utility";
}

- (NSString *) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
    StBlock *newFileBlock;

    newFileBlock = [stream startNewBlockNamed:@"Arbitrary Block" owner:[GenericArbitraryGroupBlocker blockerKey]];
    
    if (newFileBlock != nil) {
        NSMutableDictionary *optionsDictionary = anaylizer.optionsDictionary;
        NSMutableDictionary *myOptions = [optionsDictionary objectForKey:[GenericArbitraryGroupBlocker blockerKey]];
        NSMutableArray *myArray = [myOptions valueForKey:@"blockList"];
        
        for (namedRange *nr in myArray) {
            NSRange range = [nr.range rangeValue];
            [newFileBlock addDataRange:nr.name start:range.location length:range.length];
        }
    }
    
    return @"";
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
    NSRange aRange = [self.range rangeValue];
    return [NSString stringWithFormat:@"%@: %d, %d", self.name, aRange.location, aRange.length];
}

- (void)dealloc
{
    self.name = nil;
    self.range = nil;
    
    [super dealloc];
}

@end
