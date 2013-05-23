//
//  GetNetURLWindowController.m
//  Stream
//
//  Created by tim lindner on 5/22/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "GetNetURLWindowController.h"

@interface GetNetURLWindowController ()

@end

@implementation GetNetURLWindowController
@synthesize urlTextField;
@synthesize urlPopupButton;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)clickOK:(id)sender {
#pragma unused (sender)
    [NSApp stopModalWithCode:YES];
}

- (IBAction)clickCancel:(id)sender {
#pragma unused (sender)
    [NSApp stopModalWithCode:NO];
}

- (IBAction)menuChoose:(id)sender {
#pragma unused (sender)
    NSString *url = [[urlPopupButton selectedItem] title];
    [urlTextField setStringValue:url];
}

@end
