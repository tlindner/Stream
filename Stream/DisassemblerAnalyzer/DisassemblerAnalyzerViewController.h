//
//  DisassemblerAnalyzerViewController.h
//  Stream
//
//  Created by tim lindner on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StAnalyzer;

@interface DisassemblerAnalyzerViewController : NSViewController
{
    BOOL observationsActive;
}

@property (assign) IBOutlet NSTextView *textView;
@property (nonatomic,retain) StAnalyzer *lastAnalyzer;

- (void) suspendObservations;
- (void) resumeObservations;

@end
