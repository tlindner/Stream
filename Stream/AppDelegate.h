//
//  AppDelegate.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StStream, NewAnaylizerSetWindowController, AnaylizerSetWindowController;

@interface AppDelegate : NSObject
{
//    NSMenu *blocksMenu;
}

@property (assign) IBOutlet NSMenu *blocksMenu;
@property (assign) IBOutlet NSMenu *setsMenu;
@property (retain) NSManagedObjectContext *anaSetsContext;
@property (retain) NewAnaylizerSetWindowController *anaylizerSetGetInformation;
@property (retain) AnaylizerSetWindowController *manageAnaylizerWindowController;

- (void) addBlockerMenu:(NSString *)classNameString;
- (IBAction)makeAnaylizerSet:(id)sender;
- (IBAction)manageAnaylizerSets:(id)sender;
- (void) addAnaylizerSetMenu:(NSString *)name withGroup:(NSString *)group withKey:(NSString *)commandKey representedBy:(NSManagedObject *)representedObject;
- (NSManagedObject *)anaylizerSetNamed:(NSString *)name;

@end

@interface NSError (ExtendedErrorCategory)
- (NSString *)debugDescription;
@end