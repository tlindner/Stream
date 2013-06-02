//
//  AppDelegate.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Analyzation.h"
#import "StStream.h"
#import "StAnalyzer.h"
#import "Blockers.h"
#import "NSFileManager+DirectoryLocations.h"
#import "NewAnalyzerSetWindowController.h"
#import "AnalyzerSetWindowController.h"
#import "GetNetURLWindowController.h"

@implementation AppDelegate

@synthesize blocksMenu;
@synthesize setsMenu;
@synthesize anaSetsContext;
@synthesize analyzerSetGetInformation;
@synthesize manageAnalyzerWindowController;
@synthesize urlWindowController;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSError *)application:(NSApplication *)theApplication willPresentError:(NSError *)error
{
#pragma unused (theApplication)
    // Log the error to the console for debugging
    NSLog(@"Application will present error:\n%@", [error description]);
    
    return error;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
#pragma unused (aNotification)
    NSError *err;
    
    err = nil;
    [self.anaSetsContext save:&err];
    
    if (err != nil) {
        NSLog( @"applicationWillTerminate saving managed object context error: %@", err );
    }
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    #pragma unused(notification)
    
    NSArray *classList = [Blockers sharedInstance].classList;
    NSArray *classListSorted = [classList sortedArrayUsingComparator: ^(id obj1, id obj2) {
        
        /* Build combined strings */
        Class obj1Class = NSClassFromString(obj1);
        Class obj2Class = NSClassFromString(obj2);
        NSString *obj1Group = [obj1Class blockerGroup];
        NSString *obj2Group = [obj2Class blockerGroup];
        
        NSString *obj1Built, *obj2Built;
        
        if ([obj1Group isEqualToString:@""]) {
            obj1Built = obj1;
        } else {
            obj1Built = [NSString stringWithFormat:@"%@ %@", obj1Group, obj1];
        }
        
        if ([obj2Group isEqualToString:@""]) {
            obj2Built = obj2;
        } else {
            obj2Built = [NSString stringWithFormat:@"%@ %@", obj2Group, obj2];
        }
        
        /* return comparison */
        return [obj1Built localizedCompare:obj2Built];
    }];

    for (NSString *blockerClassString in classListSorted) {
        [self addBlockerMenu:blockerClassString];
    }
    
    /* Initialize analyzer sets */
    NSString *appSupportDir = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSURL *anaSetsURL = [[[NSURL alloc] initFileURLWithPath:[appSupportDir stringByAppendingPathComponent:@"Analyzer Sets.binary"]] autorelease];
    NSBundle *myBundle = [NSBundle mainBundle];
    NSURL *mom = [myBundle URLForResource:@"MyDocument" withExtension:@"momd"];
    NSManagedObjectModel *om = [[[NSManagedObjectModel alloc] initWithContentsOfURL:mom] autorelease];
    NSPersistentStoreCoordinator *psc = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:om] autorelease];
    NSError *err = nil;
    NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:anaSetsURL options:nil error:&err];
            
    if (err != nil) {
        NSLog(@"error creating/loading “Analyzer Sets.binary”: %@\nLet's delete it and start over.", err);
        err = nil;
        [[NSFileManager defaultManager] removeItemAtURL:anaSetsURL error:&err];
        
        if (err == nil) {
            ps = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:anaSetsURL options:nil error:&err];
            if (err != nil) {
                NSLog( @"Error persists while trying to load “Analyzer Sets.binary”: %@", err );
            }
        } else {
            NSLog(@"Error removing existing “Analyzer Sets.binary”: %@", err);
        }
    }
    
    err = nil;
    
    [ps loadMetadata:&err];
    
    if (err != nil) {
        NSLog(@"error loading meta data for “Analyzer Sets.binary”: %@", err);
    }
    
    self.anaSetsContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
    [self.anaSetsContext setPersistentStoreCoordinator:psc];
    
    [self reloadAllAnalyzerSetMenuItems];
}

- (void)reloadAllAnalyzerSetMenuItems
{
    NSError *err = nil;
    [self.anaSetsContext save:&err];
    
    if (err != nil) {
        NSLog(@"Error at reloadAllAnalyzerSetMenuItems: %@", err);
    }
    
    while ([setsMenu numberOfItems] > 3) {
        [setsMenu removeItemAtIndex:3];
    }
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"StAnaSet" inManagedObjectContext:self.anaSetsContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSArray *sdArray = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES selector:@selector(localizedStandardCompare:)], [NSSortDescriptor sortDescriptorWithKey:@"setName" ascending:YES selector:@selector(localizedStandardCompare:)], nil];
    [request setSortDescriptors:sdArray];
    [request setEntity:entityDescription];
    
    err = nil;
    NSArray *array = [self.anaSetsContext executeFetchRequest:request error:&err];
    
    if (err != nil) {
        NSLog(@"Error fetching analyzer sets: %@", err);
    }
    
    if (array != nil)
    {
        for (NSManagedObject *anaSet in array) {
            if (![anaSet isDeleted]) {
                NSString *name = [anaSet valueForKey:@"setName"];
                NSString *group = [anaSet valueForKey:@"group"];
                NSString *keyCombo = [anaSet valueForKey:@"commandKey"];
                
                [self addAnalyzerSetMenu:name withGroup:group withKey:keyCombo representedBy:anaSet];
            }
        }
    }
}

- (NSManagedObject *)analyzerSetNamed:(NSString *)name
{
    NSManagedObject *result = nil;
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"StAnaSet" inManagedObjectContext:self.anaSetsContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"setName == %@", name];
    [request setPredicate:predicate];
    
    NSError *err = nil;
    NSArray *array = [self.anaSetsContext executeFetchRequest:request error:&err];
    
    if (err != nil) {
//        NSLog(@"Error fetching analyzer set named %@: %@", name, err);
    }
    else if (array != nil) {
        if ([array count] == 0) {
//            NSLog(@"Error fetching analyzer set named %@: zero sets found", name);
        } else if ([array count] > 1) {
//            NSLog(@"Error fetching analyzer set named %@: %lu sets found", name, [array count]);
        } else {
            result = [array objectAtIndex:0];
        }
    } else {
//        NSLog(@"Error fetching analyzer set named %@: no sets found", name);
    }
    
    return result;
}

- (void) addBlockerMenu:(NSString *)classNameString
{
    Class blockerClass = NSClassFromString(classNameString);

    NSString *subMenuName = [blockerClass blockerGroup];
    NSMenuItem *subMenuItem = [blocksMenu itemWithTitle:subMenuName];
    NSMenu *subMenu;
    
    if (subMenuItem == nil) {
        NSMenuItem *mainItem = [[[NSMenuItem alloc] init] autorelease];
        [mainItem setTitle:subMenuName];
        subMenu = [[[NSMenu alloc] initWithTitle:subMenuName] autorelease];
        [blocksMenu addItem:mainItem];
        [blocksMenu setSubmenu:subMenu forItem:mainItem];
    }
    else {
        subMenu = [subMenuItem submenu];
    }
    
    NSMenuItem *newMenuItem = [[[NSMenuItem alloc] initWithTitle:[blockerClass blockerName] action:@selector(makeNewBlocker:) keyEquivalent:@""] autorelease];
    [newMenuItem setRepresentedObject:blockerClass];
    [subMenu addItem:newMenuItem];
}

- (void) addAnalyzerSetMenu:(NSString *)name withGroup:(NSString *)group withKey:(NSString *)commandKey representedBy:(NSManagedObject *)representedObject
{
    NSMenuItem *subMenuItem = nil;
    NSMenu *subMenu = setsMenu;
    
    if (name == nil) {
        NSLog( @"addAnalyzerSetMenu: Name can not be nil" );
        return;
    }
    
    if (group == nil) {
        group = @"";
    }
    
    if (commandKey == nil) {
        commandKey = @"";
    }
    
    if (![group isEqualToString:@""]) {
        subMenuItem = [setsMenu itemWithTitle:group];
        if (subMenuItem == nil) {
            NSMenuItem *mainItem = [[[NSMenuItem alloc] init] autorelease];
            [mainItem setTitle:group];
            subMenu = [[[NSMenu alloc] initWithTitle:group] autorelease];
            [setsMenu addItem:mainItem];
            [setsMenu setSubmenu:subMenu forItem:mainItem];
        }
        else {
            subMenu = [subMenuItem submenu];
        }
    }
    
    NSMenuItem *newMenuItem = [[[NSMenuItem alloc] initWithTitle:name action:@selector(applyAnalyzerSet:) keyEquivalent:commandKey] autorelease];
    [newMenuItem setRepresentedObject:representedObject];
    [subMenu addItem:newMenuItem];
}

- (IBAction)makeAnalyzerSet:(id)sender
{
    StStream *theStream = sender;

    if(self.analyzerSetGetInformation == nil) {
        self.analyzerSetGetInformation = [[[NewAnalyzerSetWindowController alloc] initWithWindowNibName:@"NewAnalyzerSetDialog"] autorelease];
    }
    
    NSString *name;
    int j=1;
    name = [NSString stringWithFormat:@"Set #%d", j++];
    while ([self analyzerSetNamed:name] != nil) {
        name = [NSString stringWithFormat:@"Set #%d", j++];
    }

    NSWindow *nasd = [self.analyzerSetGetInformation window];
    [self.analyzerSetGetInformation.nameField setStringValue:name];
    [self.analyzerSetGetInformation.groupField setStringValue:@""];
    [self.analyzerSetGetInformation.keyComboField setStringValue:@""];
    NSInteger result = [NSApp runModalForWindow: nasd];
    [nasd orderOut: self];

    if (result == YES) {
        NSString *newName = [self.analyzerSetGetInformation.nameField stringValue];
        NSManagedObject *anaSet = [self analyzerSetNamed:newName];

        if (anaSet != nil) {
            /* Ask user if they want to replace existing set */
            NSAlert *replaceAlert = [NSAlert alertWithMessageText:@"Duplicate Analyzer Set Name" defaultButton:@"Cancel" alternateButton:@"OK" otherButton:nil informativeTextWithFormat:@"An analyzer set named “%@” already exists. Do you want to replace it?", newName];
            
            NSInteger result = [replaceAlert runModal];
            
            if (result == NSAlertSecondButtonReturn) {
                [[anaSet mutableOrderedSetValueForKey:@"analyzers"] removeAllObjects];
            } else {
                return;
            }
        } else {
            anaSet = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaSet" inManagedObjectContext:self.anaSetsContext];
        }
        
        [anaSet setValue:[self.analyzerSetGetInformation.nameField stringValue] forKey:@"setName"];
        [anaSet setValue:[self.analyzerSetGetInformation.groupField stringValue] forKey:@"group"];
        [anaSet setValue:[self.analyzerSetGetInformation.keyComboField stringValue] forKey:@"commandKey"];
        NSMutableOrderedSet *analyzers = [anaSet mutableOrderedSetValueForKey:@"analyzers"];
        Analyzation *analyzation = [Analyzation sharedInstance];
        
        for (StAnalyzer *sourceAna in theStream.analyzers) {
            StAnalyzer *destAna = [NSEntityDescription insertNewObjectForEntityForName:@"StAnalyzer" inManagedObjectContext:self.anaSetsContext];
            destAna.analyzerHeight = sourceAna.analyzerHeight;
            destAna.paneExpanded = sourceAna.paneExpanded;
            destAna.analyzerKind = sourceAna.analyzerKind;
            destAna.currentEditorView = sourceAna.currentEditorView;
            destAna.readOnly = sourceAna.readOnly;
            destAna.resultingUTI = sourceAna.resultingUTI;
            destAna.sourceUTI = sourceAna.sourceUTI;

            NSDictionary *copyDictionary = [sourceAna.optionsDictionary valueForKey:sourceAna.analyzerKind];
            
            if (copyDictionary != nil) {
                NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:copyDictionary];
                [destAna.optionsDictionary setObject:[NSKeyedUnarchiver unarchiveObjectWithData:archivedData] forKey:sourceAna.analyzerKind];
            }
            
            NSString *anaKey = [[analyzation analyzerClassforName:sourceAna.currentEditorView] analyzerKey];
            copyDictionary = [sourceAna.optionsDictionary valueForKey:anaKey];
            
            if (copyDictionary != nil) {
                NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:copyDictionary];
                [destAna.optionsDictionary setObject:[NSKeyedUnarchiver unarchiveObjectWithData:archivedData] forKey:anaKey];
            }

            [analyzers addObject:destAna];
        }

        [self addAnalyzerSetMenu:[self.analyzerSetGetInformation.nameField stringValue] withGroup:[self.analyzerSetGetInformation.groupField stringValue] withKey:[self.analyzerSetGetInformation.keyComboField stringValue] representedBy:anaSet];
    }
}

- (IBAction)manageAnalyzerSets:(id)sender
{
#pragma unused (sender)
    if (self.manageAnalyzerWindowController == nil) {
        self.manageAnalyzerWindowController = [[[AnalyzerSetWindowController alloc] initWithWindowNibName:@"AnalyzerSetWindowController"] autorelease];
        self.manageAnalyzerWindowController.managedObjectContext = self.anaSetsContext;
        [self.manageAnalyzerWindowController loadWindow];
    }
    
    [self.manageAnalyzerWindowController showWindow:self];
}

- (NSURL *)getURLFromUser
{
    NSURL *result = nil;
    
    if(self.urlWindowController == nil) {
        self.urlWindowController = [[[GetNetURLWindowController alloc] initWithWindowNibName:@"GetNetURLWindowController"] autorelease];
    }

    NSWindow *nasd = [self.urlWindowController window];
    NSUserDefaults *ud =  [NSUserDefaults standardUserDefaults];
    NSArray *previousURLs = [ud arrayForKey:@"previousURLList"];
    
    if (previousURLs == nil) {
        previousURLs = [NSArray array];
    }

    [self.urlWindowController.urlPopupButton removeAllItems];
    [self.urlWindowController.urlPopupButton addItemsWithTitles:previousURLs];
    
    NSInteger reply = [NSApp runModalForWindow: nasd];
    [nasd orderOut: self];
    
    if (reply == YES) {
        NSString *urlString = [self.urlWindowController.urlTextField stringValue];
        result = [[[NSURL alloc] initWithString:urlString] autorelease];
        
        if ([previousURLs count] > 15) {
            previousURLs = [previousURLs subarrayWithRange:NSMakeRange(0, [previousURLs count]-2)];
        }
        
        if (![previousURLs containsObject:urlString]) {
            previousURLs = [previousURLs arrayByAddingObject:urlString];
        }
        
        [ud setObject:previousURLs forKey:@"previousURLList"];
        [ud synchronize];
    }
    
    return result;
}

- (void)dealloc
{
    self.anaSetsContext = nil;
    self.analyzerSetGetInformation = nil;
    self.manageAnalyzerWindowController = nil;
    self.urlWindowController = nil;

    [super dealloc];
}

@end

@implementation NSError (ExtendedErrorCategory)

- (NSString *)debugDescription
{
    //  Log the entirety of domain, code, userInfo for debugging.
    //  Operates recursively on underlying errors
    
    NSMutableDictionary *dictionaryRep = [[self userInfo] mutableCopy];
    
    [dictionaryRep setObject:[self domain] forKey:@"domain"];
    [dictionaryRep setObject:[NSNumber numberWithInteger:[self code]] forKey:@"code"];
    
    NSError *underlyingError = [[self userInfo] objectForKey:NSUnderlyingErrorKey];
    NSString *underlyingErrorDescription = [underlyingError debugDescription];
    if (underlyingErrorDescription)
    {
        [dictionaryRep setObject:underlyingErrorDescription forKey:NSUnderlyingErrorKey];
    }
    
    // Finish up
    NSString *result = [dictionaryRep description];
    [dictionaryRep release];
    return result;
}

@end