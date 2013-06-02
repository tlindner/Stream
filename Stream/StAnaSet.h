//
//  StAnaSet.h
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StAnalyzer;

@interface StAnaSet : NSManagedObject

@property (nonatomic, retain) NSString * commandKey;
@property (nonatomic, retain) NSString * group;
@property (nonatomic, retain) NSString * setName;
@property (nonatomic, retain) NSOrderedSet *analyzers;


@property (nonatomic, readonly) NSArray *analyzerArray;
@end

@interface StAnaSet (CoreDataGeneratedAccessors)

- (void)insertObject:(StAnalyzer *)value inAnalyzersAtIndex:(NSUInteger)idx;
- (void)removeObjectFromAnalyzersAtIndex:(NSUInteger)idx;
- (void)insertAnalyzers:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeAnalyzersAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInAnalyzersAtIndex:(NSUInteger)idx withObject:(StAnalyzer *)value;
- (void)replaceAnalyzersAtIndexes:(NSIndexSet *)indexes withAnalyzers:(NSArray *)values;
- (void)addAnalyzersObject:(StAnalyzer *)value;
- (void)removeAnalyzersObject:(StAnalyzer *)value;
- (void)addAnalyzers:(NSOrderedSet *)values;
- (void)removeAnalyzers:(NSOrderedSet *)values;
@end
