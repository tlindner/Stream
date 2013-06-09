//
//  OS9DirectoryFile.m
//  Stream
//
//  Created by tim lindner on 5/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "OS9DirectoryFile.h"

@implementation OS9DirectoryFile
+ (NSArray *)analyzerUTIs
{
    return [NSArray arrayWithObjects:@"com.microware.os9directoryfile", nil];
}

+ (NSString *)analyzerName
{
    return @"OS9 Directory File";
}

+ (NSString *)analyzerKey
{
    return @"OS9DirectoryFile";
}

- (void)analyzeData
{
    StData *object = [self representedObject];
    NSData *sourceData = [object resultingData];
    NSString *result = [self convertToString:sourceData];
    self.resultingData = [result dataUsingEncoding:NSUnicodeStringEncoding];
    
    object.resultingUTI = @"public.utf16-plain-text";
    
    if (self.resultingData == nil) {
        self.resultingData = [NSData data];
    }
}

- (NSString *)convertToString:(NSData *)source
{
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    NSUInteger length = [source length], i=0;
    const unsigned char *bytes = [source bytes];
    NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:@"OS9String"];
    
    if (vt != nil) {
        while (length > 0) {
            
            if (bytes[i*32] != 0) {
                [result appendString:[vt transformedValue:[source subdataWithRange:NSMakeRange(i * 32, 29)]]];
                [result appendString:@", "];
                
                unsigned lsn = bytes[(i * 32) + 29] << 16;
                lsn += bytes[(i * 32) + 30] << 8;
                lsn += bytes[(i * 32) + 31];
                
                [result appendString:[NSString stringWithFormat:@"%d (0x%X)", lsn, lsn]];
                [result appendString:@"\n"];
            }
            
            i++;
            length -= 32;
        }
    }
    else {
        [result appendString:@"Missing OS-9 string tranfsormer."];
    }
    
    return result;
}

@end
