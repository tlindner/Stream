//
//  StStream.m
//  Stream
//
//  Created by tim lindner on 7/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StStream.h"


@implementation StStream
@dynamic bytesAfterTransform;
@dynamic bytesCache;
@dynamic changedBytes;
@dynamic displayName;
@dynamic modificationDateofURL;
@dynamic parentBlock;
@dynamic sourceURL;
@dynamic streamTransform;
@dynamic customeSortOrder;
@dynamic anaylizers;
@dynamic blocks;
@dynamic childStreams;
@dynamic parentStream;

- (void)awakeFromInsert
{
    NSLog(@"Awoke!");
}

@end
