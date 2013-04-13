//
//  NSIndexSet+GSIndexSetAdditions.m
//
//  Created by Mike Piatek-Jimenez on 1/4/13.
//  Copyright (c) 2013 Mike Piatek-Jimenez. All rights reserved.
//

#import "NSIndexSet+GSIndexSetAdditions.h"

@implementation NSIndexSet (GSIndexSetAdditions)

- (NSIndexSet *) gsIntersectionWithIndexSet:(NSIndexSet *)otherSet {
  NSMutableIndexSet *finalSet = [[[NSMutableIndexSet alloc] init] autorelease];
	
  [self enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
    if ([otherSet containsIndex:index]) [finalSet addIndex:index];
  }];

  return finalSet;
}

- (NSIndexSet *) gsSubtractWithIndexSet:(NSIndexSet *)otherSet {
    NSMutableIndexSet *finalSet = [self mutableCopy];
    
    [otherSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        [finalSet removeIndex:index];
    }];
    
    return finalSet;
}

@end
