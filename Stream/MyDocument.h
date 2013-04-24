//
//  MyDocument.h
//  Stream
//
//  Created by tim lindner on 7/23/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SDListView.h"

@class StStream;

@interface MyDocument : NSPersistentDocument {

    NSScrollView *streamListView;
    SDListView *listView;
}

@property (assign) IBOutlet NSTreeController *streamTreeControler;
@property (assign) IBOutlet NSWindow *documentWindow;
@property (assign) IBOutlet NSScrollView *streamListView;
@property (nonatomic, retain) NSCursor *zoomCursor;
@property (assign) IBOutlet SDListView *listView;
@property (retain) StStream *observingStream;

- (IBAction)add:(id)sender;
- (void) addStreamFromURL:(NSURL *)aURL;
- (IBAction)removeStream:(id)sender;
- (IBAction)removeAnaylizer:(id)sender;
- (void) flushAnaylizer:(NSDictionary *)parameter;

@end
