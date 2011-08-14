//
//  AnaylizerSettingPopOverViewController.m
//  Stream
//
//  Created by tim lindner on 8/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AnaylizerSettingPopOverViewController.h"

@implementation AnaylizerSettingPopOverViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)popOverOK:(id)sender
{
    [cgv popOverOK:sender];
}

- (IBAction)popOverCancel:(id)sender
{
    [cgv popOverCancel:sender];
}

//- (void)dealloc {
//    NSLog( @"Why did I die: AnaylizerSettingPopOverViewController" );
//    [super dealloc];
//}

@end
