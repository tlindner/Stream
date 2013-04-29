//
//  CoCoSegmentedObjectBlocker.h
//  Stream
//
//  Created by tim lindner on 4/28/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StStream.h"
#import "AppDelegate.h"

@interface CoCoSegmentedObjectBlocker : NSObject <BlockerProtocol>

+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;

+ (void) makeBlocks:(StStream *)stream;

@end
