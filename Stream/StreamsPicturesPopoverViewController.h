//
//  StreamsPicturesPopoverViewController.h
//  Stream
//
//  Created by tim lindner on 5/18/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StreamsPicturesPopoverViewController : NSViewController
{
    NSStringEncoding myEncoding;
}

@property (retain) NSURL *textFileURL;
@property (assign) NSScrollView *textScrollView;

@property (assign) IBOutlet NSPopover *popover;
@property (assign) IBOutlet NSPopUpButton *popupButton;
@property (assign) IBOutlet NSImageView *imageView;
@property (assign) IBOutlet NSStepper *stepper;

- (void)saveAndLoadTextFile:(NSURL *)aFile;
- (IBAction)clickDone:(id)sender;
- (IBAction)showPopover:(id)sender;
- (IBAction)changePopupButton:(id)sender;
- (IBAction)clickStepper:(id)sender;

@end
