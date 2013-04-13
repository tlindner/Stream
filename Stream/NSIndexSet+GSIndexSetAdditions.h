//
//  NSIndexSet+GSIndexSetAdditions.h
//
//  Created by Mike Piatek-Jimenez on 1/4/13.
//  Copyright (c) 2013 Mike Piatek-Jimenez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (GSIndexSetAdditions)

- (NSIndexSet *) gsIntersectionWithIndexSet:(NSIndexSet *)otherSet;
- (NSIndexSet *) gsSubtractWithIndexSet:(NSIndexSet *)otherSet;

@end
