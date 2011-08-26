//
//  AppDelegate.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "CoCoCassetteBlocker.h"

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
    //NSLog( @"Im alive: %@", notification );

    NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:@"CoCo Cassette Blocker" action:@selector(makeNewBlocker:) keyEquivalent:@""];
    [newMenuItem setRepresentedObject:[CoCoCassetteBlocker class]];
    [blocksMenu addItem:newMenuItem];
    [newMenuItem release];
}

@end
