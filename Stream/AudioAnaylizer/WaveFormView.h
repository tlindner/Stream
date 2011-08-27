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
#import "AudioAnaylizer.h"

#define ZOOM_FRAMES 10

@interface WaveFormView : NSView
{
    AudioSampleType *audioFrames;
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
    
    charRef *coalescedCharacters;
    charRef *characters;
    unsigned char *character;
    NSUInteger char_count;
    NSUInteger coa_char_count;
}

@property(nonatomic, assign) AudioSampleType *audioFrames;
@property(nonatomic, assign) NSUInteger frameCount;
@property(nonatomic, assign) Float64 sampleRate;
@property(nonatomic, assign) charRef *characters;
@property(nonatomic, assign) charRef *coalescedCharacters;
@property(nonatomic, assign) unsigned char *character;
@property(nonatomic, assign) NSUInteger char_count;
@property(nonatomic, assign) NSUInteger coa_char_count;

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
