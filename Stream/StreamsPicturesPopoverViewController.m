//
//  StreamsPicturesPopoverViewController.m
//  Stream
//
//  Created by tim lindner on 5/18/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StreamsPicturesPopoverViewController.h"
#import "MyDocument.h"

@interface StreamsPicturesPopoverViewController ()

@end

@implementation StreamsPicturesPopoverViewController

@synthesize popover;
@synthesize popupButton;
@synthesize imageView;
@synthesize stepper;
@synthesize textFileURL;
@synthesize textScrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)clickDone:(id)sender
{
#pragma unused (sender)
    [popover performClose:self];
}

- (IBAction)showPopover:(id)sender
{
    NSMutableArray *urls = self.representedObject;
    MyDocument *doc = sender;

    [popupButton removeAllItems];
    [popupButton addItemsWithTitles:[urls valueForKey:@"lastPathComponent"]];

    int index = (int)[popupButton indexOfSelectedItem];
    NSURL *fileURL = [urls objectAtIndex:index];
    
    if ([[[fileURL pathExtension] lowercaseString] isEqualToString:@"txt"]) {
        [self saveAndLoadTextFile:fileURL];
    } else {
        [self saveAndLoadTextFile:nil];
        NSImage *image = [[[NSImage alloc] initByReferencingURL:fileURL] autorelease];
        [self.imageView setImage:image];

    }
    
    [stepper setMaxValue:[urls count] - 1];
    [stepper setIntValue:index];
     
    [popover showRelativeToRect:doc.imageButton.bounds ofView:doc.imageButton preferredEdge:NSMaxYEdge];
}

- (IBAction)changePopupButton:(id)sender
{
#pragma unused (sender)
    NSMutableArray *urls = self.representedObject;
    int index = (int)[popupButton indexOfSelectedItem];

    NSURL *fileURL = [urls objectAtIndex:index];
    
    if ([[[fileURL pathExtension] lowercaseString] isEqualToString:@"txt"]) {
        [self saveAndLoadTextFile:fileURL];
    } else {
        [self saveAndLoadTextFile:nil];
        NSImage *image = [[[NSImage alloc] initByReferencingURL:fileURL] autorelease];
        [self.imageView setImage:image];
        
    }

    [stepper setIntValue:index];
}

- (IBAction)clickStepper:(id)sender
{
    [popupButton selectItemAtIndex:[stepper intValue]];
    [self changePopupButton:sender];
}

- (void)saveAndLoadTextFile:(NSURL *)aFile
{
    /* Save existing text */
    if (self.textFileURL != nil) {
        NSError *err = nil;
        NSString *string = [[[self.textScrollView documentView] textStorage] string];
        [string writeToURL:self.textFileURL atomically:NO encoding:myEncoding error:&err];
        
        if (err != nil) {
            NSLog( @"Error writing to text file %@: %@", aFile, err );
        }
    }
    
    /* tear down existing text view */
    if (self.textScrollView != nil)
    {
        [self.textScrollView removeFromSuperview];
        self.textScrollView = nil;
        self.textFileURL = nil;
        [self.imageView setHidden:NO];
    }
    
    if (aFile != nil)
    {
        /* build up new text view */
        self.textFileURL = aFile;
        NSError *err = nil;
        NSString *string;
        string = [NSString stringWithContentsOfURL:aFile usedEncoding:&myEncoding error:&err];
        
        if (err != nil) {
            if (err.code == NSFileReadNoSuchFileError) {
                string = @"";
                myEncoding = NSUTF8StringEncoding;
            }
            else {
                NSLog( @"Error reading from text file %@: %@", aFile, err );
                return;
            }
        }
        
        [imageView setHidden:YES];
        NSRect textViewFrame = [imageView frame];
        textViewFrame = NSInsetRect(textViewFrame, 16, 16);
        self.textScrollView = [[[NSScrollView alloc] initWithFrame:textViewFrame] autorelease];
        [self.textScrollView setHasVerticalScroller:YES];
        [self.textScrollView setHasHorizontalScroller:YES];
        NSTextView *textView = [[[NSTextView alloc] initWithFrame:textViewFrame] autorelease];
        
        [self.textScrollView setDocumentView:textView];
        [textView setString:string];
        [[textView textStorage] setFont:[NSFont userFixedPitchFontOfSize:14.0]];
        
        [[self view] addSubview:self.textScrollView];
    }
}

- (void)popoverWillClose:(NSNotification *)notification
{
#pragma unused (notification)
    [self saveAndLoadTextFile:nil];
}

@end
