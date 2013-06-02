//
//  CoCoAudioAnalyzer.h
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Analyzation.h"
#import "StStream.h"
#import "StAnalyzer.h"
#import "StBlock.h"
#include "AudioToolbox/AudioToolbox.h"

void SetCanonical(AudioStreamBasicDescription *clientFormat, UInt32 nChannels, bool interleaved);

@interface CoCoAudioAnalyzer : NSObject
{
    BOOL needsAnalyzation;
    BOOL analyzationError;
    BOOL observationsActive;
    StAnalyzer *representedObject;
    NSMutableData *frameBuffer;
    NSUInteger currentAudioChannel;
    NSMutableData *resultingData;
}

@property (assign) StAnalyzer * representedObject;
@property (nonatomic, retain) NSMutableData *frameBuffer;
@property (nonatomic, retain) NSMutableData *resultingData;
@property (nonatomic, retain) NSData *cachedframeBuffer;

@property (nonatomic, retain) NSData *zeroCrossingArray;
@property (nonatomic, retain) NSMutableIndexSet *changedIndexes;
@property (nonatomic, retain) NSMutableData *coalescedObject;
@property (nonatomic, retain) NSMutableData *charactersObject;
@property (nonatomic, retain) NSMutableData *characterObject;

- (void) loadAudioChannel:(NSUInteger)audioChannel;
- (void) analyzeAudioData;
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
- (void) analyzeData;

@end
