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

}

@property(nonatomic, retain) NSCursor *zoomCursor;

- (IBAction)add:(id)sender;

@end
