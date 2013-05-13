//
//  DavidKeilDiskImage.m
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DavidKeilDiskImage.h"
#import "StStream.h"
#import "StBlock.h"

UInt16 ccitt_crc16(UInt16 crc, const UInt8 *buffer, size_t buffer_len);
UInt16 ccitt_crc16_one( UInt16 crc, const UInt8 data );

@implementation DavidKeilDiskImage

+ (NSString *)blockerName
{
    return @"DMK Disk Image Blocker";
}

+ (NSString *)blockerKey
{
    return @"DavidKeilDiskImage";
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
    
    unsigned const char *bytes = [streamBytesObject bytes];
    
    NSUInteger streamLength = [streamBytesObject length], bc;

    bc = 16;
    
    if (bc > streamLength) {
        return @"Stream smaller than a DMK header";
    }
    
    unsigned trackCount = bytes[1];
    unsigned trackLength = (bytes[3] << 8) + bytes[2];
    unsigned sideCount = (bytes[4] & 0x10) ? 1 : 2;
    unsigned trackIndex = 0;
    unsigned sideIndex;
    unsigned idamIndex;
    
    if (16 + (trackCount * sideCount * trackLength) != streamLength) {
        return @"Calculated stream size does not match real stream size. Aborting.";
    }
    
    StBlock *dmkHeader = [stream startNewBlockNamed:@"DMK Header" owner:[DavidKeilDiskImage blockerKey]];

    [dmkHeader addAttributeRange:@"stream" start:0 length:1 name:@"Write Protect" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:1 length:1 name:@"Track Count" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:2 length:2 name:@"Track Length" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:4 length:1 name:@"Virtual Disk Flags" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:5 length:1 name:@"Reserved 1" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:6 length:1 name:@"Reserved 2" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:7 length:1 name:@"Reserved 3" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:8 length:1 name:@"Reserved 4" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:9 length:1 name:@"Reserved 5" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:10 length:1 name:@"Reserved 6" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:11 length:1 name:@"Reserved 7" verification:nil transformation:@"BlocksUnsignedLittleEndian"];
    [dmkHeader addAttributeRange:@"stream" start:12 length:4 name:@"Real Flag" verification:nil transformation:@"BlocksUnsignedLittleEndian"];

    while (trackIndex < trackCount) {
        sideIndex = 0;
        
        while (sideIndex < sideCount) {
            idamIndex = 0;
            
            while (idamIndex < 0x80) {
                
                unsigned idamPosition;
                unsigned singleDensity;
                UInt16 idamCRC, damCRC;
                UInt8 idamCRC_BE[2], damCRC_BE[2];
                StBlock *newSector;
                
                idamPosition = (bytes[bc+idamIndex+1] << 8) + bytes[bc+idamIndex];
                singleDensity = (idamPosition & 0x8000) == 0;
                idamPosition &= 0x3fff;
                
                if (idamPosition == 0) break;
                
                if (idamPosition+5 > trackLength) {
                    return [NSString stringWithFormat:@"IDAM index: %d, on track %d, and side %d past length of track", idamIndex, trackIndex, sideIndex];
                }
                
                if (singleDensity)
                    idamCRC = ccitt_crc16(0xffff, &(bytes[bc+idamPosition]), 5);
                else
                    idamCRC = ccitt_crc16(0xcdb4, &(bytes[bc+idamPosition]), 5);
                
                idamCRC_BE[0] = idamCRC >> 8;
                idamCRC_BE[1] = idamCRC & 0xff;
                NSData *crcVerify = [NSData dataWithBytes:idamCRC_BE length:2];
                
                unsigned trackCode = bytes[bc+idamPosition+1];
                unsigned sideCode = bytes[bc+idamPosition+2];
                unsigned sectorCode = bytes[bc+idamPosition+3];
                unsigned sizeCode = bytes[bc+idamPosition+4];
//                unsigned crcCode = (bytes[bc+idamPosition+5] << 8) + bytes[bc+idamPosition+6];
                
                NSString *sectorName = [NSString stringWithFormat:@"Track %d %d Side %d %d Sector %d %d", trackIndex, trackCode, sideIndex, sideCode, idamIndex/2, sectorCode];
                newSector = [stream startNewBlockNamed:sectorName owner:[DavidKeilDiskImage blockerKey]];
                [newSector addAttributeRange:@"stream" start:bc+idamPosition+1 length:1 name:@"Track Code" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                [newSector addAttributeRange:@"stream" start:bc+idamPosition+2 length:1 name:@"Side Code" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                [newSector addAttributeRange:@"stream" start:bc+idamPosition+3 length:1 name:@"Sector Code" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                [newSector addAttributeRange:@"stream" start:bc+idamPosition+4 length:1 name:@"Size Code" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                [newSector addAttributeRange:@"stream" start:bc+idamPosition+5 length:2 name:@"ID CRC" verification:crcVerify transformation:@"BlocksUnsignedBigEndian"];
                
                /* search for Data Address Mark */
                
                unsigned stopLooking;
                unsigned damPosition = 0;
                
                stopLooking = MIN(idamPosition+5+7+0x80, trackLength);
                
                while ( idamPosition+5+7+damPosition < stopLooking-2 )
                {
                    if (singleDensity) {
                        if (bytes[bc+idamPosition+5+7+damPosition] == 0x00) {
                            if (bytes[bc+idamPosition+5+7+damPosition+1] == 0x00) {
                                if ((bytes[bc+idamPosition+5+7+damPosition+2] >= 0xf8) && (bytes[bc+idamPosition+5+7+damPosition+2] <= 0xfb)) {
                                    /* is there enough room in the track data for it */
                                    
                                    if (idamPosition+5+7+damPosition+2+(128<<sizeCode)+1 < trackLength ) {
                                        damCRC = ccitt_crc16(0xffff, &(bytes[bc+idamPosition+5+7+damPosition+2]), (128<<sizeCode)+1);
                                        damCRC_BE[0] = damCRC >> 8;
                                        damCRC_BE[1] = damCRC & 0x0f;
                                        crcVerify = [NSData dataWithBytes:damCRC_BE length:2];
                                        [newSector addAttributeRange:@"stream" start:bc+idamPosition+5+7+damPosition+2 length:1 name:@"DAM" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                                        [newSector addAttributeRange:@"stream" start:bc+idamPosition+5+7+damPosition+2+(128<<sizeCode)+1 length:2 name:@"Data CRC" verification:crcVerify transformation:@"BlocksUnsignedBigEndian"];
                                        
                                        [newSector addDataRange:@"stream" start:bc+idamPosition+5+7+damPosition+3 length:(128<<sizeCode)];
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    else {
                        if( bytes[bc+idamPosition+5+7+damPosition] == 0xa1 ) {
                            if( bytes[bc+idamPosition+5+7+damPosition+1] == 0xa1 ) {
                                if( (bytes[bc+idamPosition+5+7+damPosition+2] >= 0xf8) && (bytes[bc+idamPosition+5+7+damPosition+2] <= 0xfb) ) {
                                    /* is there enough room in the track data for it */
                                    if (idamPosition+5+7+damPosition+2+(128<<sizeCode)+1 < trackLength ) {
                                    
                                        damCRC = ccitt_crc16(0xcdb4, &(bytes[bc+idamPosition+5+7+damPosition+2]), (128<<sizeCode)+1);
                                        damCRC_BE[0] = damCRC >> 8;
                                        damCRC_BE[1] = damCRC & 0xff;
                                        crcVerify = [NSData dataWithBytes:damCRC_BE length:2];
                                        [newSector addAttributeRange:@"stream" start:bc+idamPosition+5+7+damPosition+2 length:1 name:@"DAM" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                                        [newSector addAttributeRange:@"stream" start:bc+idamPosition+5+7+damPosition+2+(128<<sizeCode)+1 length:2 name:@"Data CRC" verification:crcVerify transformation:@"BlocksUnsignedBigEndian"];
                                        
                                        [newSector addDataRange:@"stream" start:bc+idamPosition+5+7+damPosition+3 length:(128<<sizeCode)];
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    
                    damPosition++;
                }
                
                idamIndex += 2;
            }
            
            bc += trackLength;
            sideIndex++;
        }
        
        trackIndex++;
    }

    return nil;
}

@end


/*
 Compute CCITT CRC-16 using the correct bit order for floppy disks.
 CRC code courtesy of Tim Mann.
 */

/* Accelerator table to compute the CRC eight bits at a time */
static const UInt16 ccitt_crc16_table[256] =
{
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7,
    0x8108, 0x9129, 0xA14A, 0xB16B, 0xC18C, 0xD1AD, 0xE1CE, 0xF1EF,
    0x1231, 0x0210, 0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6,
    0x9339, 0x8318, 0xB37B, 0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64E6, 0x74C7, 0x44A4, 0x5485,
    0xA56A, 0xB54B, 0x8528, 0x9509, 0xE5EE, 0xF5CF, 0xC5AC, 0xD58D,
    0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6, 0x5695, 0x46B4,
    0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D, 0xC7BC,
    0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840, 0x1861, 0x2802, 0x3823,
    0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B,
    0x5AF5, 0x4AD4, 0x7AB7, 0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12,
    0xDBFD, 0xCBDC, 0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A,
    0x6CA6, 0x7C87, 0x4CE4, 0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41,
    0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD, 0xAD2A, 0xBD0B, 0x8D68, 0x9D49,
    0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13, 0x2E32, 0x1E51, 0x0E70,
    0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B, 0xAF3A, 0x9F59, 0x8F78,
    0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E, 0xE16F,
    0x1080, 0x00A1, 0x30C2, 0x20E3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E,
    0x02B1, 0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256,
    0xB5EA, 0xA5CB, 0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C, 0xC50D,
    0x34E2, 0x24C3, 0x14A0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xA7DB, 0xB7FA, 0x8799, 0x97B8, 0xE75F, 0xF77E, 0xC71D, 0xD73C,
    0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657, 0x7676, 0x4615, 0x5634,
    0xD94C, 0xC96D, 0xF90E, 0xE92F, 0x99C8, 0x89E9, 0xB98A, 0xA9AB,
    0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882, 0x28A3,
    0xCB7D, 0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A,
    0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3, 0x3A92,
    0xFD2E, 0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9,
    0x7C26, 0x6C07, 0x5C64, 0x4C45, 0x3CA2, 0x2C83, 0x1CE0, 0x0CC1,
    0xEF1F, 0xFF3E, 0xCF5D, 0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8,
    0x6E17, 0x7E36, 0x4E55, 0x5E74, 0x2E93, 0x3EB2, 0x0ED1, 0x1EF0
};

UInt16 ccitt_crc16(UInt16 crc, const UInt8 *buffer, size_t buffer_len)
{
	size_t i;
	for (i = 0; i < buffer_len; i++)
		crc = (crc << 8) ^ ccitt_crc16_table[(crc >> 8) ^ buffer[i]];
	return crc;
}

UInt16 ccitt_crc16_one( UInt16 crc, const UInt8 data )
{
    return (crc << 8) ^ ccitt_crc16_table[(crc >> 8) ^ data];
}
