//
//  StBlock.h
//  temp
//
//  Created by tim lindner on 5/7/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "StData.h"

@class StBlock, StStream;

@interface StBlock : StData
{
    NSUInteger dataIndex, attrIndex, depIndex, actualBlockSizeCache;
    StBlock *dataSubBlock, *attrSubBlock, *depSubBlock;
    
}

@property (nonatomic) int64_t offset;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) int64_t length;
@property (nonatomic) BOOL repeat;
@property (nonatomic) int64_t expectedSize;
@property (nonatomic, retain) NSData * checkBytes;
@property (nonatomic, retain) NSDictionary *uiCheckBytes;
@property (nonatomic, retain) NSDictionary *uiData;
@property (nonatomic) BOOL isEdit;
@property (nonatomic) BOOL isFail;
@property (nonatomic) BOOL markForDeletion;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * uiName;
@property (nonatomic, retain) NSString * valueTransformer;
@property (nonatomic, retain) NSOrderedSet *blocks;
@property (nonatomic, retain) StBlock *parentBlock;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) StStream *sourceSubStreamParent;
@property (nonatomic, readonly) NSMutableIndexSet *editSet;
@property (nonatomic, readonly) NSArray *blocksArray;
@property (nonatomic, retain) NSColor *attributeColor;
@property (nonatomic) NSUInteger actualBlockSizeCache;
@property (nonatomic, retain) NSImage *icon;

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name;
- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification: (NSData *)verify;
- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length expectedLength:(NSUInteger)expectedLength;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length expectedLength:(NSUInteger)expectedLength repeat:(BOOL)repeat;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name transformation:(NSString *)transform;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform expectedLength:(NSUInteger)expectedLength repeat:(BOOL)repeat;

- (StStream *)getStream;
- (StBlock *)subBlockNamed:(NSString *)inName;
- (void) checkEdited:(StBlock *)newBlock;
- (void) checkFail:(StBlock *)newBlock;
- (StBlock *)subBlockAtIndex:(NSUInteger)theIndex;
- (BOOL) topLevelBlock;
- (NSData *)getAttributeData;
- (id)getAttributeDatawithUIName:(NSString *)name;
- (NSOrderedSet *)getOrderedSetOfBlocks;
- (BOOL) writeByte:(unsigned char)byte atOffset:(NSUInteger)offset;
- (void) smartSetEdit;
- (void) smartSetFail;
- (void) resetCounters;
- (NSArray *)blocksArray;
- (void)addSubBlocksObject:(StBlock *)value;
- (void)makeMarkForDeletion;
- (NSArray *)recursiveChildBlocks;
- (NSImage *)icon;
- (NSUInteger)actualBlockSize;

@end

@interface StBlock (CoreDataGeneratedAccessors)

- (void)insertObject:(StBlock *)value inBlocksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBlocksAtIndex:(NSUInteger)idx;
- (void)insertBlocks:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBlocksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBlocksAtIndex:(NSUInteger)idx withObject:(StBlock *)value;
- (void)replaceBlocksAtIndexes:(NSIndexSet *)indexes withBlocks:(NSArray *)values;
- (void)addBlocksObject:(StBlock *)value;
- (void)removeBlocksObject:(StBlock *)value;
- (void)addBlocks:(NSOrderedSet *)values;
- (void)removeBlocks:(NSOrderedSet *)values;

- (NSMutableIndexSet *)primitiveEditSet;
- (void)setPrimitiveEditSet:(NSMutableIndexSet *)editSet;

- (NSColor *)primitiveAttributeColor;
- (void)setPrimitiveAttributeColor:(NSColor *)color;

- (NSImage *)primitiveIcon;
- (void)setPrimitiveIcon:(NSImage *)color;

@end

@interface StBlockFormatter : NSFormatter {
@private
}
@property (nonatomic, retain) NSString *mode;

- (NSString *)stringForObjectValue:(id)anObject;
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error;
@end
