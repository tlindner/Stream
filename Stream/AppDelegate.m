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
#import "StAnaylizer.h"
#import "Blockers.h"
#import "NSFileManager+DirectoryLocations.h"
#import "NewAnaylizerSetWindowController.h"
#import "AnaylizerSetWindowController.h"

@implementation AppDelegate

@synthesize blocksMenu;
@synthesize setsMenu;
@synthesize anaSetsContext;
@synthesize anaylizerSetGetInformation;
@synthesize manageAnaylizerWindowController;

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

    for (NSString *blockerClassString in [Blockers sharedInstance].classList) {
        [self addBlockerMenu:blockerClassString];
    }
    
    /* Initialize anaylizer sets */
    NSString *appSupportDir = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSURL *anaSetsURL = [[[NSURL alloc] initFileURLWithPath:[appSupportDir stringByAppendingPathComponent:@"Anaylizer Sets.binary"]] autorelease];
    NSBundle *myBundle = [NSBundle mainBundle];
    NSURL *mom = [myBundle URLForResource:@"MyDocument" withExtension:@"momd"];
    NSManagedObjectModel *om = [[[NSManagedObjectModel alloc] initWithContentsOfURL:mom] autorelease];
    NSPersistentStoreCoordinator *psc = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:om] autorelease];
    NSError *err = nil;
    NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:anaSetsURL options:nil error:&err];
            
    if (err != nil) {
        NSLog(@"error creating/loading anaylizer sets document: %@", err);
    }
    
    err = nil;
    
    [ps loadMetadata:&err];
    
    if (err != nil) {
        NSLog(@"error loading meta data for anaylizer sets document: %@", err);
    }
    
    self.anaSetsContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
    [self.anaSetsContext setPersistentStoreCoordinator:psc];
    
    [self reloadAllAnaylizerSetMenuItems];
}

- (void)reloadAllAnaylizerSetMenuItems
{
    while ([setsMenu numberOfItems] > 3) {
        [setsMenu removeItemAtIndex:3];
    }
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"StAnaSet" inManagedObjectContext:self.anaSetsContext];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSArray *sdArray = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"group" ascending:YES selector:@selector(localizedStandardCompare:)], [NSSortDescriptor sortDescriptorWithKey:@"setName" ascending:YES selector:@selector(localizedStandardCompare:)], nil];
    [request setSortDescriptors:sdArray];
    [request setEntity:entityDescription];
    
    NSError *err = nil;
    NSArray *array = [self.anaSetsContext executeFetchRequest:request error:&err];
    
    if (err != nil) {
        NSLog(@"Error fetching anaylyizer sets: %@", err);
    }
    
    if (array != nil)
    {
        for (NSManagedObject *anaSet in array) {
            NSString *name = [anaSet valueForKey:@"setName"];
            NSString *group = [anaSet valueForKey:@"group"];
            NSString *keyCombo = [anaSet valueForKey:@"commandKey"];
            
            [self addAnaylizerSetMenu:name withGroup:group withKey:keyCombo representedBy:anaSet];
        }
    }
}

- (NSManagedObject *)anaylizerSetNamed:(NSString *)name
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
        NSLog(@"Error fetching anaylyizer set named %@: %@", name, err);
    }
    else if (array != nil) {
        if ([array count] == 0) {
            NSLog(@"Error fetching anaylyizer set named %@: zero sets found", name);
        } else if ([array count] > 1) {
            NSLog(@"Error fetching anaylyizer set named %@: %lu sets found", name, [array count]);
        } else {
            result = [array objectAtIndex:0];
        }
    } else {
        NSLog(@"Error fetching anaylyizer set named %@: no sets found", name);
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

- (void) addAnaylizerSetMenu:(NSString *)name withGroup:(NSString *)group withKey:(NSString *)commandKey representedBy:(NSManagedObject *)representedObject
{
    NSMenuItem *subMenuItem = nil;
    NSMenu *subMenu = setsMenu;
    
    if (name == nil) {
        NSLog( @"addAnaylizerSetMenu: Name can not be nil" );
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
    
    NSMenuItem *newMenuItem = [[[NSMenuItem alloc] initWithTitle:name action:@selector(applyAnaylizerSet:) keyEquivalent:commandKey] autorelease];
    [newMenuItem setRepresentedObject:representedObject];
    [subMenu addItem:newMenuItem];
}

- (IBAction)makeAnaylizerSet:(id)sender
{
    StStream *theStream = sender;

    if(self.anaylizerSetGetInformation == nil) {
        self.anaylizerSetGetInformation = [[[NewAnaylizerSetWindowController alloc] initWithWindowNibName:@"NewAnaylizerSetDialog"] autorelease];
    }
    
    [self.anaylizerSetGetInformation.nameField setStringValue:@""];
    [self.anaylizerSetGetInformation.groupField setStringValue:@""];
    [self.anaylizerSetGetInformation.keyComboField setStringValue:@""];
    NSWindow *nasd = [self.anaylizerSetGetInformation window];
    NSInteger result = [NSApp runModalForWindow: nasd];
    [nasd orderOut: self];

    if (result == YES) {
        NSString *newName = [self.anaylizerSetGetInformation.nameField stringValue];
        NSManagedObject *anaSet = [self anaylizerSetNamed:newName];

        if (anaSet != nil) {
            /* Ask user if they want to replace existing set */
            NSAlert *replaceAlert = [NSAlert alertWithMessageText:@"Duplicate Anayzer Set Name" defaultButton:@"Cancel" alternateButton:@"OK" otherButton:nil informativeTextWithFormat:@"An anaylizer set named “%@” already exists. Do you want to replace it?", newName];
            
            NSInteger result = [replaceAlert runModal];
            
            if (result == NSAlertSecondButtonReturn) {
                [[anaSet mutableOrderedSetValueForKey:@"anaylizers"] removeAllObjects];
            } else {
                return;
            }
        } else {
            anaSet = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaSet" inManagedObjectContext:self.anaSetsContext];
        }
        
        [anaSet setValue:[self.anaylizerSetGetInformation.nameField stringValue] forKey:@"setName"];
        [anaSet setValue:[self.anaylizerSetGetInformation.groupField stringValue] forKey:@"group"];
        [anaSet setValue:[self.anaylizerSetGetInformation.keyComboField stringValue] forKey:@"commandKey"];
        NSMutableOrderedSet *anaylizers = [anaSet mutableOrderedSetValueForKey:@"anaylizers"];
        Analyzation *analyzation = [Analyzation sharedInstance];
        
        for (StAnaylizer *sourceAna in theStream.anaylizers) {
            StAnaylizer *destAna = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaylizer" inManagedObjectContext:self.anaSetsContext];
            destAna.anaylizerHeight = sourceAna.anaylizerHeight;
            destAna.paneExpanded = sourceAna.paneExpanded;
            destAna.anaylizerKind = sourceAna.anaylizerKind;
            destAna.currentEditorView = sourceAna.currentEditorView;
            destAna.readOnly = sourceAna.readOnly;
            destAna.resultingUTI = sourceAna.resultingUTI;
            destAna.sourceUTI = sourceAna.sourceUTI;

            NSDictionary *copyDictionary = [sourceAna.optionsDictionary valueForKey:sourceAna.anaylizerKind];
            
            if (copyDictionary != nil) {
                NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:copyDictionary];
                [destAna.optionsDictionary setObject:[NSKeyedUnarchiver unarchiveObjectWithData:archivedData] forKey:sourceAna.anaylizerKind];
            }
            
            NSString *anaKey = [[analyzation anaylizerClassforName:sourceAna.currentEditorView] anaylizerKey];
            copyDictionary = [sourceAna.optionsDictionary valueForKey:anaKey];
            
            if (copyDictionary != nil) {
                NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:copyDictionary];
                [destAna.optionsDictionary setObject:[NSKeyedUnarchiver unarchiveObjectWithData:archivedData] forKey:anaKey];
            }

            [anaylizers addObject:destAna];
        }

        [self addAnaylizerSetMenu:[self.anaylizerSetGetInformation.nameField stringValue] withGroup:[self.anaylizerSetGetInformation.groupField stringValue] withKey:[self.anaylizerSetGetInformation.keyComboField stringValue] representedBy:anaSet];
    }
}

- (IBAction)manageAnaylizerSets:(id)sender
{
#pragma unused (sender)
    if (self.manageAnaylizerWindowController == nil) {
        self.manageAnaylizerWindowController = [[[AnaylizerSetWindowController alloc] initWithWindowNibName:@"AnaylizerSetWindowController"] autorelease];
        self.manageAnaylizerWindowController.managedObjectContext = self.anaSetsContext;
        [self.manageAnaylizerWindowController loadWindow];
    }
    
    [self.manageAnaylizerWindowController showWindow:self];
}

@end

@implementation NSError (ExtendedErrorCategory)

- (NSString *)debugDescription
{
    //  Log the entirety of domain, code, userInfo for debugging.
    //  Operates recursively on underlying errors
    
    NSMutableDictionary *dictionaryRep = [[self userInfo] mutableCopy];
    
    [dictionaryRep setObject:[self domain]
                      forKey:@"domain"];
    [dictionaryRep setObject:[NSNumber numberWithInteger:[self code]]
                      forKey:@"code"];
    
    NSError *underlyingError = [[self userInfo] objectForKey:NSUnderlyingErrorKey];
    NSString *underlyingErrorDescription = [underlyingError debugDescription];
    if (underlyingErrorDescription)
    {
        [dictionaryRep setObject:underlyingErrorDescription
                          forKey:NSUnderlyingErrorKey];
    }
    
    // Finish up
    NSString *result = [dictionaryRep description];
    [dictionaryRep release];
    return result;
}

@end