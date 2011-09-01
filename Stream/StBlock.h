//
//  StBlock.h
//  Stream
//
//  Created by tim lindner on 8/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StBlock, StStream;

@interface StBlock : NSManagedObject
{
@private
    NSUInteger dataIndex, attrIndex, depIndex; 
}
@property (nonatomic, retain) NSString * anaylizerKind;
@property (nonatomic, retain) NSString * currentEditorView;
@property (nonatomic) int64_t expectedSize;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) int32_t type;
@property (nonatomic) int64_t offset;
@property (nonatomic) int64_t length;
@property (nonatomic, retain) NSString * valueTransformer;
@property (nonatomic, retain) NSString * uiName;
@property (nonatomic, retain) NSData * checkBytes;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * sourceUTI;
@property (nonatomic) int64_t index;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) StBlock *parentBlock;
@property (nonatomic, retain) NSSet *blocks;

@property (nonatomic, readonly) NSData *data;

- (StStream *)getStream;

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name;
- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify;
- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name transformation:(NSString *)transform;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;

- (void) addDependenciesRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;

- (NSData *)getData;
- (StBlock *)blockNamed:(NSString *)inName;

@end

@interface StBlock (CoreDataGeneratedAccessors)

- (void)addBlocksObject:(StBlock *)value;
- (void)removeBlocksObject:(StBlock *)value;
- (void)addBlocks:(NSSet *)values;
- (void)removeBlocks:(NSSet *)values;

@end
