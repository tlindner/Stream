//
//  AnaylizerSettingPopOverViewController.h
//  Stream
//
//  Created by tim lindner on 8/13/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ColorGradientView.h"

@class AnaylizerSettingPopOverAccessoryViewController;

@interface AnaylizerSettingPopOverViewController : NSViewController
{
}

@property (assign) IBOutlet NSPopover *popover;
@property (assign) IBOutlet NSView *accessoryView;
@property (nonatomic, retain) AnaylizerSettingPopOverAccessoryViewController *avc;

- (IBAction)sourceUTIAction:(id)sender;
- (void)setAccessoryView;

@end
