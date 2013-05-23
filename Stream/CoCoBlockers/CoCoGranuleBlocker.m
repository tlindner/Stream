//
//  CoCoGranuleBlocker.m
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CoCoGranuleBlocker.h"
#import "StStream.h"
#import "StBlock.h"

@class StAnaylizer;

@implementation CoCoGranuleBlocker

+ (NSString *)blockerName
{
    return @"CoCo Granule Blocker";
}

+ (NSString *)blockerKey
{
    return @"CoCoGranuleBlocker";
}

+ (NSString *)blockerPopoverAccessoryViewNib
{
    return nil;
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] init] autorelease];
}

+ (NSString *)blockerGroup
{
    return @"CoCo Disk";
}

- (NSString *) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
#pragma unused (anaylizer)
    int startSector, track;
    StBlock *newGran, *directory, *fat, *directoryEntries;
    
    startSector = 1;
    track = 0;
    
    for (int i=0; i<68; i++) {
        newGran = [stream startNewBlockNamed:[NSString stringWithFormat:@"Granule %d", i] owner:[CoCoGranuleBlocker blockerKey]];
        
        for (int j=0; j<9; j++) {
            NSString *name = [NSString stringWithFormat:@"Track * %d Side * 0 Sector * %d", track, j + startSector];
            [newGran addDataRange:name start:0 length:0 expectedLength:256];
        }
        
        if (startSector == 1) {
            startSector = 10;
        }
        else {
            startSector = 1;
            track++;
        }
        
        if (track == 17) {
            track++;
        }
    }
    
    directory = [stream startNewBlockNamed:@"Directory" owner:[CoCoGranuleBlocker blockerKey]];
    for (int i=1; i<19; i++) {
        NSString *name = [NSString stringWithFormat:@"Track * 17 Side * 0 Sector * %d", i];
        [directory addDataRange:name start:0 length:0 expectedLength:256];
    }
    
    fat = [stream startNewBlockNamed:@"File Allocation Table" owner:[CoCoGranuleBlocker blockerKey]];
    [fat addDataRange:@"Directory" start:256*1 length:256];
    
    directoryEntries = [stream startNewBlockNamed:@"Directory Entries" owner:[CoCoGranuleBlocker blockerKey]];
    [directoryEntries addDataRange:@"Directory" start:256*2 length:32*72];
    
    return nil;
}
@end
