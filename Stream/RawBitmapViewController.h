//
//  RawBitmapViewController.h
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RawBitmapViewController : NSViewController
{
    BOOL observationsActive;
}
@property (nonatomic, assign) IBOutlet NSImageView *imageView;

- (void) suspendObservations;
- (void) resumeObservations;
- (IBAction)imageChanging:(id)sender;

@end
