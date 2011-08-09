//
//  WaveFormView.h
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CoreAudio/CoreAudioTypes.h"

@interface WaveFormView : NSView
{
    AudioSampleType *audioFrames;
    NSUInteger frameCount;
    Float64 sampleRate;

}

@property(nonatomic, assign) AudioSampleType *audioFrames;
@property(nonatomic, assign) NSUInteger frameCount;
@property(nonatomic, assign) Float64 sampleRate;

@end
