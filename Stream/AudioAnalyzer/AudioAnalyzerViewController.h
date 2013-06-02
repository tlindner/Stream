//
//  AudioAnalyzerViewController.h
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AudioAnaScrollView.h"
#import "WaveFormView.h"

@class AudioAnaScrollView;

@interface AudioAnalyzerViewController : NSViewController {
    AudioAnaScrollView *scroller;
    NSSlider *slider;
}
@property (assign) IBOutlet NSSegmentedControl *toolControl;
@property (assign) IBOutlet NSSlider *slider;
@property (assign) IBOutlet AudioAnaScrollView *scroller;

- (IBAction)updateSlider:(id)sender;
- (void)updateBounds:(NSRect)inRect;
- (void)deltaSlider:(float)delta fromPoint:(NSPoint)point;
- (void) reloadView;
- (IBAction)ConfigurableButton1:(id)sender;
- (void)analyzerIsDeallocating;

- (void) suspendObservations;
- (void) resumeObservations;

@end
