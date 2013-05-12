//
//  CoCoCassetteFileBlocker.m
//  Stream
//
//  Created by tim lindner on 4/13/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CoCoCassetteFileBlocker.h"
#import "StBlock.h"

@implementation CoCoCassetteFileBlocker

+ (NSString *)blockerName
{
    return @"CoCo Cassette File Blocker";
}

+ (NSString *)blockerKey
{
    return @"CoCoCassetteFileBlocker";
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
    NSAssert( [stream respondsToSelector:@selector(dataOfTopLevelBlockNamed:)] == YES, @"CoCoCassetteFileBlocker: Incompatiable stream" );
    int blockNumber = 0, fileNumber = 0;
    int noteFileType, noteDataType, noteGaps;
    
    /* Rummage thru data block building up files */
    
    noteFileType = -1;
    noteDataType = -1;
    noteGaps = -1;
    NSString *currentBlock = [NSString stringWithFormat:@"Block %d", blockNumber++];
    StBlock *theBlock = [stream topLevelBlockNamed:currentBlock];

    if( theBlock == nil ) return @"Could not find any \"Block\" blockes";
    
    NSData  *attributeDataObject = [theBlock getAttributeData];
    unsigned char *data = (unsigned char *)[attributeDataObject bytes];
    
    while (theBlock != nil)
    {
        if( [attributeDataObject length] > 0 && data[0] == 0x00 )
        {
            /* We found a start of a file! */
            StBlock *newFile = [stream startNewBlockNamed:[NSString stringWithFormat:@"File %d", fileNumber++] owner:[CoCoCassetteFileBlocker blockerKey]];
            NSData *dataBlock = [theBlock resultingData];
            unsigned char *dataBlockBytes = (unsigned char *)[dataBlock bytes];
            NSUInteger dataBlockSize = [dataBlock length];
            if( dataBlockSize > 7 ) [newFile addAttributeRange:currentBlock start:0 length:8 name:@"Filename" verification:nil transformation:@"RSDOSString"];
            if( dataBlockSize > 8 ) {
                [newFile addAttributeRange:currentBlock start:8 length:1 name:@"File Type" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                noteFileType = dataBlockBytes[8];
            }
            if( dataBlockSize > 9 ) {
                [newFile addAttributeRange:currentBlock start:9 length:1 name:@"Data Type" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                noteDataType = dataBlockBytes[9];
            }
            if( dataBlockSize > 10 ) {
                [newFile addAttributeRange:currentBlock start:10 length:1 name:@"Gaps" verification:nil transformation:@"BlocksUnsignedBigEndian"];
                noteGaps = dataBlockBytes[10];
            }
            if( dataBlockSize > 12 ) [newFile addAttributeRange:currentBlock start:11 length:2 name:@"ML Exec Address" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            if( dataBlockSize > 14 ) [newFile addAttributeRange:currentBlock start:13 length:2 name:@"ML Load Address" verification:nil transformation:@"BlocksUnsignedBigEndian"];

            /* Set up UTIs */
            if (noteFileType == 0 && noteDataType == 0) {
                newFile.sourceUTI = newFile.resultingUTI = @"com.microsoft.cocobasic.binary";
                newFile.currentEditorView = @"DeToken Binary CoCo BASIC";
            }
            else if (noteFileType == 0 && noteDataType == 0xff) {
                newFile.sourceUTI = newFile.resultingUTI = @"com.microsoft.cocobasic.ascii";
                newFile.currentEditorView = @"Text Editor";
            }
            else if (noteFileType == 0x01 && noteDataType == 0xff) {
                newFile.sourceUTI = newFile.resultingUTI = @"public.text";
                newFile.currentEditorView = @"Text Editor";
            }
            else if (noteFileType == 0x02 && noteDataType == 0 && noteGaps == 0) {
                newFile.sourceUTI = newFile.resultingUTI = @"com.microsoft.cocobasic.object";
                newFile.currentEditorView = @"6809 Dissasembler";
            }
            else if (noteFileType == 0x02 && noteDataType == 0 && noteGaps == 0xff) {
                newFile.sourceUTI = newFile.resultingUTI = @"com.microsoft.cocobasic.gapsobject";
                newFile.currentEditorView = @"6809 Dissasembler";
            }
            else {
                newFile.sourceUTI = newFile.resultingUTI = @"public.data";
            }
            
           currentBlock = [NSString stringWithFormat:@"Block %d", blockNumber++];
            theBlock = [stream topLevelBlockNamed:currentBlock];
            if( theBlock == nil ) break;
            attributeDataObject = [theBlock getAttributeData];
            data = (unsigned char *)[attributeDataObject bytes];
            
            while ([attributeDataObject length] > 0 && data[0] == 0x01) {
                [newFile addDataRange:currentBlock start:0 length:0];
                
                currentBlock = [NSString stringWithFormat:@"Block %d", blockNumber++];
                theBlock = [stream topLevelBlockNamed:currentBlock];
                
                if( theBlock == nil ) break;
                
                attributeDataObject = [theBlock getAttributeData];
                data = (unsigned char *)[attributeDataObject bytes];
            }
            
            if( theBlock == nil ) break;
         }
        
        if( data[0] == 0xff )
        {
            /* All is well, files successfully processed. Now onto the next file */
        }
        
        noteFileType = -1;
        noteDataType = -1;
        noteGaps = -1;
        
        currentBlock = [NSString stringWithFormat:@"Block %d", blockNumber++];
        theBlock = [stream topLevelBlockNamed:currentBlock];

        if( theBlock == nil ) break;

        attributeDataObject = [theBlock getAttributeData];
        data = (unsigned char *)[attributeDataObject bytes];
    }
    
    return @"";
 }

@end
