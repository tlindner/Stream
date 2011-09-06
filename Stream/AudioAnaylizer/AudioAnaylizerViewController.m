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

-(void)loadView
{
    [super loadView];
    
    [self.scroller setHasVerticalScroller:NO];
    [self.scroller setHasHorizontalScroller:YES];
    [self.scroller setHasVerticalRuler:NO];
    [self.scroller setHasHorizontalRuler:YES];
    [self.scroller setRulersVisible:YES];
    [[self.scroller horizontalRulerView] setMeasurementUnits:@"Points"];
    [[self.scroller horizontalRulerView] setReservedThicknessForAccessoryView:0];
    [[self.scroller horizontalRulerView] setReservedThicknessForMarkers:0];
    
    StAnaylizer *theAna = [self representedObject];
    
    //trackingArea = [[[NSTrackingArea alloc] initWithRect:scrollerRect options:NSTrackingCursorUpdate+NSTrackingActiveAlways owner:[self.scroller documentView] userInfo:nil] autorelease];
    //[self addTrackingArea:trackingArea];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipViewBoundsChanged:) name:NSViewBoundsDidChangeNotification object:nil];
    [[self.scroller contentView] setPostsBoundsChangedNotifications:YES];
    
    WaveFormView *wfv = [self.scroller documentView];
    wfv.viewController = self;
    self.scroller.viewController = self;

    [theAna addSubOptionsDictionary:[AudioAnaylizerViewController anaylizerKey] withDictionary:[AudioAnaylizerViewController defaultOptions]];
    UInt32 propSize;
    OSStatus myErr;
    
    wfv.cachedAnaylizer = theAna;

    if( [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.initializedOD"] boolValue] == YES )
    {
        /* Read in options data */
        
        wfv.channelCount = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.channelCount"] unsignedIntegerValue];
        wfv.currentChannel = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"] integerValue];
        wfv.sampleRate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"] doubleValue];
        wfv.frameCount = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"] unsignedLongLongValue];
    }
    else
    {
        NSManagedObject *parentStream = [theAna valueForKeyPath:@"parentStream"];
        NSURL *fileURL = [parentStream valueForKey:@"sourceURL"];
        
        /* Convert data to samples */
        ExtAudioFileRef af;
        myErr = ExtAudioFileOpenURL((CFURLRef)fileURL, &af);
        
        if (myErr == noErr)
        {
            [theAna willChangeValueForKey:@"optionsDictionary"];
            SInt64 fileFrameCount;
            
            AudioStreamBasicDescription clientFormat;
            propSize = sizeof(clientFormat);
            
            myErr = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileDataFormat, &propSize, &clientFormat);
            NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileGetProperty1: returned %d", myErr );
            
            wfv.channelCount = clientFormat.mChannelsPerFrame;
            [theAna setValue:[NSNumber numberWithUnsignedInt:clientFormat.mChannelsPerFrame] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.channelCount"];
            
            wfv.currentChannel = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"] integerValue];
            
            wfv.sampleRate = clientFormat.mSampleRate;
            [theAna setValue:[NSNumber numberWithDouble:clientFormat.mSampleRate] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"];
            
            /* Build array for channel popup list in accessory view */
            if( wfv.channelCount > 1 )
            {
                NSMutableArray *theChannelList = [[NSMutableArray alloc] init];
                for( int i=1; i<=wfv.channelCount; i++ )
                {
                    [theChannelList addObject:[NSString stringWithFormat:@"%d", i]];
                }
                
                [theAna setValue:theChannelList forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannelList"];
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
            [theAna setValue:[NSNumber numberWithUnsignedLongLong:fileFrameCount] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"];
            
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
            
            [theAna setValue:frameBufferObject forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"];
            [theAna didChangeValueForKey:@"optionsDictionary"];
            [wfv anaylizeAudioData];
            
            [theAna setValue:[NSNumber numberWithBool:YES] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.initializedOD"];
            
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
        [theAna addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle" options:NSKeyValueChangeSetting context:nil];
        [theAna addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle" options:NSKeyValueChangeSetting context:nil];
        [theAna addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold" options:NSKeyValueChangeSetting context:nil];
        [theAna addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel" options:NSKeyValueChangeSetting context:nil];
        wfv.observationsActive = YES;
    }
    
    NSView *clipView = [self.scroller contentView];
    self.slider.maxValue = wfv.frameCount;
    self.slider.minValue = [clipView frame].size.width / MAXZOOM;
    self.slider.floatValue = wfv.frameCount;
    
    [wfv setAutoresizingMask:NSViewHeightSizable];
    [[self.scroller documentView] setFrameSize:NSMakeSize(wfv.frameCount, [self.scroller contentSize].height)];
    
    float retrieveScale = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"] floatValue];
    
    if( isnan(retrieveScale) )
        [theAna setValue:[NSNumber numberWithFloat:self.slider.floatValue] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
    else
        [self.slider setFloatValue:retrieveScale];
    
    float retrieveOrigin = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scrollOrigin"] floatValue];
    
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
    WaveFormView *wfv = [self.scroller documentView];

    if( wfv.observationsActive == YES )
    {
        StAnaylizer *theAna = [self representedObject];
        [theAna removeObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"];
        [theAna removeObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"];
        [theAna removeObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"];
        [theAna removeObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"];
        wfv.observationsActive = NO;
    } 
    
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
    
    NSRect rect = [[self.scroller documentView] frame];
    rect.size.height = boundsRect.size.height;
    [[self.scroller documentView] setFrame:rect];
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

    NSRect rect = [[self.scroller documentView] frame];
    rect.size.height = newBoundsRect.size.height;
    [[self.scroller documentView] setFrame:rect];
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

    NSRect rect = [[self.scroller documentView] frame];
    rect.size.height = boundsRect.size.height;
    [[self.scroller documentView] setFrame:rect];
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.audio"];
}

+ (NSString *)anayliserName
{
    return @"Color Computer Audio Anaylizer";
}

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


