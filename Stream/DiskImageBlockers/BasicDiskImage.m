//
//  BasicDiskImage.m
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "BasicDiskImage.h"
#import "StStream.h"
#import "StAnaylizer.h"
#import "StBlock.h"

@implementation BasicDiskImage

+ (NSString *)blockerName
{
    return @"Basic Disk Blocker";
}

+ (NSString *)blockerKey
{
    return @"BasicDiskImage";
}

+ (NSString *)blockerPopoverAccessoryViewNib
{
    return @"BasicDiskImageViewController";
}

+(NSString *)blockerGroup
{
    return @"Disk Image";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:0], @"skipHeaderLength", [NSNumber numberWithUnsignedInteger:256], @"sectorLength", [NSNumber numberWithUnsignedInteger:1], @"sideCount", [NSNumber numberWithUnsignedInteger:18], @"trackLength",[NSNumber numberWithUnsignedInteger:1], @"firstSectorID", nil] autorelease];
}

- (NSString *)makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
    if ([stream respondsToSelector:@selector(dataOfTopLevelBlockNamed:)] == NO) {
        return @"Incompatiable stream";
    }
    
    NSData  *streamBytesObject = [stream dataOfTopLevelBlockNamed:@"stream"];
    
    if (streamBytesObject == nil) {
        return @"No stream object";
    }
        
    NSUInteger streamLength = [streamBytesObject length], bytesConsumed;
    NSDictionary *option = [[anaylizer optionsDictionary] objectForKey:[BasicDiskImage blockerKey]];
    NSUInteger skipHeaderLength = [[option objectForKey:@"skipHeaderLength"] intValue];
    NSUInteger sectorLength = [[option objectForKey:@"sectorLength"] intValue];
    NSUInteger sideCount = [[option objectForKey:@"sideCount"] intValue];
    NSUInteger trackLength = [[option objectForKey:@"trackLength"] intValue];
    NSUInteger firstSectorID = [[option objectForKey:@"firstSectorID"] intValue];
    NSUInteger track = 0;
    
    bytesConsumed = skipHeaderLength;
    
    while (bytesConsumed < streamLength) {
        for (NSUInteger i = 0; i <sideCount; i++) {
            for (NSUInteger j=0; j<trackLength; j++) {

                StBlock *newsector = [stream startNewBlockNamed:[NSString stringWithFormat:@"Track %d %d Side %d %d Sector %d %d", track, track, i, i, j, j+firstSectorID] owner:[BasicDiskImage blockerKey]];
                
                NSUInteger actualLength = MIN(sectorLength, streamLength - sectorLength);
                [newsector addDataRange:@"stream" start:bytesConsumed length:actualLength expectedLength:sectorLength];
                bytesConsumed += actualLength;
                
                if (bytesConsumed >= streamLength) break;
            }
            
            if (bytesConsumed >= streamLength) break;
        }
        
        track++;
    }
    
    return @"";
}
@end
