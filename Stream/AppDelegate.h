//
//  AppDelegate.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlockerProtocol.h"

@class StStream;

@interface AppDelegate : NSObject
{
    NSMenu *blocksMenu;
}

@property (assign) IBOutlet NSMenu *blocksMenu;

@end

@interface NSError (ExtendedErrorCategory)
- (NSString *)debugDescription;
@end