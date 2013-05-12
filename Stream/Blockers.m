//
//  Blockers.m
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "Blockers.h"

static Blockers *sharedSingleton;
static BOOL initialized = NO;

@implementation Blockers

@synthesize classList;
@synthesize nameLookup;

+ (void)initialize
{
    if ( self == [Blockers class] )
    {
        if(!initialized)
        {
            sharedSingleton = [[Blockers alloc] init];
            initialized = YES;
            [sharedSingleton addBlocker:@"CoCoCassetteBlocker"];
            [sharedSingleton addBlocker:@"CoCoCassetteFileBlocker"];
            [sharedSingleton addBlocker:@"CoCoSegmentedObjectBlocker"];
            [sharedSingleton addBlocker:@"OS9LogicalSectorsBlocker"];
            [sharedSingleton addBlocker:@"OS9FileBlocker"];
            [sharedSingleton addBlocker:@"ArbitraryGroupBlocker"];
            [sharedSingleton addBlocker:@"DunfieldImageDisk"];
            [sharedSingleton addBlocker:@"BasicDiskImage"];
            [sharedSingleton addBlocker:@"CoCoGranuleBlocker"];
            [sharedSingleton addBlocker:@"CoCoDiskFileBlocker"];
//            [sharedSingleton addBlocker:@"XXX"];
//            [sharedSingleton addBlocker:@"XXX"];
//            [sharedSingleton addBlocker:@"XXX"];
//            [sharedSingleton addBlocker:@"XXX"];
            
        }
    }
}

+ (Blockers *)sharedInstance
{
    if (initialized) {
        if (sharedSingleton != nil) {
            return sharedSingleton;
        }
    }
    
    NSLog( @"Blocker singleton requested, but does not exist");
    return nil;
}

+ (NSString *)blockerGroup
{
    return @"blockerGroup";
}

+ (NSString *)blockerName
{
    return @"blockerName";
}

+ (NSString *)blockerKey
{
    return @"blockerKey";
}

+ (NSString *)blockerPopoverAccessoryViewNib
{
    return nil;
}

+ (NSMutableDictionary *)defaultOptions
{
    return nil;
}

- (void) addBlocker:(NSString *)blocker
{
    if (self.classList == nil)
    {
        self.classList = [[[NSMutableArray alloc] init] autorelease];
    }
    
    if (self.nameLookup == nil)
    {
        self.nameLookup = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    [self.classList addObject:blocker];
    
    Class blockerClass = NSClassFromString(blocker);
    [self.nameLookup setObject:blockerClass forKey:[blockerClass blockerKey]];
}

- (NSString *)makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
#pragma unused (stream, anaylizer)
    NSLog( @"MakeBlocker needs to be implemented in the subclass");
    return nil;
}

- (void)showPopover:(NSView *)showView
{
#pragma unused (showView)
    return;
}

@end
