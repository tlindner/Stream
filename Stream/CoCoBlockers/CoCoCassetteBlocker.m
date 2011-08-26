//
//  CoCoCassetteBlocker.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CoCoCassetteBlocker.h"

@implementation CoCoCassetteBlocker

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (void) makeBlocks:(StStream *)stream
{
    NSLog( @"stream: %@", stream );
    
    NSAssert( [stream respondsToSelector:@selector(blockNamed:)] == YES, @"CoCoCassetteBlocker: Incompatiable stream" );
    
    NSData  *streamBytesObject = [stream blockNamed:@"stream"];
    NSAssert( streamBytesObject != nil, @"CoCoCassetteBlocker: no stream object" );
    
    unsigned char *streamBytes = (unsigned char *)[streamBytesObject bytes];
    NSAssert( streamBytes != nil, @"CoCoCassetteBlocker: no stream bytes");
    
    NSUInteger length = [streamBytesObject length];
    
    if( length < 3 )
    {
        NSLog( @"CoCoCassetteBlocker: buffer too short to anaylize" );
        return;
    }
    
    int blockName = 0;
    UInt16 header = streamBytes[0];
    
    for( NSUInteger i=1; i<length; i++ )
    {
        /* look for 0x553c */
        header <<= 8;
        header += streamBytes[i];
        
        if( (header & 0x0fff) == 0x053c )
        {
            /* we found a header */
            
            StBlock *newBlock = [stream startNewBlockNamed:[NSString stringWithFormat:@"Block %d", blockName++] owner:[CoCoCassetteBlocker anaylizerKey]];
            
            //unsigned char blockType = streamBytes[i+1];
            unsigned char checksumCheck = 0x55;
            unsigned char fixed = 0x55;
            NSUInteger blockLength = streamBytes[i+2];
            
            for( NSUInteger j=i+1; j<i+2+blockLength; j++ ) checksumCheck += streamBytes[j];

            [newBlock addAttributeRange:@"stream" start:i length:1 name:@"Block Type"];
            [newBlock addAttributeRange:@"stream" start:i+blockLength+1 length:1 name:@"Check Sum" verification:[NSData dataWithBytes:&checksumCheck length:1]];
            [newBlock addAttributeRange:@"stream" start:i+blockLength+2 length:1 name:@"Fixed" verification:[NSData dataWithBytes:&fixed length:1]];
            
            [newBlock addDataRange:@"stream" start:i+3 length:blockLength];
            
            i += 1 + blockLength + 2;
        }
    }
}

+ (NSString *)anayliserName
{
    return @"Color Computer Cassette Blocker";
}

+ (NSString *)anaylizerKey
{
    return @"ColorComputerCassetteBlocker";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return nil;
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] init] autorelease];
}

@end
