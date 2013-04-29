//
//  AnaylizerSettingPopOverAccessoryViewController.m
//  Stream
//
//  Created by tim lindner on 8/13/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "AnaylizerSettingPopOverAccessoryViewController.h"
#import "StAnaylizer.h"

@implementation AnaylizerSettingPopOverAccessoryViewController

@synthesize groupBox;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
- (IBAction)ConfigurableButton1:(id)sender {

    StAnaylizer *anaylizer = [self representedObject];
    
    if ([anaylizer respondsToSelector:@selector(ConfigurableButton1:)]) {
        [anaylizer ConfigurableButton1:sender];
    }
}

@end
