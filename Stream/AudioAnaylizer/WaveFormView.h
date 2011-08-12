//
//  WaveFormView.h
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StAnaylizer.h"
#import "CoreAudio/CoreAudioTypes.h"

typedef struct
{
    NSUInteger start;
    NSUInteger length;
} charRef;

@interface WaveFormView : NSView
{
    AudioSampleType *audioFrames;
    NSUInteger frameCount;
    Float64 sampleRate;
    
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

- (void) anaylizeAudioDataWithOptions:(StAnaylizer *)anaylizer;
+ (NSMutableDictionary *)defaultOptions;

@end
