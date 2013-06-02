//
//  AnalyzerSettingPopOverAccessoryViewController.m
//  Stream
//
//  Created by tim lindner on 8/13/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "AnalyzerSettingPopOverAccessoryViewController.h"
#import "StAnalyzer.h"

@implementation AnalyzerSettingPopOverAccessoryViewController

@synthesize groupBox;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
- (IBAction)ConfigurableButton1:(id)sender
{
    StAnalyzer *analyzer = [self representedObject];
    
    if ([analyzer respondsToSelector:@selector(ConfigurableButton1:)]) {
        [analyzer ConfigurableButton1:sender];
    }
}

- (IBAction)ConfigurableButton2:(id)sender
{
    StAnalyzer *analyzer = [self representedObject];
    
    if ([analyzer respondsToSelector:@selector(ConfigurableButton2:)]) {
        [analyzer ConfigurableButton2:sender];
    }
}
@end
