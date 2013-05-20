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
    if( [[self representedObject] isKindOfClass:[StAnaylizer class]] )
    {
        StAnaylizer *object = [self representedObject];
        self.resultingData = object.sourceData;
    }
    else if( [[self representedObject] isKindOfClass:[StBlock class]] )
    {
        StBlock *theBlock = (StBlock *)[self representedObject];
        self.resultingData = [theBlock resultingData];
    }
    else if( [[self representedObject] isKindOfClass:[NSData class]] )
    {
        self.resultingData = (NSData *)[self representedObject];
    }
    else
        NSLog( @"RawBitmapAnaylizer: Unknown type of represented object" );
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
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"0", @"ignoreHeaderBytes", @"10", @"horizontalPixels", @"10", @"verticalPixels", @"1", @"bitsPerSample",[NSArray arrayWithObjects:@"1", @"2", @"4", @"8", @"12", @"16", nil], @"bitsPerSampleList", @"1", @"samplesPerPixel", [NSNumber numberWithBool:NO], @"alphaChannel", [NSNumber numberWithBool:NO], @"planar", @"NSDeviceWhiteColorSpace", @"colorSpaceName",@"2", @"rowBytes", [NSArray arrayWithObjects:@"NSCalibratedWhiteColorSpace",@"NSCalibratedBlackColorSpace", @"NSCalibratedRGBColorSpace", @"NSDeviceWhiteColorSpace", @"NSDeviceBlackColorSpace", @"NSDeviceRGBColorSpace", @"NSDeviceCMYKColorSpace", @"NSNamedColorSpace", @"NSPatternColorSpace", @"NSCustomColorSpace", nil], @"colorSpaceNameList", @"0", @"pixelBits", nil] autorelease];
}

@end
