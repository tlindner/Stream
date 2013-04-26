//
//  CoCoCassetteFileBlocker.m
//  Stream
//
//  Created by tim lindner on 4/13/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CoCoCassetteFileBlocker.h"

@implementation CoCoCassetteFileBlocker


+ (NSString *)anayliserName
{
    return @"Color Computer Cassette File Blocker";
}

+ (NSString *)anaylizerKey
{
    return @"CoCoCassetteFileBlocker";
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
    NSAssert( [stream respondsToSelector:@selector(dataOfBlockNamed:)] == YES, @"CoCoCassetteFileBlocker: Incompatiable stream" );
    int blockNumber = 0, fileNumber = 0;
    
    /* Rummage thru data block building up files */
     
    NSString *currentBlock = [NSString stringWithFormat:@"Block %d", blockNumber++];
    StBlock *theBlock = [stream blockNamed:currentBlock];

    if( theBlock == nil ) return;
    
    NSData  *attributeDataObject = [theBlock getAttributeData];
    unsigned char *data = (unsigned char *)[attributeDataObject bytes];
    
    while (theBlock != nil)
    {
        if( [attributeDataObject length] > 0 && data[0] == 0x00 )
        {
            /* We found a start of a file! */
            StBlock *newFile = [stream startNewBlockNamed:[NSString stringWithFormat:@"File %d", fileNumber++] owner:[CoCoCassetteFileBlocker anaylizerKey]];
            NSUInteger dataBlockSize = [[theBlock getData] length];
            if( dataBlockSize > 7 ) [newFile addAttributeRange:currentBlock start:0 length:8 name:@"Filename" verification:nil transformation:@"RSDOSString"];
            if( dataBlockSize > 8 ) [newFile addAttributeRange:currentBlock start:8 length:1 name:@"File Type" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            if( dataBlockSize > 9 ) [newFile addAttributeRange:currentBlock start:9 length:1 name:@"Data Type" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            if( dataBlockSize > 10 ) [newFile addAttributeRange:currentBlock start:10 length:1 name:@"Gaps" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            if( dataBlockSize > 12 ) [newFile addAttributeRange:currentBlock start:11 length:2 name:@"ML Exec Address" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            if( dataBlockSize > 14 ) [newFile addAttributeRange:currentBlock start:13 length:2 name:@"ML Load Address" verification:nil transformation:@"BlocksUnsignedBigEndian"];

            currentBlock = [NSString stringWithFormat:@"Block %d", blockNumber++];
            theBlock = [stream blockNamed:currentBlock];
            if( theBlock == nil ) break;
            attributeDataObject = [theBlock getAttributeData];
            data = (unsigned char *)[attributeDataObject bytes];
            
            while ([attributeDataObject length] > 0 && data[0] == 0x01) {
                [newFile addDataRange:currentBlock start:0 length:0];
                
                currentBlock = [NSString stringWithFormat:@"Block %d", blockNumber++];
                theBlock = [stream blockNamed:currentBlock];
                
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
        
        /* Set up source UTI */
        
        currentBlock = [NSString stringWithFormat:@"Block %d", blockNumber++];
        theBlock = [stream blockNamed:currentBlock];

        if( theBlock == nil ) break;

        attributeDataObject = [theBlock getAttributeData];
        data = (unsigned char *)[attributeDataObject bytes];
    }
 }

@end
