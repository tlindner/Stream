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
    NSData *rd = [modelObject resultingData];
    NSImage *image = nil;
    
    if ([rd length] > 0) {
        image = [[[NSImage alloc] initWithData:rd] autorelease];
    }

    if (image == nil) {
        image = [NSImage imageNamed:@"ImageNotWorking"];
    }

    [imageView setImage:image];
   
    [self resumeObservations];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        [self reloadView];
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
