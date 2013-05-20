//
//  DMKProcessSingleDensity.m
//  Stream
//
//  Created by tim lindner on 5/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DMKProcessSingleDensity.h"
#import "HexFiendAnaylizerController.h"

@implementation DMKProcessSingleDensity

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"org.macmess.imagedisk"];
}

+ (NSString *)anayliserName
{
    return @"DMK Process Single Density";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"HFAccessoryView";
}

- (Class)viewControllerClass
{
    return [HexFiendAnaylizerController class];
}

+ (NSString *)anaylizerKey
{
    return @"DMKProcessSingleDensity";
}

- (void)anaylizeData
{
    [super anaylizeData];
    NSData *data = self.resultingData;
    
    unsigned const char *bytes = [data bytes];
    NSUInteger inputLength = [data length];
    
    if (inputLength < 16) {
        StAnaylizer *theAna = self.representedObject;
        theAna.errorString = @"Stream less that DMK header in length. No Processing done.";
        self.resultingData = data;
        return;
    }
    
    unsigned trackCount = bytes[1];
    unsigned trackLength = (bytes[3] << 8) + bytes[2];
    unsigned sideCount = (bytes[4] & 0x10) ? 1 : 2;
    
    if( 16 + (trackCount * trackLength * sideCount) != inputLength ) {
        StAnaylizer *theAna = self.representedObject;
        theAna.errorString = @"Calculated length of stream does not match actual stream length. No Processing done.";
        self.resultingData = data;
        return;
    }
        
    NSMutableData *result = [[[NSMutableData alloc] init] autorelease];
   
    [result appendBytes:bytes length:16];
    
    for (unsigned trackIndex=0; trackIndex < (trackCount*sideCount); trackIndex++) {

        unsigned char *workBuffer = malloc(trackLength);
        memcpy(workBuffer, &(bytes[16+(trackIndex*trackLength)]), trackLength);

        for (unsigned idamIndex = 0; idamIndex < 0x80; idamIndex+=2) {
            
            unsigned offset = (workBuffer[idamIndex+1] << 8) + workBuffer[idamIndex];
            unsigned nextOffset;
            
            if (offset == 0) break;
            
            if ((offset & 0x8000) == 0) {
                /* found a single density "double byte" sector */
                
                offset &= 0x3fff;
                
                if (offset > trackLength) {
                    StAnaylizer *theAna = self.representedObject;
                    theAna.errorString = [NSString stringWithFormat:@"IDAM offset %d on track index %d overflows track length. No Processing done.", idamIndex, trackIndex];
                    free(workBuffer);
                    self.resultingData = data;
                    return;
                }
                
               /* calculate end of sector data */
                if (idamIndex == 0x7e) {
                    nextOffset = trackLength;
                } else {
                    nextOffset = (workBuffer[idamIndex+3] << 8) + workBuffer[idamIndex+2];
                    nextOffset &= 0x3fff;

                    if (nextOffset > trackLength) {
                        StAnaylizer *theAna = self.representedObject;
                        theAna.errorString = [NSString stringWithFormat:@"IDAM offset %d on track index %d overflows track length. No Processing done.", nextOffset, trackIndex];
                        free(workBuffer);
                        self.resultingData = data;
                        return;
                    }
                }

                if (nextOffset == 0) {
                    nextOffset = trackLength;
                }
                
                /* rewrite sector data */
                for (unsigned i=offset, j=offset; i <nextOffset; i+=2, j++) {
                    workBuffer[j] = workBuffer[i];
                }
            }
        }
        
        [result appendBytes:workBuffer length:trackLength];
        free(workBuffer);
    }

    self.resultingData = result;
}

@end
