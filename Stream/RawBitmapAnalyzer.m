//
//  RawBitmapAnalyzer.m
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "RawBitmapAnalyzer.h"
#import "RawBitmapViewController.h"
#import "StAnalyzer.h"
#import "StBlock.h"

@implementation RawBitmapAnalyzer

@synthesize representedObject;
@synthesize resultingData;

- (StAnalyzer *)representedObject
{
    return _representedObject;
}

- (void) setRepresentedObject:(id)inRepresentedObject
{
    _representedObject = inRepresentedObject;
    
    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[RawBitmapAnalyzer analyzerKey] withDictionary:[RawBitmapAnalyzer defaultOptions]];
    }
}

- (void) analyzeData
{
    StData *ro = [self representedObject];
    NSMutableData *sourceData = (NSMutableData *)[ro resultingData];
    self.resultingData = [NSData data];
    ro.resultingUTI = @"public.data";
    
    if (sourceData != nil) {
        BOOL passThrough = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.passThrough"] boolValue];

        if (passThrough == NO) {
            NSInteger ignoreHeaderBytes = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.ignoreHeaderBytes"] intValue];
            NSInteger width = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.horizontalPixels"] intValue];
            NSInteger height = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.verticalPixels"] intValue];
            NSInteger bps = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.bitsPerSample"] intValue];
            NSInteger spp = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.samplesPerPixel"] intValue];
            BOOL isAlpha = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.alphaChannel"] boolValue];
            BOOL isPlanar = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.planar"] boolValue];
            NSString *colorSpaceName = [ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.colorSpaceName"];
            NSInteger rowBytes = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.rowBytes"] intValue];
            NSInteger pixelBits = [[ro valueForKeyPath:@"optionsDictionary.RawBitmapAnalyzer.pixelBits"] intValue];
            
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

+ (NSArray *)analyzerUTIs
{
    return [NSArray arrayWithObject:@"public.data"];
}

+ (NSString *)analyzerName
{
    return @"Raw Bitmap Viewer";
}

+ (NSString *)AnalyzerPopoverAccessoryViewNib
{
    return @"RawBitmapAccessoryView";
}

- (Class)viewControllerClass
{
    return [RawBitmapViewController class];
}

+ (NSString *)analyzerKey
{
    return @"RawBitmapAnalyzer";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"passThrough", @"0", @"ignoreHeaderBytes", @"10", @"horizontalPixels", @"10", @"verticalPixels", @"1", @"bitsPerSample",[NSArray arrayWithObjects:@"1", @"2", @"4", @"8", @"12", @"16", nil], @"bitsPerSampleList", @"1", @"samplesPerPixel", [NSNumber numberWithBool:NO], @"alphaChannel", [NSNumber numberWithBool:NO], @"planar", @"NSDeviceWhiteColorSpace", @"colorSpaceName",@"2", @"rowBytes", [NSArray arrayWithObjects:@"NSCalibratedWhiteColorSpace",@"NSCalibratedBlackColorSpace", @"NSCalibratedRGBColorSpace", @"NSDeviceWhiteColorSpace", @"NSDeviceBlackColorSpace", @"NSDeviceRGBColorSpace", @"NSDeviceCMYKColorSpace", @"NSNamedColorSpace", @"NSPatternColorSpace", @"NSCustomColorSpace", nil], @"colorSpaceNameList", @"0", @"pixelBits", nil] autorelease];
}

@end
