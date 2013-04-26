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
#import "AnaylizerListViewItem.h"

@implementation MyDocument

@synthesize documentWindow;
@synthesize streamTreeControler;
@synthesize observingStream;
@synthesize streamListView;
@synthesize zoomCursor;
@synthesize listView;

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

    [streamTreeControler addObserver:self forKeyPath:@"selectionIndexPaths" options:0 context:self];
    listView.prototypeItem = [[[AnaylizerListViewItem alloc] initWithNibName:@"AnaylizerListViewItem" bundle:nil] autorelease];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWindowWillClose:) name:NSWindowWillCloseNotification object:documentWindow];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        if ([keyPath isEqualToString:@"selectionIndexPaths"]) {
            NSArray *selectedObjects = [streamTreeControler selectedObjects];
            
            if( observingStream != nil )
            {
                [observingStream removeObserver:self forKeyPath:@"anaylizers" context:self];
                self.observingStream = nil;
            }
            
            if( [selectedObjects count] > 0 )
            {
                StStream *selectedStream = [selectedObjects objectAtIndex:0];
                NSOrderedSet *anaylizers = [[selectedStream anaylizers] reversedOrderedSet];
                listView.content = [anaylizers array];
                
                self.observingStream = selectedStream;
                [observingStream addObserver:self forKeyPath:@"anaylizers" options:0 context:self];
                 
            }
            else {
                listView.content = [NSArray array];
            }
        } else if ([keyPath isEqualToString:@"anaylizers"]) {
            NSOrderedSet *anaylizers = [[self.observingStream anaylizers] reversedOrderedSet];
            listView.content = [anaylizers array];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
                [self addStreamFromURL:aURL];
            }
        }
    };
    
    [myOpenPanel beginSheetModalForWindow:[self windowForSheet] completionHandler: sheetCompleation];
}

- (void) addStreamFromURL:(NSURL *)aURL
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
    
//    [streamTreeControler addObject:newObject];
    
    /* setup undo */
    [[[self managedObjectContext] undoManager] setActionName:[NSString stringWithFormat:@"Add Stream “%@”", [newObject valueForKey:@"displayName"]]];
}

- (void) addSubStreamFromTopLevelBlock:(StBlock *)theBlock ofParent:(StStream *)theParent
{
//    NSLog( @"Add substreamfromtoplevel block: %@, with parent: %@", theBlock, theParent );
    NSManagedObject *newObject = [[streamTreeControler newObject] autorelease];
    NSString *name = [theBlock getAttributeDatawithUIName:@"Filename"];
    
    if( ![[name class] isSubclassOfClass:[NSString class]] ) {
        name = [theBlock getAttributeDatawithUIName:@"Name"];
        
        if( ![[name class] isSubclassOfClass:[NSString class]] ) {
            name = [theBlock source];
        }
    }

//    theBlock.parentStream = theParent;
    [theParent addChildStreamsObject:(StStream *)newObject];
    [newObject setValue:name forKey:@"displayName"];
    [newObject setValue:[theBlock resultingUTI] forKey:@"sourceUTI"];
    [newObject setValue:[theBlock getData] forKey:@"bytesCache"];
  
    /* Setup first anaylizer */
    NSMutableOrderedSet *theSet = [newObject mutableOrderedSetValueForKey:@"anaylizers"];
    
    StAnaylizer *newAnaylizer = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaylizer" inManagedObjectContext:[self managedObjectContext]];
    newAnaylizer.anaylizerKind = @"base anaylizer";
    [theSet addObject:newAnaylizer];
    
//    [streamTreeControler addChild:newObject];
    
    /* setup undo */
    [[[self managedObjectContext] undoManager] setActionName:[NSString stringWithFormat:@"Add Sub-Stream “%@”", name]];
}

- (IBAction)wftSave:(id)sender
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    
    NSError *err = nil;
    
    [moc save:&err];
    
    if( err != nil )
    {
        NSLog( @"%@", err );
    }
}

- (IBAction)removeStream:(id)sender
{
    StStream *removeStream = sender;
    
    /* setup redo */
    [[[self managedObjectContext] undoManager] registerUndoWithTarget:self selector:@selector(addStreamFromURL:) object:[removeStream sourceURL]];
    [[[self managedObjectContext] undoManager] setActionName:[NSString stringWithFormat:@"Add Stream “%@”", [removeStream valueForKey:@"displayName"]]];

    NSMutableOrderedSet *orderedAnaylizers = [removeStream mutableOrderedSetValueForKey:@"anaylizers"];
    StAnaylizer *lastAna;
    
    while( (lastAna = [orderedAnaylizers lastObject]) != nil )
    {
        NSDictionary *flushDictionary;
        
        flushDictionary = [NSDictionary dictionaryWithObjectsAndKeys:removeStream, @"parentStream", lastAna, @"anaylizer", nil];
        [self flushAnaylizer:flushDictionary];
    }
    
    //[streamTreeControler removeObject:removeStream];
    [[self managedObjectContext] deleteObject:removeStream];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(makeSubStream:)) {
        return NO;
    }
    else if ([menuItem action] == @selector(add:)) {
        return YES;
    }
    else if ([[menuItem representedObject] respondsToSelector:@selector(anaylizerKey)]) {
        NSArray *selectedObjects = [streamTreeControler selectedObjects];
        
        if ([selectedObjects count] > 0) {
            StStream *selectedStream = [selectedObjects objectAtIndex:0];
            NSOrderedSet *anaylizers = [selectedStream anaylizers];
            Class <BlockerProtocol>menuAnaylizerClass = menuItem.representedObject;
            for (StAnaylizer *theAna in anaylizers) {
                if ([theAna.anaylizerKind isEqualToString:[menuAnaylizerClass anaylizerKey]]) {
                    return NO;
                }
            }
        }
        else {
            return NO;
        }
    }
    
    return [super validateMenuItem:menuItem];
}

- (IBAction)makeSubStream:(id)sender
{
    [self addSubStreamFromTopLevelBlock:sender ofParent:observingStream];
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

        Class <BlockerProtocol> blockerClass = NSClassFromString([newAnaylizer valueForKey:@"anaylizerKind"]);
        
        if (blockerClass != nil )
        {
            [blockerClass makeBlocks:selectedStream];
        }
        else
            NSLog( @"Could not create class: %@", [newAnaylizer valueForKey:@"anaylizerKind"] );

        [[[self managedObjectContext] undoManager] setActionName:[NSString stringWithFormat:@"Add Blocker “%@”", newAnaylizer.anaylizerKind]];
    }
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

- (void)documentWindowWillClose:(NSNotification *)note
{
    [streamTreeControler removeObserver:self forKeyPath:@"selectionIndexPaths" context:self];
    
    if( observingStream != nil )
    {
        [observingStream removeObserver:self forKeyPath:@"anaylizers" context:self];
        self.observingStream = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:documentWindow];
}

- (void)dealloc
{
    self.zoomCursor = nil;
    self.observingStream = nil;

    [super dealloc];
}
@end
