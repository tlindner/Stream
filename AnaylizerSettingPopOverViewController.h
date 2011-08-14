//
//  AnaylizerSettingPopOverViewController.h
//  Stream
//
//  Created by tim lindner on 8/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ColorGradientView.h"

@interface AnaylizerSettingPopOverViewController : NSViewController
{
    IBOutlet ColorGradientView *cgv;
}

- (IBAction)popOverOK:(id)sender;
- (IBAction)popOverCancel:(id)sender;

@end
