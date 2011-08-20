//
//  AudioAnaylizer.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "AudioAnaylizer.h"
#import "WaveFormView.h"
#import "AudioAnaScrollView.h"

#define MAXZOOM 16.0

@implementation AudioAnaylizer

@dynamic data;
@synthesize result;
@synthesize scroller;
@synthesize slider;
@synthesize newConstraints;
@synthesize objectValue;
@synthesize toolSegment;

+ (void)initialize {
    if (self == [AudioAnaylizer class]) {
        [self exposeBinding:@"data"];
        [self exposeBinding:@"result"];
    }
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
        [self setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setAutoresizesSubviews:YES];
        
        NSRect buttonRect = NSMakeRect(1.0, 1.0, 100*3, 15);
        toolSegment = [[NSSegmentedControl alloc] initWithFrame:buttonRect];
        [self.toolSegment setSegmentCount:3];
        [[self.toolSegment cell] setControlSize:NSMiniControlSize];
        [self.toolSegment setFont:[NSFont controlContentFontOfSize:[NSFont smallSystemFontSize]]];
        [self.toolSegment setLabel:@"Selection" forSegment:0];
        [self.toolSegment setLabel:@"Pan" forSegment:1];
        [self.toolSegment setLabel:@"Lupe" forSegment:2];
        [self.toolSegment setImage:[NSImage imageNamed:@"AnaylizerArrow"] forSegment:0];
        [self.toolSegment setImage:[NSImage imageNamed:@"AnaylizerHand"] forSegment:1];
        [self.toolSegment setImage:[NSImage imageNamed:@"AnaylizerLupe"] forSegment:2];
        [self.toolSegment setImageScaling:NSImageScaleProportionallyDown forSegment:0];
        [self.toolSegment setImageScaling:NSImageScaleProportionallyDown forSegment:1];
        [self.toolSegment setImageScaling:NSImageScaleProportionallyDown forSegment:2];
        [self addSubview:toolSegment];
        [self.toolSegment sizeToFit];
        [self.toolSegment setSelectedSegment:0];
        
        CGFloat segWidth = [self.toolSegment frame].size.width;
        NSRect sliderRect = NSMakeRect(segWidth+2.0, 2.0, frame.size.width-3.0-segWidth, 15.0f);
        NSAssert(self.slider == nil, @"self.slider should be nil here");
        self.slider = [[[NSSlider alloc] initWithFrame:sliderRect] autorelease];
        
        [self addSubview:slider];
        //[self.slider setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.slider setTranslatesAutoresizingMaskIntoConstraints:YES];
        [self.slider setAutoresizingMask:NSViewWidthSizable];
        [[self.slider cell] setControlSize:NSMiniControlSize];
        [self.slider setTickMarkPosition:(NSTickMarkAbove)];
        [self.slider setNumberOfTickMarks:25];
        [self.slider setAction:@selector(updateSlider:)];
        [self.slider setTarget:self];
        
        NSAssert(self.scroller == nil, @"self.scroller should be nil here");
        NSRect scrollerRect = NSMakeRect(1.0f,17,frame.size.width-3, frame.size.height-19.0f);
        self.scroller = [[[AudioAnaScrollView alloc] initWithFrame:scrollerRect] autorelease];
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
        
        NSRect contentRect = NSMakeRect(0, 0, 0, 0);
        
        contentRect.size = [NSScrollView contentSizeForFrameSize:scrollerRect.size horizontalScrollerClass:[NSScroller class] verticalScrollerClass:nil borderType:NSLineBorder controlSize:NSRegularControlSize scrollerStyle:NSScrollerStyleOverlay];
        WaveFormView *wfv = [[WaveFormView alloc] initWithFrame:contentRect];
        [wfv setTranslatesAutoresizingMaskIntoConstraints:YES];
        [wfv setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [self.scroller setDocumentView:wfv];
        [wfv release];
 
        [self.toolSegment setAction:@selector(chooseTool:)];
        [self.toolSegment setTarget:[self.scroller documentView]];
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
    self.objectValue = [[[self superview] superview] valueForKey:@"objectValue"];
    [self.objectValue addSubOptionsDictionary:[AudioAnaylizer anaylizerKey] withDictionary:[AudioAnaylizer defaultOptions]];
    UInt32 propSize;
    OSStatus myErr;
   
    if( inData != data )
    {
        [data release];
        data = [inData retain];
    }
    
    if( data != nil )
    {
        NSManagedObject *parentStream = [self.objectValue valueForKeyPath:@"parentStream"];
        NSURL *fileURL = [parentStream valueForKey:@"sourceURL"];

        /* Convert data to samples */
        ExtAudioFileRef af;
        myErr = ExtAudioFileOpenURL((CFURLRef)fileURL, &af);
        
        if (myErr == noErr)
        {
            SInt64 fileFrameCount;
            
            AudioStreamBasicDescription clientFormat;
            propSize = sizeof(clientFormat);
            
            myErr = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileDataFormat, &propSize, &clientFormat);
            NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileGetProperty1: returned %d", myErr );
            
            wfv.channelCount = clientFormat.mChannelsPerFrame;
            wfv.currentChannel = [[self.objectValue valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel"] intValue];
            wfv.sampleRate = clientFormat.mSampleRate;
            
            /* Build array for channel popup list in accessory view */
            if( wfv.channelCount > 1 )
            {
                NSMutableArray *theChannelList = [[NSMutableArray alloc] init];
                for( int i=1; i<=wfv.channelCount; i++ )
                {
                    [theChannelList addObject:[NSString stringWithFormat:@"%d", i]];
                }
                [self.objectValue setValue:theChannelList forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannelList"];
                [theChannelList release];
            }
            
            propSize = sizeof(SInt64);
            myErr = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileLengthFrames, &propSize, &fileFrameCount);
            NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileGetProperty2: returned %d", myErr );
            
            SetCanonical(&clientFormat, (UInt32)wfv.channelCount, YES);

            propSize = sizeof(clientFormat);
            myErr = ExtAudioFileSetProperty(af, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
            NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileSetProperty: returned %d", myErr );

            wfv.frameCount = fileFrameCount;
            
            if (wfv.audioFrames != nil)
                free(wfv.audioFrames);

            wfv.audioFrames = malloc(((UInt32)sizeof(AudioSampleType)) * wfv.frameCount * wfv.channelCount);
            
            AudioBufferList bufList;
            bufList.mNumberBuffers = 1;
            bufList.mBuffers[0].mNumberChannels = (UInt32)wfv.channelCount;
            bufList.mBuffers[0].mData = wfv.audioFrames;
            bufList.mBuffers[0].mDataByteSize = (unsigned int)((sizeof(AudioSampleType)) * wfv.frameCount * wfv.channelCount);
            UInt32 ioFrameCount = (unsigned int)fileFrameCount;
            myErr = ExtAudioFileRead(af, &ioFrameCount, &bufList);
            NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", myErr );
            
            self.slider.maxValue = wfv.frameCount;
            self.slider.minValue = [[[self scroller] contentView] frame].size.width / MAXZOOM;
            self.slider.floatValue = wfv.frameCount;
            
            [wfv setAutoresizingMask:NSViewHeightSizable];
            [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount, [self.scroller contentSize].height)];
            
            NSView *clipView = [[self.scroller documentView] superview];
            NSSize clipViewFrameSize = [clipView frame].size;
            [clipView setBoundsSize:NSMakeSize([[self slider] floatValue], clipViewFrameSize.height)];
            
            float retrieveScale = [[self.objectValue valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scale"] floatValue];
            if( isnan(retrieveScale) )
            {
                [self.objectValue setValue:[NSNumber numberWithFloat:self.slider.floatValue] forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scale"];
            }
            
            [self.slider setFloatValue:retrieveScale];
            //[self.slider bind:@"floatValue" toObject:self.objectValue withKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scale" options:nil];
            
            float retrieveOrigin = [[self.objectValue valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scrollOrigin"] floatValue];
            [[self.scroller documentView] scrollPoint:NSMakePoint(retrieveOrigin, 0.0f)];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipViewBoundsChanged:) name:NSViewBoundsDidChangeNotification object:nil];
            [clipView setPostsBoundsChangedNotifications:YES];
            
            
            [wfv anaylizeAudioDataWithOptions:self.objectValue];
        }
        
        myErr = ExtAudioFileDispose(af);
        NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", myErr );
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

- (void)clipViewBoundsChanged:(NSNotification *)notification
{
    NSView *theView = [notification object];
    
    if( [self.scroller contentView] == theView )
    {
        [self.objectValue setValue:[NSNumber numberWithFloat:[theView bounds].origin.x] forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scrollOrigin"];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //[self.slider unbind:@"floatValue"];
    [self.objectValue unbind:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel"];
    
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
    [super setFrame:frameRect];
    self.slider.minValue = [[[self scroller] contentView] frame].size.width / MAXZOOM;
    
    NSView *clipView = [[self.scroller documentView] superview];
    NSSize clipViewFrameSize = [clipView frame].size;
    [clipView setBoundsSize:NSMakeSize((CGFloat)[[self slider] intValue], clipViewFrameSize.height)];
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
    [self.objectValue setValue:[NSNumber numberWithFloat:newWidth] forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scale"];
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
    [self.objectValue setValue:[NSNumber numberWithFloat:newWidth] forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scale"];
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.audio"];
}

+ (NSString *)anayliserName
{
    return @"Color Computer Audio Anaylizer";
}

/* Used for KVC and KVO in anaylizer options dictionary */
+ (NSString *)anaylizerKey;
{
    return @"ColorComputerAudioAnaylizer";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"AudioAnaylizer";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:1094.68085106384f], @"lowCycle", [NSNumber numberWithFloat:2004.54545454545f], @"highCycle", [NSNumber numberWithFloat:NAN], @"scale", [NSNumber numberWithFloat:0], @"scrollOrigin", [NSNumber numberWithFloat:300.0],@"resyncThreashold", @"1", @"audioChannel", [NSArray arrayWithObject:@"1"], @"audioChannelList", nil] autorelease];
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

