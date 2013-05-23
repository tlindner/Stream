//
//  RawBitmapAnaylizer.m
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "RawBitmapAnaylizer.h"
#import "RawBitmapViewController.h"
#import "StAnaylizer.h"
#import "StBlock.h"

@implementation RawBitmapAnaylizer

@synthesize representedObject;
@synthesize resultingData;

- (StAnaylizer *)representedObject
{
    return _representedObject;
}

- (void) setRepresentedObject:(id)inRepresentedObject
{
    _representedObject = inRepresentedObject;
    
    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[RawBitmapAnaylizer anaylizerKey] withDictionary:[RawBitmapAnaylizer defaultOptions]];
    }
}

- (void) anaylizeData
{
    StData *ro = [self representedObject];
    NSMutableData *sourceData = (NSMutableData *)[ro resultingData];
    self.resultingData = [NSData data];
    ro.resultingUTI = @"public.data";
    
    if (sourceData != nil) {
        BOOL passThrough = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.passThrough"] boolValue];

        if (passThrough == NO) {
            NSInteger ignoreHeaderBytes = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.ignoreHeaderBytes"] intValue];
            NSInteger width = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.horizontalPixels"] intValue];
            NSInteger height = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.verticalPixels"] intValue];
            NSInteger bps = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.bitsPerSample"] intValue];
            NSInteger spp = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.samplesPerPixel"] intValue];
            BOOL isAlpha = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.alphaChannel"] boolValue];
            BOOL isPlanar = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.planar"] boolValue];
            NSString *colorSpaceName = [ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.colorSpaceName"];
            NSInteger rowBytes = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.rowBytes"] intValue];
            NSInteger pixelBits = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.pixelBits"] intValue];
            
            if (height < 1) {
                height = 1;
            }
            
            if (width < 1) {
                width = 1;
            }
            
            NSUInteger dataLength = [sourceData length], imageLength = (rowBytes * height) + ignoreHeaderBytes;
            
            if (imageLength < dataLength) {
                sourceData = [[sourceData mutableCopy] autorelease];
                [sourceData setLength:imageLength];
            }
            
            unsigned char *planes[2];
            planes[0] = (unsigned char *)[sourceData bytes] + ignoreHeaderBytes;
            planes[1] = 0;
            NSBitmapImageRep *bir = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes pixelsWide:width pixelsHigh:height bitsPerSample:bps samplesPerPixel:spp hasAlpha:isAlpha isPlanar:isPlanar colorSpaceName:colorSpaceName bytesPerRow:rowBytes bitsPerPixel:pixelBits] autorelease];
            
            if (bir != nil) {
                [bir setCompression:NSTIFFCompressionNone factor:1.0];
                self.resultingData = [bir TIFFRepresentation];
                ro.resultingUTI = @"public.tiff";
                
                if (self.resultingData == nil) {
                    self.resultingData = [NSData data];
                    ro.resultingUTI = @"public.data";
                }
            }
        } else {
            self.resultingData = sourceData;
            ro.resultingUTI = @"public.image";
        }
    }
}

- (void)dealloc
{
    self.resultingData = nil;
    
    [super dealloc];
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.data"];
}

+ (NSString *)anayliserName
{
    return @"Raw Bitmap Viewer";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"RawBitmapAccessoryView";
}

- (Class)viewControllerClass
{
    return [RawBitmapViewController class];
}

+ (NSString *)anaylizerKey
{
    return @"RawBitmapAnaylizer";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"passThrough", @"0", @"ignoreHeaderBytes", @"10", @"horizontalPixels", @"10", @"verticalPixels", @"1", @"bitsPerSample",[NSArray arrayWithObjects:@"1", @"2", @"4", @"8", @"12", @"16", nil], @"bitsPerSampleList", @"1", @"samplesPerPixel", [NSNumber numberWithBool:NO], @"alphaChannel", [NSNumber numberWithBool:NO], @"planar", @"NSDeviceWhiteColorSpace", @"colorSpaceName",@"2", @"rowBytes", [NSArray arrayWithObjects:@"NSCalibratedWhiteColorSpace",@"NSCalibratedBlackColorSpace", @"NSCalibratedRGBColorSpace", @"NSDeviceWhiteColorSpace", @"NSDeviceBlackColorSpace", @"NSDeviceRGBColorSpace", @"NSDeviceCMYKColorSpace", @"NSNamedColorSpace", @"NSPatternColorSpace", @"NSCustomColorSpace", nil], @"colorSpaceNameList", @"0", @"pixelBits", nil] autorelease];
}

@end
