//
//  AudioAnalyzerViewController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AudioAnalyzerViewController.h"
#include "AudioToolbox/AudioToolbox.h"
#import "Analyzation.h"
#import "CoCoAudioAnalyzer.h"

#define MAXZOOM 16.0

@implementation AudioAnalyzerViewController
@synthesize toolControl;
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

- (void)setRepresentedObject:(id)inRepresentedObject
{
    WaveFormView *wfv = [self.scroller documentView];
    if( wfv != nil )
        [wfv deactivateObservations];

    [super setRepresentedObject:inRepresentedObject];
}

-(void)loadView
{
    [super loadView];
    [self reloadView];
}

- (void) reloadView
{
    [self.scroller setHasVerticalScroller:NO];
    [self.scroller setHasHorizontalScroller:YES];
    [self.scroller setHasVerticalRuler:NO];
    [self.scroller setHasHorizontalRuler:YES];
    [self.scroller setRulersVisible:YES];
    [[self.scroller horizontalRulerView] setMeasurementUnits:@"Points"];
    [[self.scroller horizontalRulerView] setReservedThicknessForAccessoryView:0];
    [[self.scroller horizontalRulerView] setReservedThicknessForMarkers:0];
    
    StAnalyzer *theAna = [self representedObject];
    
    //trackingArea = [[[NSTrackingArea alloc] initWithRect:scrollerRect options:NSTrackingCursorUpdate+NSTrackingActiveAlways owner:[self.scroller documentView] userInfo:nil] autorelease];
    //[self addTrackingArea:trackingArea];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipViewBoundsChanged:) name:NSViewBoundsDidChangeNotification object:nil];
    [[self.scroller contentView] setPostsBoundsChangedNotifications:YES];
    
    WaveFormView *wfv = [self.scroller documentView];
    wfv.viewController = self;
    self.scroller.viewController = self;

    wfv.cachedAnalyzer = theAna;
//    CoCoAudioAnalyzer *modelObject = (CoCoAudioAnalyzer *)[theAna analyzerObject];
//    [modelObject analyzeData];
//    NSUInteger frameCount = [modelObject.frameBuffer length] / sizeof(AudioSampleType);
    NSUInteger frameCount = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.frameCount"] intValue];
    
    NSView *clipView = [self.scroller contentView];
    self.slider.maxValue = frameCount;
    self.slider.minValue = [clipView frame].size.width / MAXZOOM;
    self.slider.floatValue = frameCount;
    
//    [wfv setAutoresizingMask:NSViewHeightSizable];
    [[self.scroller documentView] setFrameSize:NSMakeSize(frameCount, [self.scroller contentSize].height)];
    
    float retrieveScale = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.scale"] floatValue];
    
    if( isnan(retrieveScale) )
        [theAna setValue:[NSNumber numberWithFloat:self.slider.floatValue] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.scale"];
    else
        [self.slider setFloatValue:retrieveScale];
    
    float retrieveOrigin = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.scrollOrigin"] floatValue];
    
    NSRect clipViewBounds = [clipView frame];

    [clipView setBounds:NSMakeRect(retrieveOrigin, clipViewBounds.origin.y, [[self slider] floatValue], clipViewBounds.size.height)];

    NSRect rect = [[self.scroller documentView] frame];
    rect.size.height = clipViewBounds.size.height;
    [[self.scroller documentView] setFrame:rect];
    [wfv activateObservations];
}

- (void)clipViewBoundsChanged:(NSNotification *)notification
{
    NSView *theView = [notification object];
    
    if( [self.scroller contentView] == theView )
    {
        [[self representedObject] setValue:[NSNumber numberWithFloat:[theView bounds].origin.x] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.scrollOrigin"];
    }
}

- (void)dealloc
{
//    StAnalyzer *theAna = [self representedObject];
//    theAna.viewController = nil;

    WaveFormView *wfv = [self.scroller documentView];
    [wfv deactivateObservations];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //[self removeTrackingArea:self.trackingArea];
    //self.trackingArea = nil;
    
    [super dealloc];
}

- (IBAction)updateSlider:(id)sender
{
    #pragma unused(sender)
    NSView *clipView = [[self.scroller documentView] superview];
    NSRect boundsRect = [clipView bounds];
    float width = boundsRect.size.width;
    float newWidth = [[self slider] floatValue];
    
    boundsRect.size.width = newWidth;
    boundsRect.origin.x += (width-newWidth)/2.0;
    
    [clipView setBounds:boundsRect];
//    [[self representedObject] willChangeValueForKey:@"optionsDictionary"];
    [[self representedObject] setValue:[NSNumber numberWithFloat:newWidth] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.scale"];
//    [[self representedObject] didChangeValueForKey:@"optionsDictionary"];
    
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
//    [[self representedObject] willChangeValueForKey:@"optionsDictionary"];
    [[self representedObject] setValue:[NSNumber numberWithFloat:newBoundsRect.size.width] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.scale"];
//    [[self representedObject] didChangeValueForKey:@"optionsDictionary"];
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
//    [[self representedObject] willChangeValueForKey:@"optionsDictionary"];
    [[self representedObject] setValue:[NSNumber numberWithFloat:newWidth] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.scale"];
//    [[self representedObject] didChangeValueForKey:@"optionsDictionary"];

    NSRect rect = [[self.scroller documentView] frame];
    rect.size.height = boundsRect.size.height;
    [[self.scroller documentView] setFrame:rect];
}

- (void)analyzerIsDeallocating
{
    WaveFormView *wfv = [self.scroller documentView];
    [wfv deactivateObservations];
}

- (IBAction)ConfigurableButton1:(id)sender
{
#pragma unused(sender)
    /* this should be hooked up the the analyze button */
    
    StAnalyzer *theAna = [self representedObject];
    CoCoAudioAnalyzer *modelObject = (CoCoAudioAnalyzer *)[theAna analyzerObject];
    WaveFormView *wfv = [self.scroller documentView];
    NSUInteger origin, width;
    
    [wfv getSelectionOrigin:&origin width:&width];
    [modelObject determineFrequencyOrigin:origin width:width];    
}

- (IBAction)ConfigurableButton2:(id)sender
{
#pragma unused(sender)
    /* this should be hooked up the the Zero button */
    
    StAnalyzer *theAna = [self representedObject];
    CoCoAudioAnalyzer *modelObject = (CoCoAudioAnalyzer *)[theAna analyzerObject];
    WaveFormView *wfv = [self.scroller documentView];
    NSUInteger origin, width;
    
    [wfv getSelectionOrigin:&origin width:&width];
    [modelObject zeroSamplesOrigin:origin width:width];
}

- (void) suspendObservations
{
    WaveFormView *wfv = [self.scroller documentView];
    [wfv deactivateObservations];

    StAnalyzer *theAna = [self representedObject];
    CoCoAudioAnalyzer *modelObject = (CoCoAudioAnalyzer *)[theAna analyzerObject];
    [modelObject suspendObservations];
}

- (void) resumeObservations
{
    WaveFormView *wfv = [self.scroller documentView];
    [wfv activateObservations];

    StAnalyzer *theAna = [self representedObject];
    CoCoAudioAnalyzer *modelObject = (CoCoAudioAnalyzer *)[theAna analyzerObject];
    [modelObject resumeObservations];
}

-(NSString *)nibName
{
    return @"AudioAnalyzerViewController";
}

@end
