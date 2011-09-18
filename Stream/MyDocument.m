//
//  MyDocument.m
//  Stream
//
//  Created by tim lindner on 7/23/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "MyDocument.h"
#import "StStream.h"
#import "StAnaylizer.h"
#import "AppDelegate.h"

@implementation MyDocument
@synthesize tableColumn;

@synthesize streamListView;
@synthesize zoomCursor;

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
//    NSPersistentStoreCoordinator *psc = [[self managedObjectContext] persistentStoreCoordinator];
//    NSManagedObjectContext *newMOC = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
//    [newMOC setPersistentStoreCoordinator:psc];
//    [self setManagedObjectContext:newMOC];
    self.zoomCursor = [[[NSCursor alloc] initWithImage:[NSImage imageNamed:@"Zoom"] hotSpot:NSMakePoint(5.0, 5.0)] autorelease];
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (IBAction)add:(id)sender
{
    NSOpenPanel *myOpenPanel = [NSOpenPanel openPanel];
    [myOpenPanel setAllowsMultipleSelection:YES];
    
    void *sheetCompleation = ^(NSInteger result)
    {
        if( result == NSFileHandlingPanelOKButton )
        {
            for (NSURL *aURL in [myOpenPanel URLs])
            {
                NSManagedObject *newObject = [[streamTreeControler newObject] autorelease];
                
                /* Setup main object */
                [newObject setValue:aURL forKey:@"sourceURL"];
                [newObject setValue:[aURL lastPathComponent] forKey:@"displayName"];
                NSDate *modDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[aURL path] error:nil] fileModificationDate];
                [newObject setValue:modDate forKey:@"modificationDateofURL"];
                [newObject setValue:[[[NSData alloc] initWithContentsOfURL:aURL] autorelease] forKey:@"bytesCache"];
                
                CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[aURL pathExtension], NULL);
                [newObject setValue:(NSString *)fileUTI forKey:@"sourceUTI"];
                CFRelease( fileUTI );
                
                /* Setup first anaylizer */
                NSMutableOrderedSet *theSet = [newObject mutableOrderedSetValueForKey:@"anaylizers"];
                
                StAnaylizer *newAnaylizer = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaylizer" inManagedObjectContext:[self managedObjectContext]];
                newAnaylizer.anaylizerKind = @"base anaylizer";
                [theSet addObject:newAnaylizer];
                
                [streamTreeControler addObject:newObject];
            }
        }
    };
    
    [myOpenPanel beginSheetModalForWindow:[self windowForSheet] completionHandler: sheetCompleation];
}

- (IBAction)removeAnaylizer:(id)sender
{
    NSAlert *myAlert = [NSAlert alertWithMessageText:@"Delete Anayliser" defaultButton:@"Cancel" alternateButton:@"OK" otherButton:@"" informativeTextWithFormat:@"Are you sure you want to delete this anayliser?"];
    
    [myAlert setAlertStyle:NSCriticalAlertStyle];
    [myAlert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(deleteAnayliserAlertDidEnd:returnCode:contextInfo:) contextInfo:sender];
}

- (void) deleteAnayliserAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 0)
    {
        StAnaylizer *anaylizer = contextInfo;
        StStream *parentStream = [anaylizer parentStream];
        
        NSDictionary *parameter = [NSDictionary dictionaryWithObjectsAndKeys:anaylizer.parentStream, @"parentStream", anaylizer, @"anaylizer", nil];
        
        NSMutableOrderedSet *os = [parentStream mutableOrderedSetValueForKey:@"anaylizers"];
        [os removeObject:anaylizer];

        /* At the end of the run loop the UI will unhook itself from this object */
        
        /* After dealy, the managed object and it's decendents will be deleted */
        [self performSelector:@selector(flushAnaylizer:) withObject:parameter afterDelay:0.0];
    }
}

- (void) flushAnaylizer:(NSDictionary *)parameter
{
    StStream *parentStream = [parameter objectForKey:@"parentStream"];
    StAnaylizer *anaylizer = [parameter objectForKey:@"anaylizer"];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(parentStream == %@) AND (anaylizerKind == %@)", parentStream, anaylizer.anaylizerKind ];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *resultBlockArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( error == nil )
    {
        NSMutableSet *ms = [parentStream mutableSetValueForKey:@"blocks"];
        [ms minusSet:[NSSet setWithArray:resultBlockArray]];
    }
    else
        NSLog( @"Deleting blocks in a stream: fetch returned error: %@", error );
    
    [[self managedObjectContext] deleteObject:anaylizer];
}

- (IBAction)makeNewBlocker:(id)sender
{
    Class <BlockerProtocol> class = [sender representedObject];
    
    NSArray *selectedObjects = [streamTreeControler selectedObjects];
    
    if( [selectedObjects count] > 0 )
    {
        StStream *selectedStream = [selectedObjects objectAtIndex:0];
        
        /* Setup anaylizer */
        NSMutableOrderedSet *theSet = [selectedStream mutableOrderedSetValueForKey:@"anaylizers"];
        
        StAnaylizer *newAnaylizer = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaylizer" inManagedObjectContext:[self managedObjectContext]];
        newAnaylizer.anaylizerKind = [class anaylizerKey];
        newAnaylizer.currentEditorView = @"Blocker View";
        [theSet addObject:newAnaylizer];
    }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSMutableOrderedSet *oSet = [streamTreeControler valueForKeyPath:@"selection.anaylizers"];
    StAnaylizer *ana = [oSet objectAtIndex:row];
    float value = ana.computedAnaylizerHeight;
    return value;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
    return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
    if( subview == streamListView )
        return NO;
    else
        return YES;
}

- (void)dealloc
{
    self.zoomCursor = nil;
    [super dealloc];
}
@end
