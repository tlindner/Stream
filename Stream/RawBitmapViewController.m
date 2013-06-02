//
//  RawBitmapViewController.m
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "RawBitmapViewController.h"
#import "RawBitmapAnalyzer.h"
#import "StAnalyzer.h"

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

- (void)setRepresentedObject:(id)representedObject
{
    if (representedObject != self.representedObject) {
        [self suspendObservations];
    }
    
    [super setRepresentedObject:representedObject];
}

- (void) reloadView
{
    RawBitmapAnalyzer *modelObject = (RawBitmapAnalyzer *)[[self representedObject] analyzerObject];
    [modelObject analyzeData];
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
        StAnalyzer *ro = self.representedObject;
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.passThrough" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.ignoreHeaderBytes" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.horizontalPixels" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.verticalPixels" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.bitsPerSample" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.samplesPerPixel" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.alphaChannel" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.planar" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.colorSpaceName" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.rowBytes" context:self];
        [ro removeObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.pixelBits" context:self];
        observationsActive = NO;
    }
}

- (void) resumeObservations
{
    if (observationsActive == NO) {
        StAnalyzer *ro = self.representedObject;
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.passThrough" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.ignoreHeaderBytes" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.horizontalPixels" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.verticalPixels" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.bitsPerSample" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.samplesPerPixel" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.alphaChannel" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.planar" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.colorSpaceName" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.rowBytes" options:NSKeyValueChangeSetting context:self];
        [ro addObserver:self forKeyPath:@"optionsDictionary.RawBitmapAnalyzer.pixelBits" options:NSKeyValueChangeSetting context:self];
        observationsActive = YES;
    }
}

- (IBAction)imageChanging:(id)sender {
#pragma unused (sender)
    [self reloadView];
}

- (void)dealloc
{
    [self suspendObservations];
    [super dealloc];
}

@end
