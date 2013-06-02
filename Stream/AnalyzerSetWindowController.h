//
//  AnalyzerSetWindowController.h
//  Stream
//
//  Created by tim lindner on 5/18/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AnalyzerSetWindowController : NSWindowController

@property (assign) NSManagedObjectContext *managedObjectContext;
@property (assign) IBOutlet NSTableView *analyzerTableView;
@property (assign) IBOutlet NSArrayController *analyzerArrayController;
@property (assign) IBOutlet NSArrayController *analyzerSetsController;

- (IBAction)deleteAnalyzerSet:(id)sender;
- (IBAction)nameFieldAction:(id)sender;

@end
