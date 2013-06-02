//
//  StStream.h
//  temp
//
//  Created by tim lindner on 5/8/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StAnalyzer, StBlock, StStream;

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
@property (nonatomic, retain) NSOrderedSet *analyzers;
@property (nonatomic, retain) NSSet *blocks;
@property (nonatomic, retain) NSSet *childStreams;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) StBlock *sourceBlock;

- (NSData *)dataOfTopLevelBlockNamed:(NSString *)name;
- (StBlock *)topLevelBlockNamed:(NSString *)theName;
- (StBlock *)startNewBlockNamed:(NSString *)name owner:(NSString *)owner;
- (StBlock *)makeNewBlockNamed:(NSString *)name owner:(NSString *)owner;
- (StAnalyzer *)lastFilterAnalyzer;
- (StAnalyzer *)previousAnalyzer:(StAnalyzer *)inAna;
- (NSArray *)blocksWithAnalyzerKey:(NSString *)key;
- (void)setBlock:(StBlock *)theBlock withData:(NSData *)theData;
- (void) setBlock:(StBlock *)theBlock withData:(NSData *)theData inRange:(NSRange)range;
- (void)regenerateAllBlocks;
- (void) markTopLevelBlocksForDeletion;
- (void) deleteTopLevelBlocksMarkedForDeletion;
- (BOOL)isBlockEdited:(NSString *)blockName;
- (BOOL)isBlockFailed:(NSString *)blockName;
@end

@interface StStream (CoreDataGeneratedAccessors)

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
+ (void) makeBlocks:(StStream *)stream withAnalyzer:(StAnalyzer *)analyzer;
@end