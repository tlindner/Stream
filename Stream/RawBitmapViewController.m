//
//  RawBitmapViewController.m
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "RawBitmapViewController.h"
#import "RawBitmapAnaylizer.h"
#import "StAnaylizer.h"

@interface RawBitmapViewController ()

@end

@implementation RawBitmapViewController

@synthesize imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(NSString *)nibName
{
    return @"RawBitmapViewController";
}

- (void)loadView
{
    [super loadView];
    [self reloadView];
}

- (void) reloadView
{
    RawBitmapAnaylizer *modelObject = (RawBitmapAnaylizer *)[[self representedObject] anaylizerObject];
    [modelObject anaylizeData];
    [self setupRepresentedObject];
    [self resumeObservations];
}

- (void) setupRepresentedObject
{
    unsigned char *planes[2];
    
    NSInteger ignoreHeaderBytes = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.ignoreHeaderBytes"] intValue];
    NSInteger width = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.horizontalPixels"] intValue];
    NSInteger height = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.verticalPixels"] intValue];
    NSInteger bps = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.bitsPerSample"] intValue];
    NSInteger spp = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.samplesPerPixel"] intValue];
    BOOL isAlpha = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.alphaChannel"] boolValue];
    BOOL isPlanar = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.planar"] boolValue];
    NSString *colorSpaceName = [[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.colorSpaceName"];
    NSInteger rowBytes = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.rowBytes"] intValue];
    NSInteger pixelBits = [[[self representedObject] valueForKeyPath:@"optionsDictionary.RawBitmapAnaylizer.pixelBits"] intValue];
    RawBitmapAnaylizer *modelObject = (RawBitmapAnaylizer *)[[self representedObject] anaylizerObject];
    NSUInteger dataLength = [[modelObject resultingData] length], imageLength = (rowBytes * height) + ignoreHeaderBytes;
    planes[0] = (unsigned char *)[[modelObject resultingData] bytes] + ignoreHeaderBytes;
    planes[1] = 0;

    if (imageLength > dataLength) {
        NSImage *image = [NSImage imageNamed:@"ImageNotWorking"];
        [imageView setImage:image];
    } else {
        NSBitmapImageRep *bir = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:planes pixelsWide:width pixelsHigh:height bitsPerSample:bps samplesPerPixel:spp hasAlpha:isAlpha isPlanar:isPlanar colorSpaceName:colorSpaceName bytesPerRow:rowBytes bitsPerPixel:pixelBits] autorelease];
        
        if (bir != nil) {
            NSSize size = NSMakeSize(width, height);
            
            NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];
            [image addRepresentation:bir];
            [imageView setImage:image];
        } else {
            NSImage *image = [NSImage imageNamed:@"ImageNotWorking"];
            [imageView setImage:image];
        }
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        [self setupRepresentedObject];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
- (void) suspendObservations
{
    if (observationsActive == YES) {
        StAnaylizer *ro = self.representedObject;
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.ignoreHeaderBytes" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.horizontalPixels" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.verticalPixels" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.bitsPerSample" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.samplesPerPixel" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.alphaChannel" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.planar" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.colorSpaceName" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.rowBytes" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.pixelBits" context:self];
        observationsActive = NO;
    } else {
        NSLog( @"rawbitmap suspend observations: already suspended" );
    }
}

- (void) resumeObservations
{
    if (observationsActive == NO) {
        StAnaylizer *ro = self.representedObject;
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.ignoreHeaderBytes" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.horizontalPixels" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.verticalPixels" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.bitsPerSample" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.samplesPerPixel" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.alphaChannel" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.planar" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.colorSpaceName" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.rowBytes" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnaylizer.pixelBits" options:NSKeyValueChangeSetting context:self];
        observationsActive = YES;
    } else {
        NSLog( @"rawbitmap resume observations: already resumed" );
    }
}

- (void)dealloc
{
    [self suspendObservations];
    [super dealloc];
}

@end
