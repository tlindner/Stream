//
//  DunfieldImageDisk.m
//  Stream
//
//  Created by tim lindner on 5/4/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DunfieldImageDisk.h"
#import "StStream.h"
#import "StBlock.h"

NSUInteger CalculateSectorSize( unsigned char value );

@implementation DunfieldImageDisk

+ (NSString *)blockerName
{
    return @"Dunfield Image Disk Blocker";
}

+ (NSString *)blockerKey
{
    return @"DunfieldImageDisk";
}

+ (NSString *)blockerPopoverAccessoryViewNib
{
    return nil;
}

+(NSString *)blockerGroup
{
    return @"Disk Image";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] init] autorelease];
}

- (NSString *) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
#pragma unused (anaylizer)
    
    if ([stream respondsToSelector:@selector(dataOfTopLevelBlockNamed:)] == NO) {
        return @"Incompatiable stream";
    }

    NSData  *streamBytesObject = [stream dataOfTopLevelBlockNamed:@"stream"];
    
    if (streamBytesObject == nil) {
        return @"No stream object";
    }

    unsigned char *streamBytes = (unsigned char *)[streamBytesObject bytes];
    
    if (streamBytes == nil) {
        return @"No stream bytes";
    }
    
    NSUInteger length = [streamBytesObject length];

    if (length < 4) {
        return @"Buffer too short to anaylize";
    }

    if (streamBytes[0] == 'I' && streamBytes[1] == 'M' && streamBytes[2] == 'D') {

        NSUInteger i=0;
        
        while (i < length) {
            if (streamBytes[i++] == 0x1a) break;
        }
 
        if (streamBytes[i-1] != 0x1a) {
            return @"Did not find note field";
        }
        
        StBlock *newBlock = [stream startNewBlockNamed:@"Note" owner:[DunfieldImageDisk blockerKey]];
        [newBlock addDataRange:@"stream" start:0 length:i-1];
        newBlock.sourceUTI = newBlock.resultingUTI = @"public.text";

        while (i < length) {
            unsigned char sectorTable[256];
            unsigned int sectorSizeMap[256];
            unsigned char sectorCylinderMap[256];
            unsigned char sectorHeadMap[256];
//            unsigned char mode;
            unsigned char cylinder;
            unsigned char head;
            unsigned char sectorCount;
            unsigned char sectorSizeCode;
            
            i++; /* skip mode value */
            if (i==length) return @"Abnormal end: short header";
            cylinder = streamBytes[i++];
            if (i==length) return  @"Abnormal end: short header";
            head = streamBytes[i++];
            if (i==length) return @"Abnormal end: short header";
            sectorCount = streamBytes[i++];
            if (i==length) return @"Abnormal end: short header";
            sectorSizeCode = streamBytes[i++];
            if (i==length) return @"Abnormal end: short header";
            
//            NSLog(@"mode: %d, cylinder: %d, head: %d, sector count: %d, sector size code: %d", mode, cylinder, head, sectorCount, sectorSizeCode);

            [newBlock addAttributeRange:@"stream" start:i-5 length:1 name:@"Mode" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            
            if ((i+sectorCount) >= length) return @"Abnormal end: short header";
                
            for (NSUInteger j=0; j < sectorCount ; j++ ) {
                sectorTable[j] = streamBytes[i++];
            }
            
            if ((head & 0x80) == 0x80) {
                /* sector cylinder map */
                if ((i+sectorCount) >= length) return @"Abnormal end: short header";
                for (NSUInteger j=0; j<sectorCount; j++) {
                    sectorCylinderMap[j] = streamBytes[i++];
                }
            }
            else {
                for (NSUInteger j=0; j<sectorCount; j++) {
                    sectorCylinderMap[j] = cylinder;
                }
            }
            
            if ((head & 0x40) == 0x40) {
                /* sector head map */
                if ((i+sectorCount) >= length) return @"Abnormal end: short header";
                for (NSUInteger j=0; j<sectorCount; j++) {
                    sectorHeadMap[j] = streamBytes[i++];
                }
            }
            else {
                for (NSUInteger j=0; j<sectorCount; j++) {
                    sectorHeadMap[j] = head;
                }
            }
            
            if (sectorSizeCode == 0xff) {
                /* sector size map */
                if ((i+sectorCount) >= length) return @"Abnormal end: short header";
                for (NSUInteger j=0; j<sectorCount; j++) {
                    sectorSizeMap[j] = CalculateSectorSize( streamBytes[i++] );
                }
            }
            else {
                for (NSUInteger j=0; j<sectorCount; j++) {
                    
                    sectorSizeMap[j] = CalculateSectorSize( sectorSizeCode );
                }
            }
            
            for (NSUInteger j=0; j < sectorCount; j++) {
                unsigned char sectorType = streamBytes[i++], sectorIdealType;
                if (i == length) return @"Abnormal End: short block";
                NSString *blockName;
                NSUInteger actualLength;
                
                blockName = [NSString stringWithFormat:@"Track %d %d Side %d %d Sector %d %d", sectorCylinderMap[j], cylinder, sectorHeadMap[j], head & 0x01, j, sectorTable[j]];

                switch (sectorType) {
                    case 0:
                        /* sector data unavaiable */
                        sectorIdealType = 1;
                        newBlock = [stream startNewBlockNamed:blockName owner:[DunfieldImageDisk blockerKey]];
                        [newBlock addAttributeRange:@"stream" start:i-1 length:1 name:@"Sector Type" verification:[NSData dataWithBytes:&sectorIdealType length:1] transformation:@"BlocksUnsignedBigEndian"];
                        newBlock.sourceUTI = newBlock.resultingUTI = @"public.data";
                        break;
                    case 1: /* Normal data: (Sector Size) bytes follow */
                    case 3: /* Normal data with "Deleted-Data address mark" */
                    case 5: /* Normal data read with data error */
                    case 7: /* Deleted data read with data error */
                        if (sectorType == 1) sectorIdealType = 1;
                        if (sectorType == 3) sectorIdealType = 3;
                        if (sectorType == 5) sectorIdealType = 1;
                        if (sectorType == 7) sectorIdealType = 3;
                        newBlock = [stream startNewBlockNamed:blockName owner:[DunfieldImageDisk blockerKey]];
                        actualLength = MIN(sectorSizeMap[j], length - i);
                        [newBlock addDataRange:@"stream" start:i length:actualLength name:nil verification:nil transformation:nil expectedLength:sectorSizeMap[j] repeat:NO];
                        [newBlock addAttributeRange:@"stream" start:i-1 length:1 name:@"Sector Type" verification:[NSData dataWithBytes:&sectorIdealType length:1] transformation:@"BlocksUnsignedBigEndian"];
                        newBlock.sourceUTI = newBlock.resultingUTI = @"public.data";
                        i += actualLength;
                        break;

                    case 2: /* Compressed: All bytes in sector have same value (xx) */
                    case 4: /* Compressed: with "Deleted-Data address mark" */
                    case 6: /* Compressed: read with data error */
                    case 8: /* Compressed: Deleted read with data error */
                        if (sectorType == 2) sectorIdealType = 2;
                        if (sectorType == 4) sectorIdealType = 4;
                        if (sectorType == 6) sectorIdealType = 2;
                        if (sectorType == 8) sectorIdealType = 4;
                        newBlock = [stream startNewBlockNamed:blockName owner:[DunfieldImageDisk blockerKey]];
                        actualLength = MIN(sectorSizeMap[j], length - i);
                        [newBlock addDataRange:@"stream" start:i length:1 expectedLength:actualLength repeat:YES];
                        [newBlock addAttributeRange:@"stream" start:i-1 length:1 name:@"Sector Type" verification:[NSData dataWithBytes:&sectorIdealType length:1] transformation:@"BlocksUnsignedBigEndian"];
                        newBlock.sourceUTI = newBlock.resultingUTI = @"public.data";
                        i++;
                        break;
                        
                    default:
                        return [NSString stringWithFormat:@"Abnormal end: Unexpected sector type: %d, byte: 0x%lx", sectorType, i-1];
                        break;
                }
            }
        }
    }
    else {
        return @"Stream does not start with the magic bytes.";
    }
    
    return @"";
}

@end

NSUInteger CalculateSectorSize( unsigned char value )
{
    if (value > 6) value = 6;
    return 128 << value;
}
