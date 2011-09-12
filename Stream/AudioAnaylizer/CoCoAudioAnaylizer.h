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
    
    int currentAudioChannel;
}

@property (assign) StAnaylizer * representedObject;

- (void) loadAudioChannel:(int)audioChannel;
- (void) anaylizeAudioData;
- (void) updateWaveFormForCharacter:(NSUInteger)idx;
- (void) setPreviousState:(NSDictionary *)previousState;

@end
