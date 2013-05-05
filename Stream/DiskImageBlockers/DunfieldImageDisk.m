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

+ (NSString *)anayliserName
{
    return @"Dunfield Image Disk Blocker";
}

+ (NSString *)anaylizerKey
{
    return @"DunfieldImageDisk";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return nil;
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] init] autorelease];
}

+ (void) makeBlocks:(StStream *)stream
{
    NSAssert( [stream respondsToSelector:@selector(dataOfTopLevelBlockNamed:)] == YES, @"DunfieldImageDisk: Incompatiable stream" );
    
    NSData  *streamBytesObject = [stream dataOfTopLevelBlockNamed:@"stream"];
    NSAssert( streamBytesObject != nil, @"DunfieldImageDisk: no stream object" );
    
    unsigned char *streamBytes = (unsigned char *)[streamBytesObject bytes];
    NSAssert( streamBytes != nil, @"DunfieldImageDisk: no stream bytes");

    NSUInteger length = [streamBytesObject length];

    if (length < 4) {
        NSLog( @"DunfieldImageDisk: buffer too short to anaylize" );
        return;
    }

    if (streamBytes[0] == 'I' && streamBytes[1] == 'M' && streamBytes[2] == 'D') {

        NSUInteger i=0;
        
        while (i < length) {
            if (streamBytes[i++] == 0x1a) break;
        }
 
        if (streamBytes[i-1] != 0x1a) {
            NSLog( @"DunfieldImageDisk: did not find note field" );
            return;
        }
        
        StBlock *newBlock = [stream startNewBlockNamed:@"Note" owner:[DunfieldImageDisk anaylizerKey]];
        [newBlock addDataRange:@"stream" start:0 length:i-1];
        newBlock.sourceUTI = newBlock.resultingUTI = @"public.text";

        while (i < length) {
            unsigned char sectorTable[256];
            unsigned char mode = streamBytes[i++];
            unsigned char cylinder = streamBytes[i++];
            unsigned char head = streamBytes[i++];
            unsigned char sectorCount = streamBytes[i++];
            unsigned char sectorSizeCode = streamBytes[i++];
            
//            NSLog(@"mode: %d, cylinder: %d, head: %d, sector count: %d, sector size code: %d", mode, cylinder, head, sectorCount, sectorSizeCode);

            if (sectorSizeCode == 0xff) {
                NSLog(@"DunfieldImageDisk: Un implemented sector size map");
                return;
            }
            
            NSUInteger sectorSize = CalculateSectorSize( sectorSizeCode );

            [newBlock addAttributeRange:@"stream" start:i-5 length:1 name:@"Mode" verification:nil transformation:@"BlocksUnsignedBigEndian"];

            for (NSUInteger j=0; j < sectorCount ; j++ ) {
                sectorTable[j] = streamBytes[i++];
            }
            
            if ((head & 0x80) == 0x80) {
                NSLog(@"DunfieldImageDisk: Un implemented sector cylinder map");
                return;
            }
            
            if ((head & 0x40) == 0x40) {
                NSLog(@"DunfieldImageDisk: Un implemented sector head map");
                return;
            }
            
            for (NSUInteger j=0; j < sectorCount; j++) {
                unsigned char sectorType = streamBytes[i++], sectorIdealType;
                NSString *blockName;
                NSUInteger actualLength;
                
                switch (sectorType) {
                    case 0:
                        /* sector data unavaiable */
                        sectorIdealType = 1;
                        blockName = [NSString stringWithFormat:@"Track %d Side %d Sector %d %d", cylinder, head & 0x01, j, sectorTable[j]];
                        newBlock = [stream startNewBlockNamed:blockName owner:[DunfieldImageDisk anaylizerKey]];
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
                        blockName = [NSString stringWithFormat:@"Track %d Side %d Sector %d %d", cylinder, head & 0x01, j, sectorTable[j]];
                        newBlock = [stream startNewBlockNamed:blockName owner:[DunfieldImageDisk anaylizerKey]];
                        actualLength = MIN(sectorSize, length - i);
                        [newBlock addDataRange:@"stream" start:i length:actualLength name:nil verification:nil transformation:nil expectedLength:sectorSize repeat:NO];
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
                        blockName = [NSString stringWithFormat:@"Track %d Side %d Sector %d %d", cylinder, head & 0x01, j, sectorTable[j]];
                        newBlock = [stream startNewBlockNamed:blockName owner:[DunfieldImageDisk anaylizerKey]];
                        actualLength = MIN(sectorSize, length - i);

                        [newBlock addDataRange:@"stream" start:i length:1 expectedLength:sectorSize repeat:YES];
                        [newBlock addAttributeRange:@"stream" start:i-1 length:1 name:@"Sector Type" verification:[NSData dataWithBytes:&sectorIdealType length:1] transformation:@"BlocksUnsignedBigEndian"];
                        newBlock.sourceUTI = newBlock.resultingUTI = @"public.data";
                        i++;
                        break;
                        
                    default:
                        NSLog(@"DunfieldImageDisk: Unexpected sector type: %d, byte: 0x%lx", sectorType, i-1);
                        return;
                        break;
                        
                }
            }
        }
    }
    else {
        NSLog( @"DunfieldImageDisk: stream does not start with the magic bytes." );
    }
}

@end

NSUInteger CalculateSectorSize( unsigned char value )
{
    if (value > 6) value = 6;
    return 128 << value;
}
