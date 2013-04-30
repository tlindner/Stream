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
#import "StreamEdit.h"
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
}

@property (assign) StAnaylizer * representedObject;
@property (nonatomic, retain) NSMutableData *frameBuffer;

- (void) loadAudioChannel:(int)audioChannel;
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

@end
