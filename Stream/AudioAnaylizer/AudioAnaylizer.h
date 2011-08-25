//
//  AudioAnaylizer.h
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StAnaylizer.h"
#include "AudioToolbox/AudioToolbox.h"

typedef struct
{
    NSUInteger start;
    NSUInteger length;
} charRef;

void SetCanonical(AudioStreamBasicDescription *clientFormat, UInt32 nChannels, bool interleaved);

@interface AudioAnaylizer : NSView
{
    NSData *data;
    NSMutableArray *newConstraints;
}

@property(nonatomic, retain) NSData *data;
@property(nonatomic, retain) NSMutableArray *newConstraints;
@property(nonatomic, assign) StAnaylizer *objectValue;

/* UI */
@property(nonatomic, assign) NSScrollView *scroller;
@property(nonatomic, assign) NSSlider *slider;
@property(nonatomic, assign) NSSegmentedControl *toolSegment;
@property(nonatomic, assign) NSTrackingArea *trackingArea;

+ (NSArray *)anaylizerUTIs;
+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSMutableDictionary *)defaultOptions;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;

- (void)clipViewBoundsChanged:(NSNotification *)notification;
- (IBAction)updateSlider:(id)sender;
- (void)deltaSlider:(float)delta fromPoint:(NSPoint)point;
- (void)updateBounds:(NSRect)inRect;

@end
