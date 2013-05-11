//
//  Blockers.h
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StStream, StAnaylizer;

@interface Blockers : NSObject

@property(nonatomic, retain) NSMutableArray *classList;
@property(nonatomic, retain) NSMutableDictionary *nameLookup;

+ (Blockers *)sharedInstance;

+ (NSString *)blockerGroup;
+ (NSString *)blockerName;
+ (NSString *)blockerKey;
+ (NSString *)blockerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;

- (NSString *)makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer;
- (void) addBlocker:(NSString *)blocker;

@end

@interface NSViewController (BlockerExtensions)
- (void)showPopover:(NSView *)showView;
@end