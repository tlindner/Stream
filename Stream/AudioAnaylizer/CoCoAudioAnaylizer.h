//
//  CoCoAudioAnaylizer.h
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Analyzation.h"
#import "StStream.h"
#import "StAnaylizer.h"
#import "StBlock.h"
#include "AudioToolbox/AudioToolbox.h"

void SetCanonical(AudioStreamBasicDescription *clientFormat, UInt32 nChannels, bool interleaved);

@interface CoCoAudioAnaylizer : NSObject
{
    BOOL needsAnaylyzation;
    BOOL anaylizationError;
    BOOL observationsActive;
    StAnaylizer *representedObject;
    NSMutableData *frameBuffer;
    int currentAudioChannel;
    NSMutableData *resultingData;
}

@property (assign) StAnaylizer * representedObject;
@property (nonatomic, retain) NSMutableData *frameBuffer;
@property (nonatomic, retain) NSMutableData *resultingData;

- (void) loadAudioChannel:(NSUInteger)audioChannel;
- (void) anaylizeAudioData;
- (void) applyInvert;
- (void) applyAmplify;
- (void) applyAllEdits;
- (void) reloadChachedAudioFrames;
- (void) updateWaveFormForCharacter:(NSUInteger)idx;
- (void) setPreviousState:(NSDictionary *)previousState;
- (NSURL*) makeTemporaryWavFileWithData: (NSData *)data;
- (NSURL*) makeWavFile:(NSURL *)waveFile withData:(NSData *)data;
- (void) determineFrequencyOrigin:(NSUInteger)origin width:(NSUInteger)width;
- (void) zeroSamplesOrigin:(NSUInteger)origin width:(NSUInteger)width;

- (void) suspendObservations;
- (void) resumeObservations;

@end
