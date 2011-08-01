//
//  AudioAnaylizer.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AudioAnaylizer.h"
#import "WaveFormView.h"
#include "AudioToolbox/AudioToolbox.h"

@implementation AudioAnaylizer

@dynamic data;
@synthesize result;
@synthesize scroller;
@synthesize slider;

+ (void)initialize {
    if (self == [AudioAnaylizer class]) {
        [self exposeBinding:@"data"];
        [self exposeBinding:@"result"];
    }
    
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSRect sliderRect = NSMakeRect(0.0f, 0.0f, frame.size.width, 16.0f);
        self.slider = [[NSSlider alloc] initWithFrame:sliderRect];
        [self addSubview:self.slider];
        [self.slider setAutoresizingMask:(NSViewWidthSizable)];
        [[self.slider cell] setControlSize:NSMiniControlSize];
        [self.slider setTickMarkPosition:(NSTickMarkAbove)];
        [self.slider setNumberOfTickMarks:25];
        [self.slider setAction:@selector(updateSlider:)];
        [self.slider setTarget:self];
        [self.slider release];
        
        NSRect scrollerRect = NSMakeRect(0.0f,16.0f,frame.size.width, frame.size.height-16.0f);
        self.scroller = [[NSScrollView alloc] initWithFrame:scrollerRect];
        [self.scroller setBorderType:NSLineBorder];
        [self.scroller setHasVerticalScroller:NO];
        [self.scroller setHasHorizontalScroller:YES];
        [self.scroller setAutoresizingMask:(NSViewWidthSizable)];
        [[self.scroller contentView] setAutoresizesSubviews:YES];
        [self addSubview:self.scroller];
        
        WaveFormView *wfv = [[WaveFormView alloc] initWithFrame:scrollerRect];
        [wfv setBounds:scrollerRect];
        [self.scroller setDocumentView:wfv];
        [wfv release];
        
        [self.scroller release];
    }
    
    return self;
}

- (NSData *)data
{
    return data;
}

- (void)setData:(NSData *)inData
{
    [data release];
    data = nil;
    WaveFormView *wfv = [self.scroller documentView];
    
    if( inData != nil )
    {
        data = [inData retain];
        /* Convert data to samples */
        OSStatus err;
        ExtAudioFileRef af;
        
        NSManagedObject *parentStream = [[[self superview] superview] valueForKeyPath:@"objectValue.parentStream"];
        NSURL *fileURL = [parentStream valueForKey:@"sourceURL"];
        
        err = ExtAudioFileOpenURL((CFURLRef)fileURL, &af);
        
        if (err == noErr)
        {
            UInt32 propSize;
            SInt64 fileFrameCount;
            
            AudioStreamBasicDescription clientFormat;
            propSize = sizeof(clientFormat);
            
            err = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileDataFormat, &propSize, &clientFormat);
            propSize = sizeof(SInt64);
            err = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileLengthFrames, &propSize, &fileFrameCount);
            
            wfv.frameCount = sizeof(uint8) * fileFrameCount;
            wfv.audioFrames = malloc(wfv.frameCount);
            
            AudioBufferList bufList;
            bufList.mNumberBuffers = 1;
            bufList.mBuffers[0].mNumberChannels = 1;
            bufList.mBuffers[0].mData = wfv.audioFrames;
            bufList.mBuffers[0].mDataByteSize = wfv.frameCount;
            UInt32 ioFrameCount = fileFrameCount;
            err = ExtAudioFileRead(af, &ioFrameCount, &bufList);
            
            float avaiableWidth = [self frame].size.width;
            self.slider.maxValue = wfv.frameCount/avaiableWidth;
            self.slider.minValue = 1;
            wfv.scale = self.slider.intValue;

            [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount/[self.slider floatValue], [wfv frame].size.height)];
            [[self.scroller documentView] setNeedsDisplay:YES];
        }
        
        err = ExtAudioFileDispose(af);    
    }   
}

- (void)dealloc {
    self.data = nil;
    self.result = nil;
    [self.scroller removeFromSuperview];
    self.scroller = nil;
    [self.slider removeFromSuperview];
    self.slider = nil;
    
    [super dealloc];
}

- (IBAction)updateSlider:(id)sender
{
    WaveFormView *wfv = [self.scroller documentView];
    wfv.scale = self.slider.intValue;
    [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount/[self.slider floatValue], [wfv frame].size.height)];
    [self.scroller.documentView setNeedsDisplay:YES];
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.audio"];
}

+ (NSString *)anayliserName
{
    return @"Color Computer Audio Anaylizer";
}

@end

