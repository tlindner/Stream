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

- (void)setRepresentedObject:(id)inRepresentedObject
{
    if( inRepresentedObject == nil )
    {
        WaveFormView *wfv = [self.scroller documentView];
        
        if( wfv.observationsActive == YES )
        {
            StAnaylizer *theAna = [self representedObject];
            [theAna removeObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"];
            [theAna removeObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"];
            [theAna removeObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"];
            [theAna removeObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"];
            [theAna removeObserver:wfv forKeyPath:@"resultingData"];
            wfv.observationsActive = NO;
        } 
    }
    
    [super setRepresentedObject:inRepresentedObject];
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

    wfv.cachedAnaylizer = theAna;
    unsigned long long frameCount = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"] unsignedLongLongValue];
    
    NSView *clipView = [self.scroller contentView];
    self.slider.maxValue = frameCount;
    self.slider.minValue = [clipView frame].size.width / MAXZOOM;
    self.slider.floatValue = frameCount;
    
    [wfv setAutoresizingMask:NSViewHeightSizable];
    [[self.scroller documentView] setFrameSize:NSMakeSize(frameCount, [self.scroller contentSize].height)];
    
    float retrieveScale = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"] floatValue];
    
    if( isnan(retrieveScale) )
        [theAna setValue:[NSNumber numberWithFloat:self.slider.floatValue] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
    else
        [self.slider setFloatValue:retrieveScale];
    
    float retrieveOrigin = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scrollOrigin"] floatValue];
    
    NSRect clipViewBounds = [clipView frame];

    [clipView setBounds:NSMakeRect(retrieveOrigin, clipViewBounds.origin.y, [[self slider] floatValue], clipViewBounds.size.height)];

    NSRect rect = [[self.scroller documentView] frame];
    rect.size.height = clipViewBounds.size.height;
    [[self.scroller documentView] setFrame:rect];
    
    if( wfv.observationsActive == NO )
    {
        [theAna addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle" options:NSKeyValueChangeSetting context:nil];
        [theAna addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle" options:NSKeyValueChangeSetting context:nil];
        [theAna addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold" options:NSKeyValueChangeSetting context:nil];
        [theAna addObserver:wfv forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel" options:NSKeyValueChangeSetting context:nil];
        [theAna addObserver:wfv forKeyPath:@"resultingData" options:NSKeyValueChangeReplacement context:nil];
         wfv.observationsActive = YES;
    }
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
        [theAna removeObserver:wfv forKeyPath:@"resultingData"];
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
//    [[self representedObject] willChangeValueForKey:@"optionsDictionary"];
    [[self representedObject] setValue:[NSNumber numberWithFloat:newWidth] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
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
    [[self representedObject] setValue:[NSNumber numberWithFloat:newBoundsRect.size.width] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
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
    [[self representedObject] setValue:[NSNumber numberWithFloat:newWidth] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.scale"];
//    [[self representedObject] didChangeValueForKey:@"optionsDictionary"];

    NSRect rect = [[self.scroller documentView] frame];
    rect.size.height = boundsRect.size.height;
    [[self.scroller documentView] setFrame:rect];
}

-(NSString *)nibName
{
    return @"AudioAnaylizerViewController";
}

@end
