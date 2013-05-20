//
//  StAnaSet.h
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StAnaylizer;

@interface StAnaSet : NSManagedObject

@property (nonatomic, retain) NSString * commandKey;
@property (nonatomic, retain) NSString * group;
@property (nonatomic, retain) NSString * setName;
@property (nonatomic, retain) NSOrderedSet *anaylizers;


@property (nonatomic, readonly) NSArray *anaylizerArray;
@end

@interface StAnaSet (CoreDataGeneratedAccessors)

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
@end
