//
//  CoCoDiskFileBlocker.m
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CoCoDiskFileBlocker.h"
#import "StStream.h"
#import "StBlock.h"

@implementation CoCoDiskFileBlocker
+ (void)initialize
{
    if ( self == [CoCoDiskFileBlocker class] )
    {
        // Setup standard value transformers
		RSDOSFilenameTransformer *RSDFN;
		RSDFN = [[[RSDOSFilenameTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:RSDFN forName:@"RSDOSFilename"];		
    }
}

+ (NSString *)blockerName
{
    return @"CoCo Disk File Blocker";
}

+ (NSString *)blockerKey
{
    return @"CoCoDiskFileBlocker";
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
    NSMutableString *shadowFat[68];
    
    for (int i=0; i<68; i++) {
        shadowFat[i] = [[[NSMutableString alloc] init] autorelease];
    }
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
    NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:@"RSDOSFilename"];
    NSData *directoryEntriesData = [stream dataOfTopLevelBlockNamed:@"Directory Entries"];
    
    if (directoryEntriesData == nil) {
        return @"Could not find \"Directory Entries\" block";
    }
    
    unsigned const char *directoryEntries = [directoryEntriesData bytes];
    NSUInteger directoryEntriesLength = [directoryEntriesData length];
    
    NSData *fatData = [stream dataOfTopLevelBlockNamed:@"File Allocation Table"];
    
    if (fatData == nil) {
        return @"Could not find \"File Allocation Table\" block";
    }
   
    unsigned const char *fat = [fatData bytes];
    NSUInteger fatLength = [fatData length];
    
    if (fatLength < 256) {
        return @"File allocaion table is not 256 bytes";
    }
    
    StBlock *newfile;
    
    for (NSUInteger i=0; i<72; i++) {
        
        if ((i+1)*32 > directoryEntriesLength) return @"Abnormal End: Short directory track";

        if (directoryEntries[i*32] == 0xff) break;
        
        if (directoryEntries[i*32] == 0) continue;
        
        NSString *testFilename = [vt transformedValue:[NSData dataWithBytes:&directoryEntries[i*32] length:8+3]];
        testFilename = [@"/" stringByAppendingString:testFilename];
        newfile = [stream startNewBlockNamed:testFilename owner:[CoCoDiskFileBlocker blockerKey]];
        
        int filenameIndex=0;
        NSString *fileName = testFilename;
        while (newfile == nil) {
            fileName = [testFilename stringByAppendingFormat:@" [%d]", filenameIndex++];
            newfile = [stream startNewBlockNamed:fileName owner:[CoCoDiskFileBlocker blockerKey]];
        }
        
        [newfile addAttributeRange:@"Directory Entries" start:i*32 length:8+3 name:@"Filename" verification:nil transformation:@"RSDOSFilename"];
        [newfile addAttributeRange:@"Directory Entries" start:(i*32)+11 length:1 name:@"File Type" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        [newfile addAttributeRange:@"Directory Entries" start:(i*32)+12 length:1 name:@"ASCII Flag" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        [newfile addAttributeRange:@"Directory Entries" start:(i*32)+13 length:1 name:@"First Granule" verification:nil transformation:@"BlocksUnsignedBigEndian"];
        [newfile addAttributeRange:@"Directory Entries" start:(i*32)+14 length:2 name:@"Final Sector Length" verification:nil transformation:@"BlocksUnsignedBigEndian"];

        unsigned char noteFileType = directoryEntries[(i*32)+11];
        unsigned char noteDataType = directoryEntries[(i*32)+12];
        
        /* Set up UTIs */
        if (noteFileType == 0 && noteDataType == 0) {
            newfile.sourceUTI = newfile.resultingUTI = @"com.microsoft.cocobasic.binary";
            newfile.currentEditorView = @"Text Editor";
        }
        else if (noteFileType == 0 && noteDataType == 0xff) {
            newfile.sourceUTI = newfile.resultingUTI = @"com.microsoft.cocobasic.ascii";
            newfile.currentEditorView = @"Text Editor";
        }
        else if (noteFileType == 0x01 && noteDataType == 0xff) {
            newfile.sourceUTI = newfile.resultingUTI = @"public.text";
            newfile.currentEditorView = @"Text Editor";
        }
        else if (noteFileType == 0x02 && noteDataType == 0) {
            newfile.sourceUTI = newfile.resultingUTI = @"com.microsoft.cocobasic.gapsobject";
            newfile.currentEditorView = @"Text Editor";
        }
        else if (noteFileType == 3) {
            newfile.sourceUTI = newfile.resultingUTI = @"public.text";
            newfile.currentEditorView = @"Text Editor";
        }
        else {
            newfile.sourceUTI = newfile.resultingUTI = @"public.data";
        }
                
        unsigned char nextGranule = directoryEntries[(i*32)+13];
        unsigned finalSectorLength = directoryEntries[(i*32)+14] << 8;
        finalSectorLength += directoryEntries[(i*32)+15];
        int i=0;
        
        while (i < 68) {

            if (nextGranule > 67) {
                [result appendFormat:@"\nOut of range granule number while building file:%@", fileName];
                break;
            }
            
            if ( ! [shadowFat[nextGranule] isEqualToString:@""]) {
                [result appendFormat:@"\nDouble allocation file building file:%@ (with other files: %@)", fileName, shadowFat[nextGranule]];
                break;
            }
            else {
                [shadowFat[nextGranule] appendFormat:@"%@, ", fileName];
            }
            
            NSString *name = [NSString stringWithFormat:@"Granule %d", nextGranule];
            
            if ((fat[nextGranule] & 0xc0) == 0xc0) {
                unsigned sectorCount = fat[nextGranule] & 0x3f;
                unsigned lastGranuleLength = (256 * (sectorCount-1)) + finalSectorLength;
                [newfile addDataRange:name start:0 length:lastGranuleLength];
                break;
            }
            else {
                [newfile addDataRange:name start:0 length:0 expectedLength:256*9];
            }
            
            nextGranule = fat[nextGranule];
            i++;
        }
    }
    
    return result;
}
@end

@implementation RSDOSFilenameTransformer

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
	// NSData (RSDOS Filename) -> NSString
    
	if ([value respondsToSelector: @selector(bytes)])
	{
		// RSDOS filenames are fixed length, padded with right hand spaces (0x20) in two sections 8 bytes for the file name and 3 bytes for the extension.
        
        NSString *extensionString, *filenameString;
        
        if ([value length] > 8) {
            NSUInteger actualLength = [value length] - 8;
            NSData *extensionData = [value subdataWithRange:NSMakeRange(8, actualLength)];
            extensionString = [[[NSString alloc] initWithData:extensionData encoding:NSMacOSRomanStringEncoding] autorelease];
            extensionString = [extensionString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            extensionString = [@"." stringByAppendingString:extensionString];
        }
        else {
            extensionString = @"";
        }
        
        NSUInteger actualLength = MIN([value length], (unsigned)8);
        NSData *filenameData = [value subdataWithRange:NSMakeRange(0, actualLength)];
        filenameString = [[[NSString alloc] initWithData:filenameData encoding:NSMacOSRomanStringEncoding] autorelease];
        filenameString = [filenameString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        filenameString = [filenameString stringByAppendingString:extensionString];

        return filenameString;
	}
	
	return nil;
}

- (id)reverseTransformedValue:(id)value
{
	return [self reverseTransformedValue:value ofSize:0];
}

- (id)reverseTransformedValue:(id)value ofSize:(size_t)size
{
	// NSString -> NSData (RSDOS Filename)
    
	if ([value respondsToSelector: @selector(componentsSeparatedByString:)])
	{
        char bytes[8+3+1];
        
        NSArray *stringParts = [value componentsSeparatedByString:@"."];
        NSUInteger partCount = [stringParts count];
        NSString *extension = @"";
        NSString *filename = [filename stringByAppendingString:[stringParts objectAtIndex:0]];
        
        if (partCount > 1) {
            extension = [stringParts objectAtIndex:partCount-1];
            
            for (unsigned i=1; i<partCount-1; i++) {
                filename = [filename stringByAppendingFormat:@".%@", [stringParts objectAtIndex:i]];
            }
        }
        
        extension = [extension stringByPaddingToLength:3 withString:@" " startingAtIndex:0];
        filename = [filename stringByPaddingToLength:8 withString:@" " startingAtIndex:0];
        
        [filename getCString:bytes maxLength:8 encoding:NSMacOSRomanStringEncoding];
        [extension getCString:bytes+8 maxLength:3 encoding:NSMacOSRomanStringEncoding];
        
        if (size == 0) size = 8+3;
        
        NSUInteger acualSize = MIN(size, (unsigned)8+3);
        return [NSData dataWithBytes:bytes length:acualSize];
	}
    
	return nil;
}

@end