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
#import "StreamEdit.h"

@interface NSViewController (BlockerViewExtensions)
- (void) notifyOfImpendingDeletion:(NSArray *)blocks;
- (void) reloadView;
@end

@interface StStream : NSManagedObject
{
@private
    BOOL regeneratingBlocks;
}

@property (nonatomic, retain) NSData * bytesCache;
@property (nonatomic) float customeSortOrder;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic) NSTimeInterval modificationDateofURL;
@property (nonatomic, retain) NSString * parentBlock;
@property (nonatomic, retain) id sourceURL;
@property (nonatomic, retain) NSString * sourceUTI;
@property (nonatomic, retain) NSString * streamTransform;
@property (nonatomic, retain) NSOrderedSet * anaylizers;
@property (nonatomic, retain) NSSet * blocks;
@property (nonatomic, retain) NSSet * childStreams;
@property (nonatomic, retain) NSOrderedSet * edits;
@property (nonatomic, retain) StStream * parentStream;

- (NSData *) dataOfBlockNamed:(NSString *)name;
- (StBlock *) startNewBlockNamed:(NSString *)name owner:(NSString *)owner;
- (StBlock *) makeNewBlockNamed:(NSString *)name owner:(NSString *)owner;
- (NSSet *) blocksWithKey:(NSString *)key;
- (void) setBlock:(StBlock *)theBlock withData:(NSData *)theData;
- (void) setBlock:(StBlock *)theBlock withData:(NSData *)theData inRange:(NSRange)range;
- (StAnaylizer *) lastFilterAnayliser;
- (StBlock *) blockNamed:(NSString *)theName;
- (StAnaylizer *) previousAnayliser:(StAnaylizer *)inAna;
- (void) regenerateAllBlocks;
- (void) markBlocksForDeletion;
- (void) deleteBlocksMarkedForDeletion;
- (BOOL) isBlockEdited:(NSString *)blockName;
- (BOOL) isBlockFailed:(NSString *)blockName;

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

- (void)insertObject:(StreamEdit *)value inEditsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEditsAtIndex:(NSUInteger)idx;
- (void)insertEdits:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeEditsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEditsAtIndex:(NSUInteger)idx withObject:(StreamEdit *)value;
- (void)replaceEditsAtIndexes:(NSIndexSet *)indexes withEdits:(NSArray *)values;
- (void)addEditsObject:(StreamEdit *)value;
- (void)removeEditsObject:(StreamEdit *)value;
- (void)addEdits:(NSOrderedSet *)values;
- (void)removeEdits:(NSOrderedSet *)values;

- (void)addBlocksObject:(NSManagedObject *)value;
- (void)removeBlocksObject:(NSManagedObject *)value;
- (void)addBlocks:(NSSet *)values;
- (void)removeBlocks:(NSSet *)values;

- (void)addChildStreamsObject:(StStream *)value;
- (void)removeChildStreamsObject:(StStream *)value;
- (void)addChildStreams:(NSSet *)values;
- (void)removeChildStreams:(NSSet *)values;

@end


