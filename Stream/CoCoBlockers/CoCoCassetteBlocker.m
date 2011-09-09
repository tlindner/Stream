//
//  CoCoCassetteBlocker.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CoCoCassetteBlocker.h"

static const int endianTable[] = { 1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14 };

@implementation CoCoCassetteBlocker

+ (void)initialize
{
    if ( self == [CoCoCassetteBlocker class] )
    {
        // Setup standard value transformers
		RSDOSStringTransformer *RSDS;
		RSDS = [[[RSDOSStringTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:RSDS forName:@"RSDOSString"];		
        
        UnsignedBigEndianTransformer *UBE;
		UBE = [[[UnsignedBigEndianTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:UBE forName:@"BlocksUnsignedBigEndian"];		
		
		UnsignedLittleEndianTransformer *ULE;
		ULE = [[[UnsignedLittleEndianTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:ULE forName:@"BlocksUnsignedLittleEndian"];		
    }
}

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
            
            unsigned char blockType = streamBytes[i+1];
            unsigned char checksumCheck = 0;
            unsigned char fixed = 0x55;
            NSUInteger blockLength = streamBytes[i+2];
            
            for( NSUInteger j=i+1; j<i+3+blockLength; j++ ) checksumCheck += streamBytes[j];

            [newBlock addAttributeRange:@"stream" start:i+1 length:1 name:@"Block Type" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            [newBlock addAttributeRange:@"stream" start:i+2 length:1 name:@"Length" verification:nil transformation:@"BlocksUnsignedBigEndian"];
            [newBlock addAttributeRange:@"stream" start:i+blockLength+3 length:1 name:@"Check Sum" verification:[NSData dataWithBytes:&checksumCheck length:1] transformation:@"BlocksUnsignedBigEndian"];
            [newBlock addAttributeRange:@"stream" start:i+blockLength+4 length:1 name:@"Fixed" verification:[NSData dataWithBytes:&fixed length:1] transformation:@"BlocksUnsignedBigEndian"];
            
            if( (blockType == 0) && (blockLength == 0x0f) )
            {
                [newBlock addDataRange:@"stream" start:i+3 length:8 name:@"File Name" transformation:@"RSDOSString"];
                [newBlock addDataRange:@"stream" start:i+11 length:1 name:@"File Type" transformation:@"BlocksUnsignedBigEndian"];
                [newBlock addDataRange:@"stream" start:i+12 length:1 name:@"Data Type" transformation:@"BlocksUnsignedBigEndian"];
                [newBlock addDataRange:@"stream" start:i+13 length:1 name:@"Gaps" transformation:@"BlocksUnsignedBigEndian"];
                [newBlock addDataRange:@"stream" start:i+14 length:2 name:@"ML Load Address" transformation:@"BlocksUnsignedBigEndian"];
                [newBlock addDataRange:@"stream" start:i+16 length:2 name:@"ML Exec Addr" transformation:@"BlocksUnsignedBigEndian"];
            }
            else
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
    return @"CoCoCassetteBlocker";
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

@implementation RSDOSStringTransformer

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
	// NSData (RSDOS String) -> NSString
    
	if ([value respondsToSelector: @selector(bytes)])
	{
		// RSDOS strings are fixed length, padded with right hand spaces (0x20).
        
		size_t length = [value length];
		char *buffer = (char *)calloc( 1, length+1 );
		if( buffer != NULL )
		{
			const char *src = [value bytes] + length-1;
			char *dst = buffer + length-1;
			BOOL flag = YES;
			
			while( dst >= buffer )
			{
				if( flag && (*src == 0x20) )
					*dst = 0x00;
				else
				{
					flag = NO;
					*dst = *src;
				}
				dst--;
				src--;
			}
			
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
	// NSString -> NSData (RSDOS String)
    
	if ([value respondsToSelector: @selector(cStringUsingEncoding:)])
	{
		const char *buffer = [value cStringUsingEncoding:[NSString defaultCStringEncoding]];
		size_t buffer_length = strlen( buffer );
		
		if( size == 0 )
			size = buffer_length;
		
		char *result_buffer = malloc( size );
		
		memset(result_buffer, 0x20, size);
		memcpy(result_buffer, buffer, MIN(buffer_length, size) );
		
		return [NSData dataWithBytesNoCopy:result_buffer length:size];
	}
    
	return nil;
}

@end

@implementation UnsignedBigEndianTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(NSData *)value
{
	// NSData (BE) -> NSUinteger
	
	if ([value respondsToSelector: @selector(bytes)])
	{
		NSUInteger result, length, i;
		unsigned char *bytes;
		
		bytes = (unsigned char *)[value bytes];
		length = [value length];
		result = 0;
		
		for( i=0; i<length; i++ )
			result += (bytes[ length-1-i] << (8*i));
        
		return [NSNumber numberWithUnsignedInteger:result];
	}
    
	return nil;
}

- (id)reverseTransformedValue:(id)value
{
	return [self reverseTransformedValue:value ofSize:sizeof(NSUInteger)];
}

- (id)reverseTransformedValue:(id)value ofSize:(size_t)size
{
	// NSUinteger -> NSData (BE)
	
	if ([value respondsToSelector: @selector(unsignedIntegerValue)])
	{
		NSUInteger intermediate;
		unsigned char *buffer = (unsigned char *)malloc(size);
		int i;
		
		intermediate = [value unsignedIntegerValue];
		
		for( i=0; i<size; i++ )
		{
			buffer[size-1-i] = intermediate % 256;
			intermediate >>= 8;
		}
		
		return [NSData dataWithBytesNoCopy:buffer length:size];
	}
    
	return nil;
}
@end

@implementation UnsignedLittleEndianTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(NSData *)value
{
	// NSData (LT) -> NSUinteger
	
	if ([value respondsToSelector: @selector(bytes)])
	{
		NSUInteger result, length, i;
		unsigned char *bytes;
		
		bytes = (unsigned char *)[value bytes];
		length = [value length];
		result = 0;
		
		for( i=0; i<length; i++ )
			result += (bytes[ endianTable[length-1-i]] << (8*i));
        
		return [NSNumber numberWithUnsignedInteger:result];
	}
    
	return nil;
}

- (id)reverseTransformedValue:(id)value
{
	return [self reverseTransformedValue:value ofSize:sizeof(NSUInteger)];
}

- (id)reverseTransformedValue:(id)value ofSize:(size_t)size
{
	// NSUinteger -> NSData (LE)
    
	if ([value respondsToSelector: @selector(unsignedIntegerValue)])
	{
		NSUInteger intermediate;
		unsigned char *buffer = (unsigned char *)malloc(size);
		int i;
		
		intermediate = [value unsignedIntegerValue];
		
		for( i=0; i<size; i++ )
		{
			buffer[endianTable[size-1-i]] = intermediate % 256;
			intermediate >>= 8;
		}
		
		return [NSData dataWithBytesNoCopy:buffer length:size];
	}
    
	return nil;
}

@end
