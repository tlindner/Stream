//
//  AudioAnaylizerViewController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AudioAnaylizerViewController.h"
#include "AudioToolbox/AudioToolbox.h"
#import "Analyzation.h"

#define MAXZOOM 16.0

@implementation AudioAnaylizerViewController
@synthesize slider;
@synthesize scroller;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    
    return self;
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];

    //        trackingArea = [[[NSTrackingArea alloc] initWithRect:scrollerRect options:NSTrackingCursorUpdate+NSTrackingActiveAlways owner:[self.scroller documentView] userInfo:nil] autorelease];
    //        [self addTrackingArea:trackingArea];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipViewBoundsChanged:) name:NSViewBoundsDidChangeNotification object:nil];
    [[self.scroller contentView] setPostsBoundsChangedNotifications:YES];
    
    WaveFormView *wfv = [self.scroller documentView];
    wfv.viewController = self;
    self.scroller.viewController = self;

    NSString *key = [AudioAnaylizerViewController anaylizerKey];
    [representedObject addSubOptionsDictionary:key withDictionary:[AudioAnaylizerViewController defaultOptions]];
    UInt32 propSize;
    OSStatus myErr;
    
    wfv.cachedAnaylizer = representedObject;

    if( [[representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.initializedOD"] boolValue] == YES )
    {
        /* Read in options data */
        
        wfv.channelCount = [[representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.channelCount"] unsignedIntegerValue];
        wfv.currentChannel = [[representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"] intValue];
        wfv.sampleRate = [[representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"] doubleValue];
        wfv.frameCount = [[representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"] unsignedLongLongValue];
    }
    else
    {
        NSManagedObject *parentStream = [representedObject valueForKeyPath:@"parentStream"];
        NSURL *fileURL = [parentStream valueForKey:@"sourceURL"];
        
        /* Convert data to samples */
        ExtAudioFileRef af;
        myErr = ExtAudioFileOpenURL((CFURLRef)fileURL, &af);
        
        if (myErr == noErr)
        {
            [representedObject willChangeValueForKey:@"optionsDictionary"];
            SInt64 fileFrameCount;
            
            AudioStreamBasicDescription clientFormat;
            propSize = sizeof(clientFormat);
            
            myErr = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileDataFormat, &propSize, &clientFormat);
            NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileGetProperty1: returned %d", myErr );
            
            wfv.channelCount = clientFormat.mChannelsPerFrame;
            [representedObject setValue:[NSNumber numberWithUnsignedInt:clientFormat.mChannelsPerFrame] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.channelCount"];
            
            wfv.currentChannel = [[representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"] intValue];
            
            wfv.sampleRate = clientFormat.mSampleRate;
            [representedObject setValue:[NSNumber numberWithDouble:clientFormat.mSampleRate] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"];
            
            /* Build array for channel popup list in accessory view */
            if( wfv.channelCount > 1 )
            {
                NSMutableArray *theChannelList = [[NSMutableArray alloc] init];
                for( int i=1; i<=wfv.channelCount; i++ )
                {
                    [theChannelList addObject:[NSString stringWithFormat:@"%d", i]];
                }
                
                [representedObject setValue:theChannelList forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannelList"];
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
            [representedObject setValue:[NSNumber numberWithUnsignedLongLong:fileFrameCount] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"];
            
            size_t frameBufferSize = sizeof(AudioSampleType) * wfv.frameCount * wfv.channelCount;
            NSMutableData *frameBufferObject = [NSMutableData dataWithLength:frameBufferSize];
            AudioSampleType *audioFrames = [frameBufferObject mutableBytes];
            
            AudioBufferList bufList;
            bufList.mNumberBuffers = 1;
            bufList.mBuffers[0].mNumberChannels = (UInt32)wfv.channelCount;
            bufList.mBuffers[0].mData = audioFrames;
            bufList.mBuffers[0].mDataByteSize = (unsigned int)((sizeof(AudioSampleType)) * wfv.frameCount * wfv.channelCount);
            UInt32 ioFrameCount = (unsigned int)fileFrameCount;
            myErr = ExtAudioFileRead(af, &ioFrameCount, &bufList);
            NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", myErr );
            
            [representedObject setValue:frameBufferObject forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"];
            [representedObject didChangeValueForKey:@"optionsDictionary"];
            [wfv anaylizeAudioData];
            
            [representedObject setValue:[NSNumber numberWithBool:YES] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.initializedOD"];
            
            myErr = ExtAudioFileDispose(af);
            NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", myErr );
        }
        else
        {
            NSLog(@"CoCoAudioAnaylizer: ExtAudioFileOpenURL: could not open file");
            return;
        }
    }
    
    /* setup observations */
    if( wfv.observationsActive == NO )
    {
        [representedObject addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle" options:NSKeyValueChangeSetting context:nil];
        [representedObject addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle" options:NSKeyValueChangeSetting context:nil];
        [representedObject addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold" options:NSKeyValueChangeSetting context:nil];
        [representedObject addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel" options:NSKeyValueChangeSetting context:nil];
        wfv.observationsActive = YES;
    }
    
    NSView *clipView = [self.scroller contentView];
    self.slider.maxValue = wfv.frameCount;
    self.slider.minValue = [clipView frame].size.width / MAXZOOM;
    self.slider.floatValue = wfv.frameCount;
    
    [wfv setAutoresizingMask:NSViewHeightSizable];
    [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount, [self.scroller contentSize].height)];
    
    float retrieveScale = [[representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"] floatValue];
    
    if( isnan(retrieveScale) )
        [representedObject setValue:[NSNumber numberWithFloat:self.slider.floatValue] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
    else
        [self.slider setFloatValue:retrieveScale];
    
    float retrieveOrigin = [[representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scrollOrigin"] floatValue];
    
    NSRect clipViewBounds = [clipView frame];
    [clipView setBounds:NSMakeRect(retrieveOrigin, clipViewBounds.origin.y, [[self slider] floatValue], clipViewBounds.size.height)];
}

- (void)clipViewBoundsChanged:(NSNotification *)notification
{
    NSView *theView = [notification object];
    
    if( [self.scroller contentView] == theView )
    {
        [[self representedObject] setValue:[NSNumber numberWithFloat:[theView bounds].origin.x] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scrollOrigin"];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //[self removeTrackingArea:self.trackingArea];
    //self.trackingArea = nil;
    
    [super dealloc];
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
    [[self representedObject] willChangeValueForKey:@"optionsDictionary"];
    [[self representedObject] setValue:[NSNumber numberWithFloat:newWidth] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
    [[self representedObject] didChangeValueForKey:@"optionsDictionary"];
    
}

- (void)updateBounds:(NSRect)inRect
{
    CGFloat minimumWidth = [self.slider minValue];
    NSView *clipView = [[self.scroller documentView] superview];
    NSRect newBoundsRect = [clipView bounds];
    newBoundsRect.origin.x = inRect.origin.x;
    
    if( inRect.size.width < minimumWidth ) inRect.size.width = minimumWidth;
    
    newBoundsRect.size.width = inRect.size.width;
    [clipView setBounds:newBoundsRect];
    [[self representedObject] willChangeValueForKey:@"optionsDictionary"];
    [[self representedObject] setValue:[NSNumber numberWithFloat:newBoundsRect.size.width] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
    [[self representedObject] didChangeValueForKey:@"optionsDictionary"];
    [self.slider setFloatValue:newBoundsRect.size.width];
}

- (void)deltaSlider:(float)delta fromPoint:(NSPoint)point
{
    CGFloat scale = [[self.scroller contentView] bounds].size.width / [[self.scroller contentView] frame].size.width;
    point = [[self view] convertPoint:point fromView:nil];
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
    [[self representedObject] willChangeValueForKey:@"optionsDictionary"];
    [[self representedObject] setValue:[NSNumber numberWithFloat:newWidth] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
    [[self representedObject] didChangeValueForKey:@"optionsDictionary"];
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
    return @"AudioAnaylizerViewController";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"AudioAnaylizer";
}

-(NSString *)nibName
{
    return @"AudioAnaylizerViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:1094.68085106384f], @"lowCycle", [NSNumber numberWithFloat:2004.54545454545f], @"highCycle", [NSNumber numberWithFloat:NAN], @"scale", [NSNumber numberWithFloat:0], @"scrollOrigin", [NSNumber numberWithFloat:300.0],@"resyncThreashold", @"1", @"audioChannel", [NSArray arrayWithObject:@"1"], @"audioChannelList", [NSNull null], @"sampleRate", [NSNull null], @"channelCount", [NSNull null], @"frameCount", [NSNull null], @"coalescedObject", [NSNull null], @"frameBufferObject",[NSNumber numberWithBool:NO], @"initializedOD", nil] autorelease];
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


