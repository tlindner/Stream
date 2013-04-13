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
    NSObject * anaylizerObject;
}
@property (nonatomic, retain) NSString * anaylizerKind;
@property (nonatomic, retain) NSString * currentEditorView;
@property (nonatomic, readonly) NSObject * anaylizerObject;
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
@property (nonatomic) BOOL markForDeletion;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) StBlock *parentBlock;
@property (nonatomic, retain) NSMutableDictionary *optionsDictionary;
@property (nonatomic, retain) NSSet *blocks;
@property (nonatomic, assign) NSDictionary *dataForUI;
@property (nonatomic, readonly) NSDictionary *checkBytesForUI;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, assign) BOOL isFail;
@property (nonatomic, assign) BOOL isEdit;
@property (nonatomic, readonly) NSColor * attributeColor;
@property (nonatomic, readonly) BOOL canChangeEditor;
@property (nonatomic, readonly) NSMutableIndexSet *editSet;

- (StStream *)getStream;
- (void) resetCounters;

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name;
- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify;
- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name transformation:(NSString *)transform;
- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;

- (void) addDependenciesRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;

- (void) addSubOptionsDictionary:(NSString *)subOptionsID withDictionary:(NSMutableDictionary *)newOptions;
- (NSData *)getData;
- (NSArray *)getArrayOfBlocks;
- (StBlock *)subBlockNamed:(NSString *)inName;
- (BOOL)writeByte:(unsigned char)byte atOffset:(NSUInteger)offset;
- (StBlock *)subBlockAtIndex:(NSInteger)theIndex;
- (void) smartSetEdit;
- (void) smartSetFail;
- (void) checkEdited:(StBlock *)newBlock;
- (void) checkFail:(StBlock *)newBlock;
- (NSRange)getUnionRange;

@end

@interface StBlock (CoreDataGeneratedAccessors)

- (void)addBlocksObject:(StBlock *)value;
- (void)removeBlocksObject:(StBlock *)value;
- (void)addBlocks:(NSSet *)values;
- (void)removeBlocks:(NSSet *)values;

@end

@interface StBlockFormatter : NSFormatter {
@private
}
@property (nonatomic, retain) NSString *mode;

- (NSString *)stringForObjectValue:(id)anObject;
- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error;
@end
