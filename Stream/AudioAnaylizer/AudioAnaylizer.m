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
        
        NSRect sliderRect = NSMakeRect(1.0f, 1.0, frame.size.width-2, 15.0f);
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
        NSRect scrollerRect = NSMakeRect(1.0f,17,frame.size.width-2, frame.size.height-19.0f);
        self.scroller = [[NSScrollView alloc] initWithFrame:scrollerRect];
        //[self.scroller setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.scroller setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self.scroller setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [self.scroller setAutoresizesSubviews:YES];
        [self.scroller setBorderType:NSLineBorder];
        [self.scroller setHasVerticalScroller:NO];
        [self.scroller setHasHorizontalScroller:YES];
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
            propSize = sizeof(SInt64);
            err = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileLengthFrames, &propSize, &fileFrameCount);
            
            wfv.frameCount = sizeof(uint8) * fileFrameCount;
            wfv.audioFrames = malloc(wfv.frameCount);
            
            AudioBufferList bufList;
            bufList.mNumberBuffers = 1;
            bufList.mBuffers[0].mNumberChannels = 1;
            bufList.mBuffers[0].mData = wfv.audioFrames;
            bufList.mBuffers[0].mDataByteSize = (unsigned int)wfv.frameCount;
            UInt32 ioFrameCount = (unsigned int)fileFrameCount;
            err = ExtAudioFileRead(af, &ioFrameCount, &bufList);
            
            float avaiableWidth = [self.scroller frame].size.width;
            self.slider.maxValue = wfv.frameCount/avaiableWidth;
            self.slider.minValue = 1;
            self.slider.floatValue = wfv.frameCount/avaiableWidth;
            wfv.scale = self.slider.intValue;

            [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount/[self.slider floatValue], [self.scroller contentSize ].height)];
            //[[self.scroller documentView] setNeedsDisplay:YES];
            [self.scroller setNeedsDisplay:YES];
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
    WaveFormView *wfv = [self.scroller documentView];
    float avaiableWidth = frameRect.size.width;
    self.slider.maxValue = wfv.frameCount/avaiableWidth;
    self.slider.minValue = 1;
    wfv.scale = self.slider.intValue;
    
    [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount/[self.slider floatValue], [self.scroller contentSize ].height)];
    [self.scroller setNeedsDisplay:YES];
    [super setFrame:frameRect];
}

- (IBAction)updateSlider:(id)sender
{
    WaveFormView *wfv = [self.scroller documentView];
    wfv.scale = self.slider.intValue;
    [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount/[self.slider floatValue], [self.scroller contentSize].height)];
    [self.scroller.documentView setNeedsDisplay:YES];
}

- (void)viewDidEndLiveResize
{
    WaveFormView *wfv = [self.scroller documentView];
    float maxValue = wfv.frameCount/[self bounds].size.width;
    self.slider.maxValue = maxValue;
    [self updateSlider:self];

    [super viewDidEndLiveResize];
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

