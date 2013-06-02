//
//  BlockAttributeViewController.h
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StData.h"
#import "StBlock.h"

@interface BlockAttributeViewController : NSViewController {
    NSArrayController *arrayController;
    StBlockFormatter *blockFormatter;
    NSTableView *tableView;
    BOOL observationsActive;
    StData *lastFilterAnalyzer;
}

@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet StBlockFormatter *blockFormatter;

- (void) reloadView;
- (void) suspendObservations;
- (void) resumeObservations;

@end
