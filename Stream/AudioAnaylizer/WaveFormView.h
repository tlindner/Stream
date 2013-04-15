//
//  WaveFormView.h
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StAnaylizer.h"
#import "CoreAudio/CoreAudioTypes.h"
#import "AudioAnaylizerViewController.h"
#import "CoCoAudioAnaylizer.h"
#import "MAAttachedWindow.h"

#define ZOOM_FRAMES 10

@class AudioAnaylizerViewController;

@interface WaveFormView : NSView
{
    BOOL resample;
    NSUInteger previousCurrentChannel;
    CGFloat previousBoundsWidth;
    CGFloat previousFrameWidth;
    int previousOffset;
    Float32 *previousBuffer;
    NSIndexSet *previousIndexSet;
    
    NSInteger toolMode;
    NSUInteger selectedSample, selectedSampleUnderMouse;
    NSUInteger selectedSampleLength;
    AudioSampleType *storedSamples;
    BOOL cancelDrag;
    NSPoint locationMouseDown, locationNow, locationPrevious;
    NSPoint startOrigin;
    NSTimer *panMomentumTimer;
    CGFloat panMomentumValue;
    BOOL mouseDown, mouseDownOnPoint;
    NSRect dragRect;
    double originFrames[ZOOM_FRAMES+1];
    double sizeFrames[ZOOM_FRAMES+1];
    int currentFrame;
    BOOL needsAnaylyzation;
    StAnaylizer *cachedAnaylizer;
    CoCoAudioAnaylizer *modelObject;
    MAAttachedWindow *attachedWindow;
    NSTextView *textView;
}

@property (nonatomic, assign) AudioAnaylizerViewController *viewController;
@property (nonatomic, assign) StAnaylizer *cachedAnaylizer;
@property (nonatomic, assign) BOOL observationsActive;
@property (nonatomic, assign) BOOL anaylizationError;
@property (nonatomic, retain) NSString *errorString;

- (IBAction)chooseTool:(id)sender;
- (void) activateObservations;
- (void) deactivateObservations;
- (BOOL) acceptsFirstResponder;
- (void)zoomToCharacter: (NSRange)range;
- (void) getSelectionOrigin:(NSUInteger *)origin width:(NSUInteger *)width;

@end
