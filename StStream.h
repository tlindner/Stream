//
//  Stream.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "StAnaylizer.h"
#import "StBlock.h"

@interface StStream : NSManagedObject
{
@private
}

@property (nonatomic, retain) NSData * bytesAfterTransform;
@property (nonatomic, retain) NSData * bytesCache;
@property (nonatomic, retain) NSData * changedBytes;
@property (nonatomic) float customeSortOrder;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic) NSTimeInterval modificationDateofURL;
@property (nonatomic, retain) NSString * parentBlock;
@property (nonatomic, retain) id sourceURL;
@property (nonatomic, retain) NSString * sourceUTI;
@property (nonatomic, retain) NSString * streamTransform;
@property (nonatomic, retain) NSOrderedSet *anaylizers;
@property (nonatomic, retain) NSSet *blocks;
@property (nonatomic, retain) NSSet *childStreams;
@property (nonatomic, retain) StStream *parentStream;

- (NSData *)blockedNamed:(NSString *)name;
- (StBlock *)startNewBlockNamed:(NSString *)name;

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
- (void)addBlocksObject:(NSManagedObject *)value;
- (void)removeBlocksObject:(NSManagedObject *)value;
- (void)addBlocks:(NSSet *)values;
- (void)removeBlocks:(NSSet *)values;

- (void)addChildStreamsObject:(StStream *)value;
- (void)removeChildStreamsObject:(StStream *)value;
- (void)addChildStreams:(NSSet *)values;
- (void)removeChildStreams:(NSSet *)values;

@end
