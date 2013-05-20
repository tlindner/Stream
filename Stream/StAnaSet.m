//
//  StAnaSet.m
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StAnaSet.h"
#import "StAnaylizer.h"


@implementation StAnaSet

@dynamic commandKey;
@dynamic group;
@dynamic setName;
@dynamic anaylizers;
@synthesize anaylizerArray;

- (NSArray *)anaylizerArray
{
    return [self.anaylizers array];
}

@end
