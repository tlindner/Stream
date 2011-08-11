//
//  MyDocument.m
//  Stream
//
//  Created by tim lindner on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyDocument.h"


@implementation MyDocument

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
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (IBAction)add:(id)sender
{
    NSOpenPanel *myOpenPanel = [NSOpenPanel openPanel];
    [myOpenPanel setAllowsMultipleSelection:YES];
    
    void *sheetCompleation = ^(NSInteger result) {
        if( result == NSFileHandlingPanelOKButton ) {
            for (NSURL *aURL in [myOpenPanel URLs]) {
 
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
                
                 NSManagedObject *newAnaylizer = [NSEntityDescription insertNewObjectForEntityForName:@"StAnaylizer" inManagedObjectContext:[self managedObjectContext]];
                [newAnaylizer setValue:@"base anaylizer" forKey:@"anaylizerKind"];
                [theSet addObject:newAnaylizer];
             
                [streamTreeControler addObject:newObject];
            }
        }
     };

    [myOpenPanel beginSheetModalForWindow:[self windowForSheet] completionHandler: sheetCompleation];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSMutableOrderedSet *oSet = [streamTreeControler valueForKeyPath:@"selection.anaylizers"];
    NSManagedObject *mo = [oSet objectAtIndex:row];
    float value = [[mo valueForKey:@"anaylizerHeight"] floatValue];
    return value;
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
    return NO;
}
@end
