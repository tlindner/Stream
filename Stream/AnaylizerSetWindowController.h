//
//  AnaylizerSetWindowController.h
//  Stream
//
//  Created by tim lindner on 5/18/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AnaylizerSetWindowController : NSWindowController

@property (assign) NSManagedObjectContext *managedObjectContext;
@property (assign) IBOutlet NSTableView *anaylizerTableView;
@property (assign) IBOutlet NSArrayController *anaylizerArrayController;
@property (assign) IBOutlet NSArrayController *anaylizetSetsController;

- (IBAction)deleteAnaylizerSet:(id)sender;
- (IBAction)nameFieldAction:(id)sender;

@end
