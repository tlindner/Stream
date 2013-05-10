//
//  StStream.h
//  temp
//
//  Created by tim lindner on 5/8/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StAnaylizer, StBlock, StStream;

@interface StStream : NSManagedObject

{
    BOOL regeneratingBlocks;
}

@property (nonatomic) float customSortOrder;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic) NSTimeInterval modificationDateofURL;
@property (nonatomic) BOOL regeneratingBlocks;
@property (nonatomic, retain) NSURL * sourceURL;
@property (nonatomic, retain) NSString * sourceUTI;
@property (nonatomic, retain) NSString * streamTransform;
@property (nonatomic, retain) NSMutableDictionary * topLevelBlocks;
@property (nonatomic, retain) NSOrderedSet *anaylizers;
@property (nonatomic, retain) NSSet *blocks;
@property (nonatomic, retain) NSSet *childStreams;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) StBlock *sourceBlock;

- (NSData *)dataOfTopLevelBlockNamed:(NSString *)name;
- (StBlock *)topLevelBlockNamed:(NSString *)theName;
- (StBlock *)startNewBlockNamed:(NSString *)name owner:(NSString *)owner;
- (StBlock *)makeNewBlockNamed:(NSString *)name owner:(NSString *)owner;
- (StAnaylizer *)lastFilterAnayliser;
- (StAnaylizer *)previousAnayliser:(StAnaylizer *)inAna;
- (NSArray *)blocksWithAnaylizerKey:(NSString *)key;
- (void)setBlock:(StBlock *)theBlock withData:(NSData *)theData;
- (void) setBlock:(StBlock *)theBlock withData:(NSData *)theData inRange:(NSRange)range;
- (void)regenerateAllBlocks;
- (void) markBlocksForDeletion;
- (void) deleteBlocksMarkedForDeletion;
- (BOOL)isBlockEdited:(NSString *)blockName;
- (BOOL)isBlockFailed:(NSString *)blockName;
@end

@interface StStream (CoreDataGeneratedAccessors)

- (void)insertObject:(StAnaylizer *)value inAnaylizersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAnaylizersAtIndex:(NSUInteger)idx;
- (void)insertAnaylizers:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAnaylizersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAnaylizersAtIndex:(NSUInteger)idx withObject:(StAnaylizer *)value;
- (void)replaceAnaylizersAtIndexes:(NSIndexSet *)indexes withAnaylizers:(NSArray *)values;
- (void)addAnaylizersObject:(StAnaylizer *)value;
- (void)removeAnaylizersObject:(StAnaylizer *)value;
- (void)addAnaylizers:(NSOrderedSet *)values;
- (void)removeAnaylizers:(NSOrderedSet *)values;

- (void)addBlocksObject:(StBlock *)value;
- (void)removeBlocksObject:(StBlock *)value;
- (void)addBlocks:(NSSet *)values;
- (void)removeBlocks:(NSSet *)values;

- (void)addChildStreamsObject:(StStream *)value;
- (void)removeChildStreamsObject:(StStream *)value;
- (void)addChildStreams:(NSSet *)values;
- (void)removeChildStreams:(NSSet *)values;

- (NSMutableDictionary *)primitiveTopLevelBlocks;
- (void)setPrimitiveTopLevelBlocks:(NSMutableDictionary *)dictionary;

@end

@interface NSObject (StreamBlockerMakerExtension)
+ (void)makeBlocks:(StStream *)sender;
@end