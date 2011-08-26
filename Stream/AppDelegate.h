//
//  AppDelegate.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StStream;

@interface AppDelegate : NSObject
{
    NSMenu *blocksMenu;
}

@property (assign) IBOutlet NSMenu *blocksMenu;

@end

@protocol BlockerProtocol <NSObject>
@optional
+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;
+ (void) makeBlocks:(StStream *)stream;
@end
