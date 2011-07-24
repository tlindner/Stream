//
//  StStream.h
//  Stream
//
//  Created by tim lindner on 7/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StStream;

@interface StStream : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSData * sourceURL;
@property (nonatomic, retain) NSData * changedBytes;
@property (nonatomic, retain) NSData * bytesCache;
@property (nonatomic) NSTimeInterval modificationDateofURL;
@property (nonatomic, retain) NSString * parentBlock;
@property (nonatomic, retain) NSString * streamTransform;
@property (nonatomic, retain) NSData * bytesAfterTransform;
@property (nonatomic, retain) NSOrderedSet *anaylizers;
@property (nonatomic, retain) NSSet *blocks;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) NSSet *childStreams;
@end

@interface StStream (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inAnaylizersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAnaylizersAtIndex:(NSUInteger)idx;
- (void)insertAnaylizers:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAnaylizersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAnaylizersAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceAnaylizersAtIndexes:(NSIndexSet *)indexes withAnaylizers:(NSArray *)values;
- (void)addAnaylizersObject:(NSManagedObject *)value;
- (void)removeAnaylizersObject:(NSManagedObject *)value;
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
