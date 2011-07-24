//
//  StStream.h
//  Stream
//
//  Created by tim lindner on 7/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StStream;

@interface StStream : NSManagedObject {
@private
}
@property (nonatomic, retain) NSData * bytesAfterTransform;
@property (nonatomic, retain) NSData * bytesCache;
@property (nonatomic, retain) NSData * changedBytes;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic) NSTimeInterval modificationDateofURL;
@property (nonatomic, retain) NSString * parentBlock;
@property (nonatomic, retain) NSData * sourceURL;
@property (nonatomic, retain) NSString * streamTransform;
@property (nonatomic) float customeSortOrder;
@property (nonatomic, retain) NSSet *anaylizers;
@property (nonatomic, retain) NSSet *blocks;
@property (nonatomic, retain) NSSet *childStreams;
@property (nonatomic, retain) StStream *parentStream;
@end

@interface StStream (CoreDataGeneratedAccessors)

- (void)addAnaylizersObject:(NSManagedObject *)value;
- (void)removeAnaylizersObject:(NSManagedObject *)value;
- (void)addAnaylizers:(NSSet *)values;
- (void)removeAnaylizers:(NSSet *)values;

- (void)addBlocksObject:(NSManagedObject *)value;
- (void)removeBlocksObject:(NSManagedObject *)value;
- (void)addBlocks:(NSSet *)values;
- (void)removeBlocks:(NSSet *)values;

- (void)addChildStreamsObject:(StStream *)value;
- (void)removeChildStreamsObject:(StStream *)value;
- (void)addChildStreams:(NSSet *)values;
- (void)removeChildStreams:(NSSet *)values;

@end
