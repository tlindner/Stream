//
//  StBlock.m
//  Stream
//
//  Created by tim lindner on 8/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StBlock.h"
#import "StStream.h"


@implementation StBlock
@dynamic anaylizerKind;
@dynamic expectedSize;
@dynamic name;
@dynamic type;
@dynamic offset;
@dynamic length;
@dynamic valueTransformer;
@dynamic uiName;
@dynamic checkBytes;
@dynamic source;
@dynamic index;
@dynamic parentStream;
@dynamic parentBlock;
@dynamic blocks;
@dynamic sourceUTI;

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name
{
    [self addAttributeRange:blockName start:start length:length name:name verification:nil];
}

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify
{
    void *predicate = ^(id obj, BOOL *stop)
    {
        StBlock *test = (StBlock *)obj;
        
        if ([test.name isEqualToString:@"attributes"])
        {
            *stop = YES;
            return YES;
        }
        
        return NO;
    };

    NSSet *attributeBlockSet = [self.blocks objectsPassingTest:predicate];
    NSAssert( [attributeBlockSet count] == 1, @"addAttributeRange: could not find attribute block" );
    StBlock *attributeBlock = [attributeBlockSet anyObject];
    
    StBlock *newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    newBlock.name = [NSString stringWithFormat:@"%d: %@, %d, %d", attrIndex, blockName, start, length];
    newBlock.source = blockName;
    newBlock.uiName = name;
    newBlock.offset = start;
    newBlock.length = length;
    newBlock.index = attrIndex++;
    newBlock.checkBytes = verify;
    [attributeBlock addBlocksObject:newBlock];
//    newBlock.parentStream = nil;
//    newBlock.parentBlock = self;
}

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length
{
    void *predicate = ^(id obj, BOOL *stop)
    {
        StBlock *test = (StBlock *)obj;
        
        if ([test.name isEqualToString:@"data"])
        {
            *stop = YES;
            return YES;
        }
        
        return NO;
    };
    
    NSSet *dataBlockSet = [self.blocks objectsPassingTest:predicate];
    NSAssert( [dataBlockSet count] == 1, @"addDataRange: could not find data block" );
    StBlock *dataBlock = [dataBlockSet anyObject];

    StBlock *newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    newBlock.name = [NSString stringWithFormat:@"%d: %@, %d, %d", dataIndex, blockName, start, length];
    newBlock.source = blockName;
    newBlock.offset = start;
    newBlock.length = length;
    newBlock.index = dataIndex++;
    [dataBlock addBlocksObject:newBlock];
    self.expectedSize += length;
//    newBlock.parentStream = nil;
//    newBlock.parentBlock = self;
}

@end
