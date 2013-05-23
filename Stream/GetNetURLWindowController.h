//
//  GetNetURLWindowController.h
//  Stream
//
//  Created by tim lindner on 5/22/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GetNetURLWindowController : NSWindowController
@property (assign) IBOutlet NSTextField *urlTextField;
@property (assign) IBOutlet NSPopUpButton *urlPopupButton;

- (IBAction)clickOK:(id)sender;
- (IBAction)clickCancel:(id)sender;
- (IBAction)menuChoose:(id)sender;

@end
