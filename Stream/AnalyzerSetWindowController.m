//
//  AnalyzerSetWindowController.m
//  Stream
//
//  Created by tim lindner on 5/18/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "AnalyzerSetWindowController.h"
#import "StAnalyzer.h"
#import "AppDelegate.h"

float heightForStringDrawing2(NSString *myString, NSFont *myFont, float myWidth);

@interface AnalyzerSetWindowController ()

@end

@implementation AnalyzerSetWindowController

@synthesize managedObjectContext;
@synthesize analyzerTableView;
@synthesize analyzerArrayController;
@synthesize analyzerSetsController;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [analyzerTableView sizeLastColumnToFit];
    [analyzerTableView setRowSizeStyle:NSTableViewRowSizeStyleCustom];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    StAnalyzer *ana = [[analyzerArrayController arrangedObjects] objectAtIndex:row];
    CGFloat width = [[[tableView tableColumns] objectAtIndex:0] width];
    NSFont *font = [NSFont userFontOfSize:13.0];
    return heightForStringDrawing2(ana.descriptiveText, font, width) + 13;
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
#pragma unused (aNotification)
    NSUInteger count = [[analyzerArrayController arrangedObjects] count];
    [analyzerTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
}


- (IBAction)deleteAnalyzerSet:(id)sender {
    [analyzerSetsController remove:sender];
    [[NSApp delegate] reloadAllAnalyzerSetMenuItems];
}

- (IBAction)nameFieldAction:(id)sender {
#pragma unused (sender)
    [[NSApp delegate] reloadAllAnalyzerSetMenuItems];
}

@end

float heightForStringDrawing2(NSString *myString, NSFont *myFont, float myWidth)
{
    NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString:myString] autorelease];
    NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize: NSMakeSize(myWidth, FLT_MAX)] autorelease];
    NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease]; 
    NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    [textStorage addAttribute:NSFontAttributeName value:myFont range:NSMakeRange(0, [textStorage length])];
    [textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:0.0];
    
    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager usedRectForTextContainer:textContainer].size.height;
}
