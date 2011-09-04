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

typedef struct
{
    NSUInteger start;
    NSUInteger length;
} charRef;

@class AudioAnaylizerViewController;

@interface WaveFormView : NSView
{
    NSUInteger frameCount;
    Float64 sampleRate;
    NSUInteger channelCount;
    
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
}

@property (nonatomic, assign) AudioAnaylizerViewController *viewController;

@property(nonatomic, assign) NSUInteger frameCount;
@property(nonatomic, assign) Float64 sampleRate;

@property(nonatomic, assign) NSUInteger channelCount;
@property(nonatomic, assign) NSUInteger currentChannel;
@property(nonatomic, assign) NSUInteger previousCurrentChannel;
@property(nonatomic, assign) CGFloat previousBoundsWidth;
@property(nonatomic, assign) CGFloat previousFrameWidth;
@property(nonatomic, assign) int previousOffset;
@property(nonatomic, assign) Float32 *previousBuffer;

@property(nonatomic, assign) StAnaylizer *cachedAnaylizer;
@property(nonatomic, assign) float lowCycle;
@property(nonatomic, assign) float highCycle;
@property(nonatomic, assign) float resyncThresholdHertz;
@property(nonatomic, assign) BOOL observationsActive;

@property(nonatomic, assign) BOOL anaylizationError;
@property(nonatomic, retain) NSString *errorString;
@property(nonatomic, assign) BOOL needsAnaylyzation;

- (void) anaylizeAudioData;
- (IBAction)chooseTool:(id)sender;
- (void) setPreviousState:(NSDictionary *)previousState;

@end
