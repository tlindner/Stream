//
//  StBlock.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StBlock.h"
#import "StRange.h"

@implementation StBlock

@dynamic anaylizerKind;
@dynamic expectedSize;
@dynamic name;
@dynamic attributeRanges;
@dynamic dataRanges;
@dynamic dependantRanges;
@dynamic parent;

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name
{
    [self addAttributeRange:blockName start:start length:length name:name verification:nil];
}

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify
{
    StRange *newRange = [NSEntityDescription insertNewObjectForEntityForName:@"StRange" inManagedObjectContext:self.managedObjectContext];
    newRange.name = blockName;
    newRange.uiName = name;
    newRange.offset = start;
    newRange.length = length;
    newRange.checkbytes = verify;
    [self.attributeRanges addObject:newRange];
}

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length
{
    StRange *newRange = [NSEntityDescription insertNewObjectForEntityForName:@"StRange" inManagedObjectContext:self.managedObjectContext];
    newRange.name = blockName;
    newRange.offset = start;
    newRange.length = length;
    [self.dataRanges addObject:newRange];    
}

@end
