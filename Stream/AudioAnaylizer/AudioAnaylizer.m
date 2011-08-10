//
//  AudioAnaylizer.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AudioAnaylizer.h"
#import "WaveFormView.h"
#import "AudioAnaScrollView.h"
#include "AudioToolbox/AudioToolbox.h"

void SetCanonical(AudioStreamBasicDescription *clientFormat, UInt32 nChannels, bool interleaved);

@implementation AudioAnaylizer

@dynamic data;
@synthesize result;
@synthesize scroller;
@synthesize slider;
@synthesize newConstraints;

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
        
        [self setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setAutoresizesSubviews:YES];
        
        NSRect sliderRect = NSMakeRect(1.0f, 2.0, frame.size.width-2, 15.0f);
        NSAssert(self.slider == nil, @"self.slider should be nil here");
        self.slider = [[NSSlider alloc] initWithFrame:sliderRect];
        
        [self addSubview:self.slider];
        //[self.slider setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.slider setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self.slider setAutoresizingMask:NSViewWidthSizable];
        [[self.slider cell] setControlSize:NSMiniControlSize];
        [self.slider setTickMarkPosition:(NSTickMarkAbove)];
        [self.slider setNumberOfTickMarks:25];
        [self.slider setAction:@selector(updateSlider:)];
        [self.slider setTarget:self];
        [self.slider release];
        
        NSAssert(self.scroller == nil, @"self.scroller should be nil here");
        NSRect scrollerRect = NSMakeRect(1.0f,17,frame.size.width-3, frame.size.height-19.0f);
        self.scroller = [[AudioAnaScrollView alloc] initWithFrame:scrollerRect];
        //[self.scroller setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.scroller setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self.scroller setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [self.scroller setAutoresizesSubviews:YES];
        [self.scroller setBorderType:NSLineBorder];
        [self.scroller setHasVerticalScroller:NO];
        [self.scroller setHasHorizontalScroller:YES];
        [self.scroller setHasHorizontalRuler:YES];
        [self.scroller setRulersVisible:YES];
        [[self.scroller horizontalRulerView] setMeasurementUnits:@"Points"];
        [[self.scroller horizontalRulerView] setReservedThicknessForAccessoryView:0];
        [[self.scroller horizontalRulerView] setReservedThicknessForMarkers:0];
        [self addSubview:self.scroller];
        [self.scroller release];
        
        NSRect contentRect = NSMakeRect(0, 0, 0, 0);
        
        contentRect.size = [NSScrollView contentSizeForFrameSize:scrollerRect.size horizontalScrollerClass:[NSScroller class] verticalScrollerClass:nil borderType:NSLineBorder controlSize:NSRegularControlSize scrollerStyle:NSScrollerStyleOverlay];
        WaveFormView *wfv = [[WaveFormView alloc] initWithFrame:contentRect];
        [wfv setTranslatesAutoresizingMaskIntoConstraints:YES];
        [wfv setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [self.scroller setDocumentView:wfv];
        [wfv release];
        
        //        NSDictionary *views = [NSDictionary dictionaryWithObjectsAndKeys:self.slider, @"slider", self.scroller, @"scroller", [self.scroller documentView], @"docView", nil];
        //        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-2-[slider]-2-|" options:0 metrics:nil views:views]];
        //[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-1-[scroller]-1-|" options:0 metrics:nil views:views]];
        // [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[scroller(>=10)]-0-[slider(==15)]-2-|" options:0 metrics:nil views:views]];
        
        //        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[docView]-0-|" options:0 metrics:nil views:views]];
        //        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[docView]-0-|" options:0 metrics:nil views:views]];
    }
    
    return self;
}

- (NSData *)data
{
    return data;
}

- (void)setData:(NSData *)inData
{
    WaveFormView *wfv = [self.scroller documentView];
    
    [data release];
    data = [inData retain];
    
    if( data != nil )
    {
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
            NSAssert( err == noErr, @"CoCoAudioAnaylizer: ExtAudioFileGetProperty1: returned %d", err );
            propSize = sizeof(SInt64);
            err = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileLengthFrames, &propSize, &fileFrameCount);
            NSAssert( err == noErr, @"CoCoAudioAnaylizer: ExtAudioFileGetProperty2: returned %d", err );
            
            wfv.sampleRate = clientFormat.mSampleRate;
            SetCanonical(&clientFormat, 1, true);
            
            propSize = sizeof(clientFormat);
            err = ExtAudioFileSetProperty(af, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
            NSAssert( err == noErr, @"CoCoAudioAnaylizer: ExtAudioFileSetProperty: returned %d", err );
            
            wfv.frameCount = fileFrameCount;
            NSLog( @"Frames: %lld", fileFrameCount );
            wfv.audioFrames = malloc(((UInt32)sizeof(AudioSampleType)) * wfv.frameCount);
            
            AudioBufferList bufList;
            bufList.mNumberBuffers = 1;
            bufList.mBuffers[0].mNumberChannels = 1;
            bufList.mBuffers[0].mData = wfv.audioFrames;
            bufList.mBuffers[0].mDataByteSize = (unsigned int)((sizeof(AudioSampleType)) * wfv.frameCount);
            UInt32 ioFrameCount = (unsigned int)fileFrameCount;
            err = ExtAudioFileRead(af, &ioFrameCount, &bufList);
            NSAssert( err == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", err );
            
            self.slider.maxValue = wfv.frameCount;
            self.slider.minValue = [[[self scroller] contentView] frame].size.width;
            self.slider.floatValue = wfv.frameCount;
            
            [wfv setAutoresizingMask:NSViewHeightSizable];
            [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount, [self.scroller contentSize].height)];
            
            NSView *clipView = [[self.scroller documentView] superview];
            NSSize clipViewFrameSize = [clipView frame].size;
            [clipView setBoundsSize:NSMakeSize([[self slider] floatValue], clipViewFrameSize.height)];
            
            NSMutableDictionary *optionsDictionary = [[[self superview] superview] valueForKeyPath:@"objectValue.optionsDictionary"];
            if( optionsDictionary != nil )
                optionsDictionary = [[NSMutableDictionary alloc] init];

            NSMutableDictionary *aaOptions = [optionsDictionary objectForKey:[AudioAnaylizer anayliserName]];
            
            if( aaOptions == nil )
            {
                aaOptions = [WaveFormView defaultOptions];
                [optionsDictionary setObject:aaOptions forKey:[AudioAnaylizer anayliserName]];
            }

            [wfv anaylizeAudioDataWithOptions:aaOptions];
        }
        
        err = ExtAudioFileDispose(af);    
    }
    else
    {
        if( wfv.audioFrames != nil )
        {
            free(wfv.audioFrames);
            wfv.audioFrames = nil;
        }
        wfv.frameCount = 0;
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

- (void)setFrame:(NSRect)frameRect
{
    self.slider.minValue = [[[self scroller] contentView] frame].size.width;
    
    NSView *clipView = [[self.scroller documentView] superview];
    NSSize clipViewFrameSize = [clipView frame].size;
    [clipView setBoundsSize:NSMakeSize((CGFloat)[[self slider] intValue], clipViewFrameSize.height)];
    
    [super setFrame:frameRect];
}

- (IBAction)updateSlider:(id)sender
{
    NSView *clipView = [[self.scroller documentView] superview];
    NSRect boundsRect = [clipView bounds];
    float width = boundsRect.size.width;
    float newWidth = [[self slider] floatValue];
    
    boundsRect.size.width = newWidth;
    boundsRect.origin.x += (width-newWidth)/2.0;
    [clipView setBounds:boundsRect];
}

- (void)deltaSlider:(float)delta fromPoint:(NSPoint)point
{
    CGFloat scale = [[self.scroller contentView] bounds].size.width / [[self.scroller contentView] frame].size.width;
    point = [self convertPoint:point fromView:nil];
    point.x *= scale;
    float ratio = 1.0 / (point.x / [[self.scroller contentView] bounds].size.width);

    NSView *clipView = [[self.scroller documentView] superview];
    NSRect boundsRect = [clipView bounds];
    float width = boundsRect.size.width;
    [self.slider setFloatValue:[self.slider floatValue]+delta];

    float newWidth = [[self slider] floatValue];
    boundsRect.size.width = newWidth;
    boundsRect.origin.x += (width-newWidth)/ratio;
    [clipView setBounds:boundsRect];
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

/* taken from: /Developer/Extras/CoreAudio/PublicUtility/CAStreamBasicDescription.h */

void SetCanonical(AudioStreamBasicDescription *clientFormat, UInt32 nChannels, bool interleaved)
// note: leaves sample rate untouched
{
    clientFormat->mFormatID = kAudioFormatLinearPCM;
    int sampleSize = ((UInt32)sizeof(AudioSampleType)); //SizeOf32(AudioSampleType);
    clientFormat->mFormatFlags = kAudioFormatFlagsCanonical;
    clientFormat->mBitsPerChannel = 8 * sampleSize;
    clientFormat->mChannelsPerFrame = nChannels;
    clientFormat->mFramesPerPacket = 1;
    if (interleaved)
        clientFormat->mBytesPerPacket = clientFormat->mBytesPerFrame = nChannels * sampleSize;
    else {
        clientFormat->mBytesPerPacket = clientFormat->mBytesPerFrame = sampleSize;
        clientFormat->mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
    }
}

