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
    CGFloat originFrames[ZOOM_FRAMES];
    CGFloat sizeFrames[ZOOM_FRAMES];
    int currentFrame;
    BOOL needsAnaylyzation;
}

@property (nonatomic, assign) AudioAnaylizerViewController *viewController;
@property (nonatomic, assign) StAnaylizer *cachedAnaylizer;
@property (nonatomic, assign) BOOL observationsActive;
@property (nonatomic, assign) BOOL anaylizationError;
@property (nonatomic, retain) NSString *errorString;

- (IBAction)chooseTool:(id)sender;
- (void) setPreviousState:(NSDictionary *)previousState;

@end
