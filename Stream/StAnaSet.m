//
//  StAnaSet.m
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StAnaSet.h"
#import "StAnalyzer.h"


@implementation StAnaSet

@dynamic commandKey;
@dynamic group;
@dynamic setName;
@dynamic analyzers;
@synthesize analyzerArray;

- (NSArray *)analyzerArray
{
    return [self.analyzers array];
}

@end
