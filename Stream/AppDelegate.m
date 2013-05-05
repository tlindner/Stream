//
//  AppDelegate.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "CoCoCassetteBlocker.h"
#import "CoCoCassetteFileBlocker.h"
#import "CoCoSegmentedObjectBlocker.h"
#import "DunfieldImageDisk.h"

@interface NSObject (BlockerExtension)
+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;
@end

@implementation AppDelegate

@synthesize blocksMenu;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    #pragma unused(notification)
    //NSLog( @"Im alive: %@", notification );

    NSArray *blockers = [NSArray arrayWithObjects:[CoCoCassetteBlocker class], [CoCoCassetteFileBlocker class], [CoCoSegmentedObjectBlocker class], [DunfieldImageDisk class] , nil];
    
    for (Class blocker in blockers) {
        NSString *subMenuName = [[[blocker anayliserName] componentsSeparatedByString:@" "] objectAtIndex:0];
        NSMenuItem *subMenuItem = [blocksMenu itemWithTitle:subMenuName];
        NSMenu *subMenu;
        
        if (subMenuItem == nil) {
            NSMenuItem *mainItem = [[[NSMenuItem alloc] init] autorelease];
            [mainItem setTitle:subMenuName];
            subMenu = [[[NSMenu alloc] initWithTitle:subMenuName] autorelease];
            [blocksMenu addItem:mainItem];
            [blocksMenu setSubmenu:subMenu forItem:mainItem];
        }
        else {
            subMenu = [subMenuItem submenu];
        }
        
        NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:[blocker anayliserName] action:@selector(makeNewBlocker:) keyEquivalent:@""];
        [newMenuItem setRepresentedObject:[blocker class]];
        [subMenu addItem:newMenuItem];
    }
}

@end
