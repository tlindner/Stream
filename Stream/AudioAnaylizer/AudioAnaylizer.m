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
        //[slider release];
        
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
        //[self.scroller release];
        
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
            
            //[self.objectValue addObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel" options:NSKeyValueChangeSetting context:nil];

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
            else
            {
                self.slider.floatValue = retrieveScale;
                [self updateSlider:self];
            }
            
            float retrieveOrigin = [[self.objectValue valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scrollOrigin"] floatValue];
                [[self.scroller contentView] scrollToPoint:NSMakePoint(retrieveOrigin, 0.0f)];
            
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

//- (void)prepareAccessoryView: (NSView *)baseView
//{
//    NSPopUpButton *channelsPopup = [baseView viewWithTag:6809];
//    WaveFormView *wfv = [self.scroller documentView];
//        
//    [channelsPopup setEnabled:YES];
//    [channelsPopup removeAllItems];
//    
//    for( int i=1; i<=wfv.channelCount; i++ )
//    {
//        [channelsPopup addItemWithTitle:[NSString stringWithFormat:@"%d", i]];
//    }
//}

- (void)dealloc
{
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
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
//    id newObject;
//    
//    if ([keyPath isEqualToString:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel"])
//    {
//        newObject = [change objectForKey:@"new"];
//        if ([newObject respondsToSelector:@selector(intValue)] && [newObject intValue] != currentChannel)
//        {
//            [self setData:data];
//        }
//        
//        return;
//    }
//    
//    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//}

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
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:1094.68085106384f], @"lowCycle", [NSNumber numberWithFloat:2004.54545454545f], @"highCycle", [NSNumber numberWithFloat:NAN], @"scale", [NSNumber numberWithFloat:-1.0], @"scrollOrigin", [NSNumber numberWithFloat:300.0],@"resyncThreashold", @"1", @"audioChannel", [NSArray arrayWithObject:@"1"], @"audioChannelList", nil] autorelease];
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

