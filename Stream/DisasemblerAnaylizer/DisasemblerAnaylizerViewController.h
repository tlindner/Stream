//
//  DisasemblerAnaylizerViewController.h
//  Stream
//
//  Created by tim lindner on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StAnaylizer;

@interface DisasemblerAnaylizerViewController : NSViewController
{
    BOOL observationsActive;
}

@property (assign) IBOutlet NSTextView *textView;

@property (nonatomic,retain) StAnaylizer *lastAnaylizer;

@end
