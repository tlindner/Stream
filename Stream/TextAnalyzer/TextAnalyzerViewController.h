//
//  TextAnalyzerViewController.h
//  Stream
//
//  Created by tim lindner on 4/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StAnalyzer.h"

@interface TextAnalyzerViewController : NSViewController
{
    BOOL observationsActive;
}

@property (assign) IBOutlet NSTextView *textView;
@property (nonatomic,retain) StAnalyzer *lastAnalyzer;

- (void)reloadView;
- (NSString *) transformInput;

- (void) suspendObservations;
- (void) resumeObservations;

@end
