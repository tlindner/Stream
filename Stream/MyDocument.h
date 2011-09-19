//
//  MyDocument.h
//  Stream
//
//  Created by tim lindner on 7/23/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyDocument : NSPersistentDocument {

    IBOutlet NSTreeController *streamTreeControler;

    NSTableColumn *tableColumn;
    NSScrollView *streamListView;
}
@property (assign) IBOutlet NSScrollView *streamListView;
@property (assign) IBOutlet NSTableColumn *tableColumn;
@property (nonatomic, retain) NSCursor *zoomCursor;

- (IBAction)add:(id)sender;
- (void) addStreamFromURL:(NSURL *)aURL;
- (IBAction)removeStream:(id)sender;
- (IBAction)removeAnaylizer:(id)sender;
- (void) flushAnaylizer:(NSDictionary *)parameter;

@end
