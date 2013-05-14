//
//  OS9LogicalSectorsBlocker.m
//  Stream
//
//  Created by tim lindner on 5/5/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "OS9LogicalSectorsBlocker.h"
#import "StBlock.h"
#import "StAnaylizer.h"

@implementation OS9LogicalSectorsBlocker

+ (void)initialize
{
    if ( self == [OS9LogicalSectorsBlocker class] )
    {
        // Setup standard value transformers
		OS9StringTransformer *os9st;
		os9st = [[[OS9StringTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:os9st forName:@"OS9String"];		

        OS9DateTransformer *os9dt;
		os9dt = [[[OS9DateTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:os9dt forName:@"OS9Date"];		
    }
}

+ (NSString *)blockerName
{
    return @"OS-9 Logical Sectors Blocker";
}

+ (NSString *)blockerKey
{
    return @"OS9LogicalSectorsBlocker";
}

+ (NSString *)blockerPopoverAccessoryViewNib
{
    return @"OS9LogicalSectorsViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:@"5000", @"maxLSNCount", nil];
}

+ (NSString *)blockerGroup
{
    return @"OS-9";
}

- (NSString *) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
#pragma unused (anaylizer)
    unsigned sectorStartID;
    NSString *result = nil;
    
    NSString *firstSector = @"Track * 0 Side * 0 Sector * 0";
    NSString *alternateFirstSector = @"Track * 0 Side * 0 Sector * 1";
    NSString *firstTrack = @"Track * 0 Side * 0 Sector * %d";
    NSString *genericTrack = @"Track * %d Side * %d Sector * %d";
    
    StBlock *lsn0Block = [stream topLevelBlockNamed:firstSector];
    
    if (lsn0Block == nil) {
        lsn0Block = [stream topLevelBlockNamed:alternateFirstSector];
        
        if (lsn0Block == nil) {
            return @"Could not find LSN0";
        }
        else {
            firstSector = alternateFirstSector;
            sectorStartID = 1;
        }
    }
    else {
        sectorStartID = 0;
    }
    
    NSData *lsn0Data = [lsn0Block resultingData];
    const unsigned char *lsn0 = [lsn0Data bytes];
    
    if ([lsn0Data length] < 0x6d) {
        return @"LSN 0 too short.";
    }

    NSUInteger maxLSNCount = [[anaylizer.optionsDictionary valueForKeyPath:@"OS9LogicalSectorsBlocker.maxLSNCount"] intValue];
    
    StBlock *newLSN = [stream startNewBlockNamed:[NSString stringWithFormat:@"LSN 0"] owner:[OS9LogicalSectorsBlocker blockerKey]];
  
    [newLSN addAttributeRange:firstSector start:0x0 length:3 name:@"dd.tot" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x3 length:1 name:@"dd.tks" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x4 length:2 name:@"dd.map" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x6 length:2 name:@"dd.bit" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x8 length:3 name:@"dd.dir" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0xb length:2 name:@"dd.own" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0xd length:1 name:@"dd.att" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0xe length:2 name:@"dd.dsk" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x10 length:1 name:@"dd.fmt" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x11 length:2 name:@"dd.spt" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x13 length:2 name:@"dd.res" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x15 length:3 name:@"dd.bt" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x18 length:2 name:@"dd.bsz" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x1a length:5 name:@"dd.dat" verification:nil transformation:@"OS9Date"];
    [newLSN addAttributeRange:firstSector start:0x1f length:32 name:@"dd.nam" verification:nil transformation:@"OS9String"];

    [newLSN addAttributeRange:firstSector start:0x40 length:1 name:@"pd.dtp" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x41 length:1 name:@"pd.drv" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x42 length:1 name:@"pd.stp" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x43 length:1 name:@"pd.typ" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x44 length:1 name:@"pd.dns" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x45 length:2 name:@"pd.cyl" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x47 length:1 name:@"pd.sid" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x48 length:1 name:@"pd.vfy" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x49 length:2 name:@"pd.sct" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x4b length:2 name:@"pd.t0s" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x4d length:1 name:@"pd.ilv" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x4e length:1 name:@"pd.sas" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x4f length:1 name:@"pd.tfm" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x50 length:2 name:@"pd.exten" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x52 length:1 name:@"pd.stoff" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x53 length:1 name:@"pd.att" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x54 length:3 name:@"pd.fd" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x57 length:3 name:@"pd.dfd" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x5a length:4 name:@"pd.dcp" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x5e length:2 name:@"ps.dvt" verification:nil transformation:@"BlocksUnsignedBigEndian"];
   
    [newLSN addAttributeRange:firstSector start:0x60 length:1 name:@"dd.res1" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x61 length:4 name:@"dd.sync" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x65 length:4 name:@"dd.maplsn" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x69 length:2 name:@"dd.lsnsize" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    [newLSN addAttributeRange:firstSector start:0x6b length:2 name:@"dd.versid" verification:nil transformation:@"BlocksUnsignedBigEndian"];
    
    /* create bipmap block */
    
    unsigned short bitmapSize = lsn0[4] << 8;
    bitmapSize += lsn0[5];
    
    unsigned short logicalSectorSizeCode = lsn0[0x69] << 8;
    logicalSectorSizeCode += lsn0[0x6a];
    
    unsigned short logicalSectorSize = logicalSectorSizeCode == 0 ? 256 : 256 * logicalSectorSizeCode;
    
    [newLSN addDataRange:firstSector start:0 length:0 expectedLength:logicalSectorSize];

    NSUInteger i, j;
    NSString *sectorName;
    
    StBlock *fat = [stream startNewBlockNamed:[NSString stringWithFormat:@"File Allocation Bitmap"] owner:[OS9LogicalSectorsBlocker blockerKey]];
    
    i=bitmapSize;
    j=1 + sectorStartID;
    
    while (i > logicalSectorSize) {
        sectorName = [NSString stringWithFormat:firstTrack, j];
        [fat addDataRange:sectorName start:0 length:0 expectedLength:logicalSectorSize];
        
        i -= logicalSectorSize;
        j++;
    }
    
    sectorName = [NSString stringWithFormat:firstTrack, j];
    [fat addDataRange:sectorName start:0 length:i];
    
    /* now generate all of track zeros LSNs (track zero, side zero is special, it can be short) */
    
    unsigned track, trackSizeInSectors, sector, side, lsnNumber;
    NSString *blockName;
    
    trackSizeInSectors = lsn0[0x3];
    track = 0;
    sector = 1 + sectorStartID;
    side = 0;
    lsnNumber = 1;
    
    unsigned char trackZeroSize = lsn0[0x4b];
    
    for (i=1; i<trackZeroSize; i++) {
        blockName = [NSString stringWithFormat:@"LSN %d", lsnNumber];
        sectorName = [NSString stringWithFormat:firstTrack, sector];
        newLSN = [stream startNewBlockNamed:blockName owner:[OS9LogicalSectorsBlocker blockerKey]];
        [newLSN addDataRange:sectorName start:0 length:0 expectedLength:logicalSectorSize];
        
        lsnNumber++;
        sector++;
    }
    
    side++;
    
    /* now generate the rest of the logical sectors */

    NSUInteger totalSectorCount = (lsn0[0] << 16) + (lsn0[1] << 8) + lsn0[2];

    if (totalSectorCount > maxLSNCount) {
        result = [NSString stringWithFormat:@"Stopped short at LSN %d. Maximum specified in stream: LSN %d", maxLSNCount, totalSectorCount];
    }
    totalSectorCount = MIN(maxLSNCount, totalSectorCount);
    
    unsigned sides = lsn0[0x10] & 1;
    
    while( lsnNumber < totalSectorCount )
    {
//        NSLog(@"Doing LSN #%d", lsnNumber);
        
        if (side > sides) {
            side = 0;
            track++;
        }
        
        for (sector=sectorStartID; sector<trackSizeInSectors + sectorStartID; sector++) {
            blockName = [NSString stringWithFormat:@"LSN %d", lsnNumber];
            sectorName = [NSString stringWithFormat:genericTrack, track, side, sector];
            newLSN = [stream startNewBlockNamed:blockName owner:[OS9LogicalSectorsBlocker blockerKey]];
            [newLSN addDataRange:sectorName start:0 length:0 expectedLength:logicalSectorSize];
            
            lsnNumber++;
            
            if (lsnNumber >= totalSectorCount) {
                break;
            }
        }
        
        side++;
    }
    
    return result;
}

@end

@implementation OS9StringTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(NSData *)value
{
	// NSData (OS-9 String) -> NSString
    
	if ([value respondsToSelector: @selector(bytes)])
	{
		// OS-9 strings are fixed length, the last character has it's high bit set.
        
		size_t length = [value length];
		char *buffer = (char *)malloc( length+1 );
		if( buffer != NULL )
		{
			const char *src = [value bytes];
            size_t i = 0;
            while( i < length )
            {
                buffer[i] = src[i];
            
                if ((src[i] & 0x80) == 0x80) {
                    buffer[i] = src[i] & 0x7f;
                    buffer[i+1] = 0;
                    break;
                }
            
                i++;
            }
            
            buffer[i+1] = 0;
            
			NSString *result = [NSString stringWithCString:buffer encoding:[NSString defaultCStringEncoding]];
			free(buffer);
			
			return result;
		}
	}
	
	return nil;
}
- (id)reverseTransformedValue:(id)value
{
	return [self reverseTransformedValue:value ofSize:0];
}

- (id)reverseTransformedValue:(id)value ofSize:(size_t)size
{
	// NSString -> NSData (OS-9 String)
    
	if ([value respondsToSelector: @selector(cStringUsingEncoding:)])
	{
		const char *buffer = [value cStringUsingEncoding:[NSString defaultCStringEncoding]];
		size_t buffer_length = strlen( buffer );
		
		if( size == 0 )
			size = buffer_length;
		
		char *result_buffer = malloc( size );
		
		memcpy(result_buffer, buffer, MIN(buffer_length, size) );
		result_buffer[buffer_length-1] = result_buffer[buffer_length-1] | 0x80;
        
		return [NSData dataWithBytesNoCopy:result_buffer length:size];
	}
    
	return nil;
}

@end

NSString *OS9Date_Months[] = {@"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec" };
@implementation OS9DateTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(NSData *)value
{
	// NSData (OS-9 Date) -> NSString
    NSString *result;
    
	if ([value respondsToSelector: @selector(bytes)])
	{
		// OS-9 strings are fixed length, the last character has it's high bit set.
        
		size_t length = [value length];
        unsigned char *src = (unsigned char *)[value bytes];
        
        if (length > 1 && src[1] > 11) {
            src[1] = 11;
        }
        
        if (length == 1) {
            result = [NSString stringWithFormat:@"%d", src[0]+1900];
        }
        else if (length == 2) {
            result = [NSString stringWithFormat:@"%d:%@", src[0]+1900, OS9Date_Months[src[1]]];
        }
        else if (length == 3) {
            result = [NSString stringWithFormat:@"%d:%@:%d", src[0]+1900, OS9Date_Months[src[1]], src[2]];
        }
        else if (length == 4) {
            result = [NSString stringWithFormat:@"%d:%@:%d:%d", src[0]+1900, OS9Date_Months[src[1]], src[2], src[3]];
        }
        else if (length > 4) {
            result = [NSString stringWithFormat:@"%d:%@:%d:%d:%d", src[0]+1900, OS9Date_Months[src[1]], src[2], src[3], src[4]];
        }
        else {
            result = @"Unknown";
        }
	}
    else {
        result = @"Unknown";
    }
	
	return result;
}
- (id)reverseTransformedValue:(id)value
{
	return [self reverseTransformedValue:value ofSize:5];
}

- (id)reverseTransformedValue:(id)value ofSize:(size_t)size
{
	// NSString -> NSData (OS-9 Data)
    
	if ([value respondsToSelector: @selector(cStringUsingEncoding:)])
	{
        NSCharacterSet *colonSet = [NSCharacterSet characterSetWithCharactersInString:@":"];
        NSScanner *scanner = [NSScanner scannerWithString:value];
        [scanner setCharactersToBeSkipped:colonSet];
        unsigned char data[5];
        
        int year = 0;
        NSString *monthString = @"Jan";
        int day = 0;
        int hour = 0;
        int minute = 0;
        
        BOOL yearSuccess;
        BOOL monthSuccess;
        BOOL daySuccess;
        BOOL hourSuccess;
        BOOL minuteSuccess;
        
        yearSuccess = [scanner scanInt:&year];
        monthSuccess = [scanner scanUpToString:@":" intoString:&monthString];
        daySuccess = [scanner scanInt:&day];
        hourSuccess = [scanner scanInt:&hour];
        minuteSuccess = [scanner scanInt:&minute];
        
        if (yearSuccess) {
            data[0] = 1900 - year;
        }
        
        if (monthSuccess) {
            int i = 0;
            while (i<12) {
                if ([monthString isEqualToString:OS9Date_Months[i]]) {
                    data[1] = i;
                    break;
                }
            }
        }
        
        if (daySuccess) {
            data[2] = day;
        }
        
        if (hourSuccess) {
            data[3] = hourSuccess;
        }
        
        if (minuteSuccess) {
            data[4] = minute;
        }

		return [NSData dataWithBytes:data length:MIN(size,(unsigned)5)];
	}
    
	return nil;
}

@end
