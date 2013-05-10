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
#import "OS9LogicalSectorsBlocker.h"
#import "OS9FileBlocker.h"

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

- (NSError *)application:(NSApplication *)theApplication willPresentError:(NSError *)error
{
#pragma unused (theApplication)
    // Log the error to the console for debugging
    NSLog(@"Application will present error:\n%@", [error description]);
    
    return error;
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    #pragma unused(notification)
    //NSLog( @"Im alive: %@", notification );

    NSArray *blockers = [NSArray arrayWithObjects:[CoCoCassetteBlocker class], [CoCoCassetteFileBlocker class], [CoCoSegmentedObjectBlocker class], [DunfieldImageDisk class], [OS9LogicalSectorsBlocker class], [OS9FileBlocker class], nil];
    
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

@implementation NSError (ExtendedErrorCategory)

- (NSString *)debugDescription
{
    //  Log the entirety of domain, code, userInfo for debugging.
    //  Operates recursively on underlying errors
    
    NSMutableDictionary *dictionaryRep = [[self userInfo] mutableCopy];
    
    [dictionaryRep setObject:[self domain]
                      forKey:@"domain"];
    [dictionaryRep setObject:[NSNumber numberWithInteger:[self code]]
                      forKey:@"code"];
    
    NSError *underlyingError = [[self userInfo] objectForKey:NSUnderlyingErrorKey];
    NSString *underlyingErrorDescription = [underlyingError debugDescription];
    if (underlyingErrorDescription)
    {
        [dictionaryRep setObject:underlyingErrorDescription
                          forKey:NSUnderlyingErrorKey];
    }
    
    // Finish up
    NSString *result = [dictionaryRep description];
    [dictionaryRep release];
    return result;
}

@end