//
//  CoCoSegmentedObjectBlocker.m
//  Stream
//
//  Created by tim lindner on 4/28/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CoCoSegmentedObjectBlocker.h"
#import "StBlock.h"

@implementation CoCoSegmentedObjectBlocker
+ (NSString *)blockerName
{
    return @"CoCo Segmented Object Blocker";
}

+ (NSString *)blockerKey
{
    return @"CoCoSegmentedObjectBlocker";
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
    return @"CoCo";
}

- (NSString *) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
#pragma unused (anaylizer)
    if ([stream respondsToSelector:@selector(dataOfTopLevelBlockNamed:)] == NO) {
        return @"Incompatiable stream";
    }
    
    int segmentNumber, transferNumber;
    NSUInteger i;
    
    NSData  *streamBytesObject = [stream dataOfTopLevelBlockNamed:@"stream"];
    
    if (streamBytesObject == nil) {
        return @"No stream object";
    }

    unsigned char *streamBytes = (unsigned char *)[streamBytesObject bytes];
    
    if (streamBytes == nil) {
        return @"No stream bytes";
    }

    NSUInteger length = [streamBytesObject length];
    segmentNumber = 0;
    transferNumber = 0;
    i = 0;
    
    while (i+4 < length) {
        unsigned char segAmble, actualLengthBE[2];
        unsigned short segAddress, segLength, actualLength;

        segAmble = streamBytes[i+0];
        segLength = streamBytes[i+1] << 8;
        segLength += streamBytes[i+2];
        segAddress = streamBytes[i+3] << 8;
        segAddress += streamBytes[i+4];
        actualLength = MIN(segLength, (i + 5 + segLength) - length);
        actualLengthBE[0] = actualLength >> 8;
        actualLengthBE[1] = actualLength & 0x00ff;
        
        assert(segAddress < 0x10000);
        
        if (segAmble == 0x00) {
            /* preamble */
            StBlock *newSegement = [stream startNewBlockNamed:[NSString stringWithFormat:@"Segment %d", segmentNumber++] owner:[CoCoSegmentedObjectBlocker blockerKey]];
            newSegement.sourceUTI = newSegement.resultingUTI = @"com.microsoft.cocobasic.object";
            
            [newSegement addAttributeRange:@"stream" start:i+0 length:1 name:@"Amble" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            [newSegement addAttributeRange:@"stream" start:i+1 length:2 name:@"Length" verification:[NSData dataWithBytes:actualLengthBE length:2] transformation:@"BlocksUnsignedBigEndian"];
            [newSegement addAttributeRange:@"stream" start:i+3 length:2 name:@"ML Load Address" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            
            if (actualLength > 0) {
                [newSegement addDataRange:@"stream" start:i+5 length:actualLength];
            }
            
            i += 5 + segLength;
            
        } else if (segAmble == 0xff) {
            /* postamble */
            StBlock *newSegement = [stream startNewBlockNamed:[NSString stringWithFormat:@"Transfer %d", transferNumber++] owner:[CoCoSegmentedObjectBlocker blockerKey]];
            newSegement.sourceUTI = newSegement.resultingUTI = @"public.data";
            [newSegement addAttributeRange:@"stream" start:i+0 length:1 name:@"Amble" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            [newSegement addAttributeRange:@"stream" start:i+1 length:2 name:@"Length" verification:[NSData dataWithBytes:&actualLength length:2] transformation:@"BlocksUnsignedBigEndian"];
            [newSegement addAttributeRange:@"stream" start:i+3 length:2 name:@"ML Exec Address" verification:nil transformation:@"BlocksUnsignedBigEndian"];
//            i += 5 + segLength;
            break;
            
        } else {
            /* unknown amble */
//            i += 5;
            break;
        }
    }
    
    return @"";
}

@end
