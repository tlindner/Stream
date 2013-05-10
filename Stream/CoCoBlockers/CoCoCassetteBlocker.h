//
//  CoCoCassetteBlocker.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StStream.h"
#import "AppDelegate.h"

@interface CoCoCassetteBlocker : NSObject <BlockerProtocol>

+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;

+ (void) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer;

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
