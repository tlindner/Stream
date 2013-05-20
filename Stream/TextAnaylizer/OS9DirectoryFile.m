//
//  OS9DirectoryFile.m
//  Stream
//
//  Created by tim lindner on 5/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "OS9DirectoryFile.h"

@implementation OS9DirectoryFile
+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObjects:@"com.microware.os9directoryfile", nil];
}

+ (NSString *)anayliserName
{
    return @"OS9 Directory File";
}

+ (NSString *)anaylizerKey
{
    return @"OS9DirectoryFile";
}

- (NSString *)convertToString
{
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    unsigned length = [self.resultingData length], i=0;
    const unsigned char *bytes = [self.resultingData bytes];
    NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:@"OS9String"];
    
    if (vt != nil) {
        while (length > 0) {
            
            if (bytes[i*32] != 0) {
                [result appendString:[vt transformedValue:[self.resultingData subdataWithRange:NSMakeRange(i * 32, 29)]]];
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
