//
//  OS9FileBlocker.m
//  Stream
//
//  Created by tim lindner on 5/6/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "OS9FileBlocker.h"

NSString *DoFileFD( StStream *stream, NSString *fdLSN, NSString *blockName, unsigned short logicalSectorSize );

@implementation OS9FileBlocker

+ (NSString *)anayliserName
{
    return @"OS-9 File Blocker";
}

+ (NSString *)anaylizerKey
{
    return @"OS9FileBlocker";
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
    StBlock *lsn0block = [stream topLevelBlockNamed:@"LSN 0"];
    
    if (lsn0block == nil) {
        NSLog(@"OS-9 File Blocker: LSN 0 not found");
        return;
    }
    
    NSData *lsn0Data = [lsn0block getData];
    
    if (lsn0Data != nil && [lsn0Data length] > 0x0a) {
        const unsigned char *lsn0 = [lsn0Data bytes];
        unsigned short logicalSectorSizeCode = lsn0[0x69] << 8;
        logicalSectorSizeCode += lsn0[0x6a];
        unsigned short logicalSectorSize = logicalSectorSizeCode == 0 ? 256 : 256 * logicalSectorSizeCode;
        
        unsigned dd_dir = lsn0[0x08] << 24;
        dd_dir += lsn0[0x09] << 8;
        dd_dir += lsn0[0x0a];
        
        NSString *result = DoFileFD( stream, [NSString stringWithFormat:@"LSN %d", dd_dir], @"", logicalSectorSize );
        
        if (![result isEqualToString:@""]) {
            NSLog(@"%@", result);
        }
        
    }
    else {
        NSLog(@"OS-9 File Blocker: LSN 0 too short");
    }
}

@end

NSString *DoFileFD( StStream *stream, NSString *fdLSN, NSString *blockName, unsigned short logicalSectorSize )
{
    StBlock *fdBlock = [stream topLevelBlockNamed:fdLSN];
    NSData *fdData = [fdBlock getData];

    if (fdData != nil) {
        NSUInteger fdLength = [fdData length];
        const unsigned char *fd = [fdData bytes];
    
        if (fdLength > 0x01 && (fd[0x00] & 0x80) == 0x80) blockName = [blockName stringByAppendingString:@"/"];

        StBlock *newFileBlock = [stream startNewBlockNamed:[NSString stringWithFormat:blockName] owner:[OS9FileBlocker anaylizerKey]];
        newFileBlock.sourceUTI = newFileBlock.resultingUTI = @"public.data";
        
        if (fdLength > 0x01) [newFileBlock addAttributeRange:fdLSN start:0x00 length:1 name:@"fd.att" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        if (fdLength > 0x01 && (fd[0x00] & 0x80) == 0x80) newFileBlock.sourceUTI = newFileBlock.resultingUTI = @"com.microware.os9directoryfile";
        if (fdLength > 0x03) [newFileBlock addAttributeRange:fdLSN start:0x01 length:2 name:@"fd.own" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        if (fdLength > 0x08) [newFileBlock addAttributeRange:fdLSN start:0x03 length:5 name:@"fd.dat" verification:nil transformation:@"OS9Date"];
        if (fdLength > 0x09) [newFileBlock addAttributeRange:fdLSN start:0x08 length:1 name:@"fd.lnk" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        if (fdLength > 0x0d) [newFileBlock addAttributeRange:fdLSN start:0x09 length:4 name:@"fd.siz" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        if (fdLength > 0x10) [newFileBlock addAttributeRange:fdLSN start:0x0d length:3 name:@"fd.creat" verification:nil transformation:@"OS9Date"];
        
        unsigned long fileSize = fd[0x09];
        fileSize <<= 32;
        fileSize += fd[0x0a] << 24;
        fileSize += fd[0x0b] << 8;
        fileSize += fd[0x0c];
        
        if (fdLength > 0xff)
        {
            for (unsigned i=0; i < 48; i++) {
                NSString *fdSegLSNString = [NSString stringWithFormat:@"fd.seg[%d].lsn", i];
                [newFileBlock addAttributeRange:fdLSN start:0x10 + (i*5) + 0 length:3 name:fdSegLSNString verification:nil transformation:@"BlocksUnsignedBigEndian"];
                NSString *fdSegSizeString = [NSString stringWithFormat:@"fd.seg[%d].size", i];
                [newFileBlock addAttributeRange:fdLSN start:0x10 + (i*5) + 3 length:2 name:fdSegSizeString verification:nil transformation:@"BlocksUnsignedBigEndian"];
                
                unsigned lsn = fd[0x10 + (i*5) + 0] << 24;
                lsn += fd[0x10 + (i*5) + 1] << 8;
                lsn += fd[0x10 + (i*5) + 2];
                
                unsigned size = fd[0x10 + (i*5) + 3] << 8;
                size += fd[0x10 + (i*5) + 4];
                
                if (lsn > 0 && fileSize > 0) {
                    for (unsigned j=0; j<size; j++) {
                        NSString *segLSN = [NSString stringWithFormat:@"LSN %d", lsn + j];
                        unsigned actualSize = MIN(logicalSectorSize, fileSize);
                        [newFileBlock addDataRange:segLSN start:0 length:(actualSize == logicalSectorSize) ? 0 : fileSize expectedLength:actualSize];
                        fileSize -= actualSize;
                        
                        if (fileSize == 0) {
                            break;
                        }
                    }
                }
            }
        }
        
        if (fdLength > 0x01 && (fd[0x00] & 0x80) == 0x80)
        {
            NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:@"OS9String"];
            
            if (vt != nil) {
                StBlock *newDirBlock = newFileBlock;
                NSData *newDirData = [newDirBlock getData];
                NSUInteger newDirLength = [newDirData length], i=0;
                const unsigned char *bytes = [newDirData bytes];
                
                while (newDirLength > 0) {
                    if (bytes[i*32] != 0) {
                        NSString *filename = [vt transformedValue:[newDirData subdataWithRange:NSMakeRange(i * 32, 29)]];
                        unsigned lsn = bytes[(i * 32) + 29] << 24;
                        lsn += bytes[(i * 32) + 30] << 8;
                        lsn += bytes[(i * 32) + 31];
                        
                        if ([filename isEqualToString:@"."] || [filename isEqualToString:@".."]) {
                            /* Skip dot and souble dot files */
                        }
                        else {
                            NSString *fdLSN = [NSString stringWithFormat:@"LSN %d", lsn];
                            DoFileFD( stream, fdLSN, [blockName stringByAppendingString:filename], logicalSectorSize );
                        }
                    }
                    
                    i++;
                    newDirLength -= 32;
                }
            }
            else {
                return [NSString stringWithFormat:@"OS-9 File Blocker: could not create OS-9 String value transformer"];
            }
         }
    }
    else {
        return [NSString stringWithFormat:@"OS-9 File Blocker: Could not find block %@ while building block: %@", fdLSN, blockName];
    }
    
    return @"";
}
