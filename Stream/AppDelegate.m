//
//  AppDelegate.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Blockers.h"

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

    for (NSString *blockerClassString in [Blockers sharedInstance].classList) {
        [self addBlockerMenu:blockerClassString];
    }
}
 
- (void) addBlockerMenu:(NSString *)classNameString
{
    Class blockerClass = NSClassFromString(classNameString);

    NSString *subMenuName = [blockerClass blockerGroup];
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
    
    NSMenuItem *newMenuItem = [[[NSMenuItem alloc] initWithTitle:[blockerClass blockerName] action:@selector(makeNewBlocker:) keyEquivalent:@""] autorelease];
    [newMenuItem setRepresentedObject:blockerClass];
    [subMenu addItem:newMenuItem];

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