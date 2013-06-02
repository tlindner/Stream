//
//  AppDelegate.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StStream, NewAnalyzerSetWindowController, AnalyzerSetWindowController, GetNetURLWindowController;

@interface AppDelegate : NSObject
{
//    NSMenu *blocksMenu;
}

@property (assign) IBOutlet NSMenu *blocksMenu;
@property (assign) IBOutlet NSMenu *setsMenu;
@property (retain) NSManagedObjectContext *anaSetsContext;
@property (retain) NewAnalyzerSetWindowController *analyzerSetGetInformation;
@property (retain) AnalyzerSetWindowController *manageAnalyzerWindowController;
@property (retain) GetNetURLWindowController *urlWindowController;

- (void) addBlockerMenu:(NSString *)classNameString;
- (IBAction)makeAnalyzerSet:(id)sender;
- (IBAction)manageAnalyzerSets:(id)sender;
- (void) addAnalyzerSetMenu:(NSString *)name withGroup:(NSString *)group withKey:(NSString *)commandKey representedBy:(NSManagedObject *)representedObject;
- (NSManagedObject *)analyzerSetNamed:(NSString *)name;
- (void)reloadAllAnalyzerSetMenuItems;
- (NSURL *)getURLFromUser;

@end

@interface NSError (ExtendedErrorCategory)
- (NSString *)debugDescription;
@end