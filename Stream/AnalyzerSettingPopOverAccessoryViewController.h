//
//  AnalyzerSettingPopOverAccessoryViewController.h
//  Stream
//
//  Created by tim lindner on 8/13/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AnalyzerSettingPopOverAccessoryViewController : NSViewController

@property (assign) IBOutlet NSBox *groupBox;

- (IBAction)ConfigurableButton1:(id)sender;
- (IBAction)ConfigurableButton2:(id)sender;

@end

