//
//  BlockAttributeViewController.h
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StBlock.h"

@interface BlockAttributeViewController : NSViewController {
    NSArrayController *arrayController;
    StBlockFormatter *blockFormatter;
}

@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet StBlockFormatter *blockFormatter;

+ (NSArray *)anaylizerUTIs;
+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;

@end
