//
//  OS9FileBlocker.m
//  Stream
//
//  Created by tim lindner on 5/6/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "OS9FileBlocker.h"
#import "StBlock.h"

BOOL IsTextFileBasedOnName( NSString *filename );

NSString *DoFileFD( NSMutableIndexSet *processedLSNs, NSUInteger dd_tot,  StStream *stream, NSString *fdLSN, NSString *blockName, unsigned short logicalSectorSize );

@implementation OS9FileBlocker

+ (NSString *)blockerName
{
    return @"OS-9 File Blocker";
}

+ (NSString *)blockerKey
{
    return @"OS9FileBlocker";
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
    return @"OS-9";
}

- (id)init
{
    self = [super init];
    if (self) {
        processedLSNs = [[NSMutableIndexSet alloc] init];
    }
    return self;
}

- (NSString *) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer
{
#pragma unused (anaylizer)
    NSString *result = nil;
    StBlock *lsn0block = [stream topLevelBlockNamed:@"LSN 0"];
    
    if (lsn0block == nil) {
        return @"LSN 0 not found.";
//        return @"LSN 0 not found. Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
    }
    
    NSData *lsn0Data = [lsn0block resultingData];
    
    if (lsn0Data != nil && [lsn0Data length] > 0x0a) {
        const unsigned char *lsn0 = [lsn0Data bytes];
        unsigned short logicalSectorSizeCode = lsn0[0x69] << 8;
        logicalSectorSizeCode += lsn0[0x6a];
        unsigned short logicalSectorSize = logicalSectorSizeCode == 0 ? 256 : 256 * logicalSectorSizeCode;
        
        unsigned dd_dir = lsn0[0x08] << 16;
        dd_dir += lsn0[0x09] << 8;
        dd_dir += lsn0[0x0a];
        
        NSUInteger dd_tot = (lsn0[0] << 16) + (lsn0[1] << 8) + lsn0[2];
        
        if (![processedLSNs containsIndex:dd_dir]) {
            [processedLSNs addIndex:dd_dir];
            result = DoFileFD( processedLSNs, dd_tot, stream, [NSString stringWithFormat:@"LSN %d", dd_dir], @"", logicalSectorSize );
        }
        else {
            result = @"\nFile descriptor LSN %d seen more than once.";
        }
    }
    else {
        result =  @"LSN 0 too short";
    }
    
    return result;
}

- (void)dealloc
{
    [processedLSNs release];
    
    [super dealloc];
}

@end

NSString *DoFileFD( NSMutableIndexSet *processedLSNs, NSUInteger dd_tot, StStream *stream, NSString *fdLSN, NSString *blockName, unsigned short logicalSectorSize )
{
    StBlock *fdBlock = [stream topLevelBlockNamed:fdLSN];
    NSData *fdData = [fdBlock resultingData];
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    
    if (fdData != nil) {
        NSUInteger fdLength = [fdData length];
        const unsigned char *fd = [fdData bytes];
        NSString *testNewBlockName = blockName;
        NSString *useEditorView, *useUTI;
        
        if (fdLength > 0x01 && (fd[0x00] & 0x80) == 0x80) testNewBlockName = [testNewBlockName stringByAppendingString:@"/"];

        if (IsTextFileBasedOnName( testNewBlockName )) {
            useEditorView = @"Text Editor";
            useUTI = @"public.text";
        }
        else {
            useEditorView = @"Hex Editor";
            useUTI = @"public.data";
        }
            
        StBlock *newFileBlock = [stream startNewBlockNamed:testNewBlockName owner:[OS9FileBlocker blockerKey]];
        
        int dupeFileIndex = 1;
        blockName = testNewBlockName;
        while (newFileBlock == nil) {
            blockName = [testNewBlockName stringByAppendingFormat:@" [%d]", dupeFileIndex++];
            newFileBlock = [stream startNewBlockNamed:blockName owner:[OS9FileBlocker blockerKey]];
        }
        
        newFileBlock.currentEditorView = useEditorView;
        newFileBlock.sourceUTI = newFileBlock.resultingUTI = useUTI;
        
        if (fdLength > 0x01) [newFileBlock addAttributeRange:fdLSN start:0x00 length:1 name:@"fd.att" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        if (fdLength > 0x01 && (fd[0x00] & 0x80) == 0x80) {
            newFileBlock.sourceUTI = newFileBlock.resultingUTI = @"com.microware.os9directoryfile";
            newFileBlock.currentEditorView = @"OS9 Directory File";
        }
        if (fdLength > 0x03) [newFileBlock addAttributeRange:fdLSN start:0x01 length:2 name:@"fd.own" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        if (fdLength > 0x08) [newFileBlock addAttributeRange:fdLSN start:0x03 length:5 name:@"fd.dat" verification:nil transformation:@"OS9Date"];
        if (fdLength > 0x09) [newFileBlock addAttributeRange:fdLSN start:0x08 length:1 name:@"fd.lnk" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        if (fdLength > 0x0d) [newFileBlock addAttributeRange:fdLSN start:0x09 length:4 name:@"fd.siz" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        if (fdLength > 0x10) [newFileBlock addAttributeRange:fdLSN start:0x0d length:3 name:@"fd.creat" verification:nil transformation:@"OS9Date"];
        
        unsigned long fileSize = fd[0x09];
        fileSize <<= 24;
        fileSize += fd[0x0a] << 16;
        fileSize += fd[0x0b] << 8;
        fileSize += fd[0x0c];
        
        if (fdLength > 0xff)
        {
            for (unsigned i=0; i < 48; i++) {
                
                unsigned lsn = (fd[0x10 + (i*5) + 0]) << 16;
                lsn += (fd[0x10 + (i*5) + 1]) << 8;
                lsn += fd[0x10 + (i*5) + 2];
                
                unsigned size = (fd[0x10 + (i*5) + 3]) << 8;
                size += fd[0x10 + (i*5) + 4];
                
                if (lsn == 0) break;
                
                NSString *fdSegLSNString = [NSString stringWithFormat:@"fd.seg[%d].lsn", i];
                [newFileBlock addAttributeRange:fdLSN start:0x10 + (i*5) + 0 length:3 name:fdSegLSNString verification:nil transformation:@"BlocksUnsignedBigEndian"];
                NSString *fdSegSizeString = [NSString stringWithFormat:@"fd.seg[%d].size", i];
                [newFileBlock addAttributeRange:fdLSN start:0x10 + (i*5) + 3 length:2 name:fdSegSizeString verification:nil transformation:@"BlocksUnsignedBigEndian"];

                if (lsn+size > dd_tot) {
                    [result appendFormat:@"\nFile: %@ had bad segment %d, length past end of logical sectors: %d", blockName, i, lsn+size];
                    break;
                }
           
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
        
        if (fdLength > 0x01 && (fd[0x00] & 0x80) == 0x80)
        {
            NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:@"OS9String"];
            
            if (vt != nil) {
                StBlock *newDirBlock = newFileBlock;
                NSData *newDirData = [newDirBlock resultingData];
                NSUInteger newDirLength = [newDirData length], i=0;
                const unsigned char *bytes = [newDirData bytes];
                
                while (newDirLength > 0) {
                    if (bytes[i*32] != 0) {
                        NSString *filename = [vt transformedValue:[newDirData subdataWithRange:NSMakeRange(i * 32, 29)]];
                        unsigned lsn = bytes[(i * 32) + 29] << 16;
                        lsn += bytes[(i * 32) + 30] << 8;
                        lsn += bytes[(i * 32) + 31];
                        
                        if ([filename isEqualToString:@"."] || [filename isEqualToString:@".."]) {
                            /* Skip dot and souble dot files */
                            i++;
                            newDirLength -= 32;
                            continue;
                        }
                        
                        if (lsn > dd_tot) {
                            [result appendFormat:@"\nFile: %@, file descriptor sector (%d) past end of image (%d)", filename, lsn, dd_tot];
                            i++;
                            newDirLength -= 32;
                            continue;
                        }
                        
                        NSString *fdLSN = [NSString stringWithFormat:@"LSN %d", lsn];

                        if (![processedLSNs containsIndex:lsn]) {
                            [processedLSNs addIndex:lsn];
                            [result appendString:DoFileFD( processedLSNs, dd_tot, stream, fdLSN, [blockName stringByAppendingString:filename], logicalSectorSize )];
                        }
                        else {
                            [result appendString:@"\nFile descriptor LSN %d seen more than once."];
                        }
                    }
                    
                    i++;
                    newDirLength -= 32;
                }
            }
            else {
                [result appendString:@"\nCould not create OS-9 String value transformer"];
            }
         }
    }
    else {
        [result appendFormat:@"\nCould not find block %@ while building block: %@", fdLSN, blockName];
    }
    
    return result;
}

BOOL IsTextFileBasedOnName( NSString *filename )
{
    if ([filename hasSuffix:@".asm"]) {
        return YES;
    }
    else if ([filename hasSuffix:@".a"]) {
        return YES;
    }
    else if ([filename hasSuffix:@".txt"]) {
        return YES;
    }
    else if ([filename hasSuffix:@"defs"]) {
        return YES;
    }
    else if ([filename hasSuffix:@".c"]) {
        return YES;
    }
    else if ([filename hasSuffix:@".lp"]) {
        return YES;
    }
    else if ([filename hasSuffix:@".notes"]) {
        return YES;
    }
    else if ([filename hasSuffix:@".doc"]) {
        return YES;
    }
    else if ([filename hasSuffix:@".hlp"]) {
        return YES;
    }
    else if ([filename hasSuffix:@".me"]) {
        return YES;
    }
    
    return NO;
}





