//
//  NewAnalyzerSetWindowController.h
//  Stream
//
//  Created by tim lindner on 5/18/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NewAnalyzerSetWindowController : NSWindowController
@property (assign) IBOutlet NSTextField *nameField;
@property (assign) IBOutlet NSTextField *groupField;
@property (assign) IBOutlet NSTextField *keyComboField;
@property (assign) IBOutlet NSButton *okButton;

- (IBAction)clickOK:(id)sender;
- (IBAction)clickCancel:(id)sender;

@end
