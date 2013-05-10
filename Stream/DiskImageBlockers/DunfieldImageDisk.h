//
//  DunfieldImageDisk.h
//  Stream
//
//  Created by tim lindner on 5/4/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StStream, StAnaylizer;

@interface DunfieldImageDisk : NSObject

+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;

+ (void) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer;

@end
