//
//  MyDocument.m
//  Stream
//
//  Created by tim lindner on 7/23/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "MyDocument.h"
#import "StStream.h"
#import "StBlock.h"
#import "StAnaylizer.h"
#import "AppDelegate.h"
#import "AnaylizerListViewItem.h"
#import "Blockers.h"
#import "StreamsPicturesPopoverViewController.h"

@implementation MyDocument

@synthesize documentWindow;
@synthesize streamTreeControler;
@synthesize observingStream;
@synthesize streamListView;
@synthesize zoomCursor;
@synthesize listView;
@synthesize leftSplitView;
@synthesize imageButton;
@synthesize pictureURLs;
@synthesize outlineView;
@synthesize imagePopoverViewController;
@synthesize imagePopoverNib;

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
    [outlineView setFocusRingType:NSFocusRingTypeNone];
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
                
                if (self.pictureURLs == nil) {
                    self.pictureURLs = [[[NSMutableArray alloc] init] autorelease];
                }
                
                [self.pictureURLs removeAllObjects];
                StStream *findParentURLStream = observingStream;
                id url = [findParentURLStream sourceURL];

                while (url == nil) {
                    findParentURLStream = findParentURLStream.parentStream;
                    url = [findParentURLStream sourceURL];
                }
                
                if ([url isFileURL]) {
                    BOOL foundTxt = NO;
                    NSFileManager *fm = [NSFileManager defaultManager];
                    NSString *baseFilenameString = [[url URLByDeletingPathExtension] lastPathComponent];
                    NSURL *baseFolder = [url URLByDeletingLastPathComponent];
                    NSArray *folderContents = [fm contentsOfDirectoryAtURL:baseFolder includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
                    
                    if (folderContents != nil && [folderContents count] > 0) {
                        for (NSURL *aFile in folderContents) {
                            if ([[[aFile URLByDeletingPathExtension] lastPathComponent] hasPrefix:baseFilenameString]) {
                                if (![[aFile lastPathComponent] isEqualToString:[url lastPathComponent]]) {
                                    [self.pictureURLs addObject:aFile];
                                    
                                    if ([[[aFile pathExtension] lowercaseString] isEqualToString:@"txt"]) {
                                        foundTxt = YES;
                                    }
                                }
                            }
                        }
                    }
                    
                    if (foundTxt == NO) {
                        /* Create URL pointing to a text file that doesn't exist. */
                        [self.pictureURLs addObject:[baseFolder URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", baseFilenameString]]];
                    }
                    
                    if ([self.pictureURLs count] > 0) {
                        NSImage *image = [[[NSImage alloc] initByReferencingURL:[self.pictureURLs objectAtIndex:0]] autorelease];
                        [imageButton setImage:image];
                        [imageButton setEnabled:YES];
                    }
                }
                else {
                    NSImage *image = [NSImage imageNamed:@"ImageNotWorking"];
                    [imageButton setImage:image];
                    [imageButton setEnabled:NO];
                }
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

//+ (BOOL)autosavesInPlace
//{
//    return YES;
//}

- (IBAction)add:(id)sender
{
    #pragma unused(sender)
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

- (IBAction)addURL:(id)sender
{
#pragma unused (sender)
    NSURL *url = [[NSApp delegate] getURLFromUser];
    
    if (url != nil) {
        [self addStreamFromURL:url];
    }
}

- (void) addStreamFromURL:(NSURL *)aURL
{
    NSManagedObject *newObject = [[streamTreeControler newObject] autorelease];
    
    /* Setup main object */
    [newObject setValue:aURL forKey:@"sourceURL"];
    [newObject setValue:[aURL lastPathComponent] forKey:@"displayName"];
    NSDate *modDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[aURL path] error:nil] fileModificationDate];
    [newObject setValue:modDate forKey:@"modificationDateofURL"];
//    [newObject setValue:[[[NSData alloc] initWithContentsOfURL:aURL] autorelease] forKey:@"bytesCache"];
    
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
            name = [theBlock name];
            
            if( ![[name class] isSubclassOfClass:[NSString class]] ) {
                name = [theBlock source];
                
                if( ![[name class] isSubclassOfClass:[NSString class]] ) {
                    name = [theBlock description];
                }
            }
        }
    }

//    theBlock.parentStream = theParent;
    [theParent addChildStreamsObject:(StStream *)newObject];
    [newObject setValue:name forKey:@"displayName"];
    [newObject setValue:[theBlock resultingUTI] forKey:@"sourceUTI"];
    [newObject setValue:theBlock forKey:@"sourceBlock"];
    
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
    #pragma unused(sender)
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
    else if ([menuItem action] == @selector(addURL:)) {
        return YES;
    }
    else if ([menuItem action] == @selector(exportBlocks:)) {
        return NO;
    }
    else if ([menuItem action] == @selector(applyAnaylizerSet:)) {
        NSArray *selectedObjects = [streamTreeControler selectedObjects];
        
        if ([selectedObjects count] > 0) {
            return YES;
        }
    }
    else if ([[menuItem representedObject] respondsToSelector:@selector(anaylizerKey)]) {
        NSArray *selectedObjects = [streamTreeControler selectedObjects];
        
        if ([selectedObjects count] > 0) {
            StStream *selectedStream = [selectedObjects objectAtIndex:0];
            NSOrderedSet *anaylizers = [selectedStream anaylizers];
            Class menuAnaylizerClass = menuItem.representedObject;
            for (StAnaylizer *theAna in anaylizers) {
                if ([theAna.anaylizerKind isEqualToString:[menuAnaylizerClass blockerKey]]) {
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
    #pragma unused(alert)
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
        
        for (StBlock *aBlock in resultBlockArray) {
            [self.managedObjectContext deleteObject:aBlock];
        }
        
        parentStream.topLevelBlocks = nil;
    }
    else
        NSLog( @"Deleting blocks in a stream: fetch returned error: %@", error );
    
    [[self managedObjectContext] deleteObject:anaylizer];
}

- (IBAction)makeNewBlocker:(id)sender
{
    NSUInteger flags = ([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask);
    BOOL isOptionPressed = (0 != (flags & NSAlternateKeyMask));
    
    Class class = [sender representedObject];
    
    NSArray *selectedObjects = [streamTreeControler selectedObjects];
    
    if( [selectedObjects count] > 0 )
    {
        StStream *selectedStream = [selectedObjects objectAtIndex:0];
        
        /* Setup anaylizer */
        NSMutableOrderedSet *theSet = [selectedStream mutableOrderedSetValueForKey:@"anaylizers"];
        
        StAnaylizer *newAnaylizer = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaylizer" inManagedObjectContext:[self managedObjectContext]];
        newAnaylizer.anaylizerKind = [class blockerKey];
        newAnaylizer.currentEditorView = @"Blocker View";
        
        if (isOptionPressed) {
            newAnaylizer.paneExpanded = NO;
        }
        
        Class blockerClass = NSClassFromString([newAnaylizer valueForKey:@"anaylizerKind"]);
         
        if (blockerClass != nil )
        {
            [selectedStream willChangeValueForKey:@"blocks"];
            [[[selectedStream anaylizers] array] makeObjectsPerformSelector:@selector(suspendObservations)];
            [newAnaylizer addSubOptionsDictionary:[blockerClass blockerKey] withDictionary:[blockerClass defaultOptions]];
            Blockers *blocker = [[blockerClass alloc] init];
            newAnaylizer.errorString = [blocker makeBlocks:selectedStream withAnaylizer:newAnaylizer];
            [blocker release];
            [[[selectedStream anaylizers] array] makeObjectsPerformSelector:@selector(resumeObservations)];
            [selectedStream didChangeValueForKey:@"blocks"];
        }
        else
            NSLog( @"Could not create class: %@", [newAnaylizer valueForKey:@"anaylizerKind"] );

        [theSet addObject:newAnaylizer];
        
        [[[self managedObjectContext] undoManager] setActionName:[NSString stringWithFormat:@"Add Blocker “%@”", newAnaylizer.anaylizerKind]];
    }
}
    
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
#pragma unused (alert, returnCode, contextInfo)    
}

- (void)doExportBlocks:(NSArray *)objs
{
    NSURL *url = [objs objectAtIndex:0];
    NSArray *selectedObjects = [objs objectAtIndex:1];
    NSError *err = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = [fm createFileAtPath:[url path] contents:nil attributes:nil];
    
    if (success) {
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingToURL:url error:&err];
        
        if (fh != nil && err == nil)
        {
            NSAlert *myProgressAlert = [NSAlert alertWithMessageText:@"Now writing file…" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
            NSView *enclosingView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 240, 41)] autorelease];
            NSTextField *filename = [[[NSTextField alloc] initWithFrame:NSMakeRect(-3, 24, 246, 17)] autorelease];
            [filename setDrawsBackground:NO];
            [filename setBezeled:NO];
            [filename setBordered:NO];
            [filename setEditable:NO];
            [filename setSelectable:NO];
            NSProgressIndicator *progress = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(-2, -4, 244, 20)] autorelease];
            [progress setMaxValue:[selectedObjects count]];
            [progress setIndeterminate:NO];
            [enclosingView addSubview:filename];
            [enclosingView addSubview:progress];
            [myProgressAlert setAccessoryView:enclosingView];
            [myProgressAlert layout];
            [myProgressAlert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
            [[[myProgressAlert buttons] objectAtIndex:0] setEnabled:NO];
            
            for (StBlock *aBlock in selectedObjects)
            {
                [filename setStringValue:[NSString stringWithFormat:@"Block name: %@", [aBlock name]]];
                [enclosingView display];
                [fh writeData:[aBlock resultingData]];
                [progress incrementBy:1.0];
            }
            [[[myProgressAlert buttons] objectAtIndex:0] setEnabled:YES];
            [fh closeFile];
        }
        else {
            NSAlert *myAlert = [NSAlert alertWithMessageText:@"Error writing to file" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Could not write to file: %@", err]; 
            [myAlert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
        }
    }
    else {
        NSAlert *myAlert = [NSAlert alertWithMessageText:@"Could not create file" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Could not create file: %@", url]; 
        [myAlert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
}

- (IBAction) exportBlocks:(NSArray *)selectedObjects
{
    NSSavePanel *mySavePanel = [NSSavePanel savePanel];
    
    void *sheetCompleation = ^(NSInteger result)
    {
        if( result == NSFileHandlingPanelOKButton )
        {
            NSArray *objs = [[[NSArray alloc] initWithObjects:[mySavePanel URL], selectedObjects, nil] autorelease];
            [self performSelector:@selector(doExportBlocks:) withObject:objs afterDelay:1.0];

        }
    };
    
    [mySavePanel beginSheetModalForWindow:[self windowForSheet] completionHandler: sheetCompleation];

}

//- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
//{
//    #pragma unused(aTableView)
//    return NO;
//}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
    #pragma unused(splitView)
    if( subview == leftSplitView || subview == imageButton)
        return NO;
    else
        return YES;
}

- (void)documentWindowWillClose:(NSNotification *)note
{
    #pragma unused(note)
    [streamTreeControler removeObserver:self forKeyPath:@"selectionIndexPaths" context:self];
    
    if( observingStream != nil )
    {
        [observingStream removeObserver:self forKeyPath:@"anaylizers" context:self];
        self.observingStream = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:documentWindow];
}

- (IBAction)imagePopoverClick:(id)sender
{
#pragma unused (sender)
    if (self.imagePopoverNib == nil) {
        imagePopoverViewController = nil;
        self.imagePopoverNib = [[NSNib alloc] initWithNibNamed:@"StreamsPicturesPopover" bundle:nil];
        
        if (![self.imagePopoverNib instantiateNibWithOwner:self topLevelObjects:nil]) {
            NSLog(@"Warning! Could not load image popover nib file.\n");
            return;
        }
    }
    
    imagePopoverViewController.representedObject = pictureURLs;
    [imagePopoverViewController showPopover:self];
}

- (IBAction)makeAnaylizerSet:(id)sender
{
    NSLog( @"Make Anaylizer set: %@", sender );
    NSArray *selectedObjects = [streamTreeControler selectedObjects];
    
    if( [selectedObjects count] > 0 )
    {
        [[NSApp delegate] makeAnaylizerSet:[selectedObjects objectAtIndex:0]];
    }
}

- (IBAction)applyAnaylizerSet:(id)sender
{
    NSMenuItem *menuItem = sender;
    NSManagedObject *anaSet = [menuItem representedObject];
    NSMutableOrderedSet *anaSetAnaylizers = [anaSet mutableOrderedSetValueForKey:@"Anaylizers"];
    
    NSArray *selectedObjects = [streamTreeControler selectedObjects];
    if( [selectedObjects count] > 0 )
    {
        StStream *selectedStream = [selectedObjects objectAtIndex:0];
        NSMutableOrderedSet *anaylizers = [selectedStream mutableOrderedSetValueForKey:@"Anaylizers"];
        [anaylizers removeAllObjects];
        
        for (StAnaylizer *sourceAna in anaSetAnaylizers) {
            StAnaylizer *destAna = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaylizer" inManagedObjectContext:self.managedObjectContext];
            destAna.anaylizerHeight = sourceAna.anaylizerHeight;
            destAna.paneExpanded = sourceAna.paneExpanded;
            destAna.anaylizerKind = sourceAna.anaylizerKind;
            destAna.currentEditorView = sourceAna.currentEditorView;
            destAna.readOnly = sourceAna.readOnly;
            destAna.resultingUTI = sourceAna.resultingUTI;
            destAna.sourceUTI = sourceAna.sourceUTI;

            NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:sourceAna.optionsDictionary];
            [destAna setValue:[NSKeyedUnarchiver unarchiveObjectWithData:archivedData] forKey:@"optionsDictionary"];
            
            [anaylizers addObject:destAna];
            [destAna anaylizeData];
        }
        
        [selectedStream regenerateAllBlocks];
    }

}

- (void)dealloc
{
    self.zoomCursor = nil;
    self.observingStream = nil;
    self.pictureURLs = nil;
    
    [super dealloc];
}
@end
