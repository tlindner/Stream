//
//  CoCoCassetteBlocker.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Blockers.h"
#import "StStream.h"
#import "AppDelegate.h"

@interface CoCoCassetteBlocker : Blockers

@end

@interface RSDOSStringTransformer : NSValueTransformer
{
}
- (id)reverseTransformedValue:(id)value ofSize:(size_t)size;
@end

@interface UnsignedBigEndianTransformer : NSValueTransformer
{
}
- (id)reverseTransformedValue:(id)value ofSize:(size_t)size;
@end

@interface UnsignedLittleEndianTransformer : NSValueTransformer
{
}
- (id)reverseTransformedValue:(id)value ofSize:(size_t)size;
@end
