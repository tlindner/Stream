//
//  StBlock.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
//#import "StStream.h"

@class StStream;

@interface StBlock : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * anaylizerKind;
@property (nonatomic) int64_t expectedSize;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSMutableOrderedSet *attributeRanges;
@property (nonatomic, retain) NSMutableOrderedSet *dataRanges;
@property (nonatomic, retain) NSMutableOrderedSet *dependantRanges;
@property (nonatomic, retain) StStream *parent;

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name;
- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length;

@end

@interface StBlock (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inAttributeRangesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAttributeRangesAtIndex:(NSUInteger)idx;
- (void)insertAttributeRanges:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAttributeRangesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAttributeRangesAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceAttributeRangesAtIndexes:(NSIndexSet *)indexes withAttributeRanges:(NSArray *)values;
- (void)addAttributeRangesObject:(NSManagedObject *)value;
- (void)removeAttributeRangesObject:(NSManagedObject *)value;
- (void)addAttributeRanges:(NSOrderedSet *)values;
- (void)removeAttributeRanges:(NSOrderedSet *)values;
- (void)insertObject:(NSManagedObject *)value inDataRangesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDataRangesAtIndex:(NSUInteger)idx;
- (void)insertDataRanges:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDataRangesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDataRangesAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceDataRangesAtIndexes:(NSIndexSet *)indexes withDataRanges:(NSArray *)values;
- (void)addDataRangesObject:(NSManagedObject *)value;
- (void)removeDataRangesObject:(NSManagedObject *)value;
- (void)addDataRanges:(NSOrderedSet *)values;
- (void)removeDataRanges:(NSOrderedSet *)values;
- (void)insertObject:(NSManagedObject *)value inDependantRangesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromDependantRangesAtIndex:(NSUInteger)idx;
- (void)insertDependantRanges:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeDependantRangesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInDependantRangesAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceDependantRangesAtIndexes:(NSIndexSet *)indexes withDependantRanges:(NSArray *)values;
- (void)addDependantRangesObject:(NSManagedObject *)value;
- (void)removeDependantRangesObject:(NSManagedObject *)value;
- (void)addDependantRanges:(NSOrderedSet *)values;
- (void)removeDependantRanges:(NSOrderedSet *)values;
@end
