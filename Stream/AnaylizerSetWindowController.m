//
//  AnaylizerSetWindowController.m
//  Stream
//
//  Created by tim lindner on 5/18/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "AnaylizerSetWindowController.h"
#import "StAnaylizer.h"

float heightForStringDrawing2(NSString *myString, NSFont *myFont, float myWidth);

@interface AnaylizerSetWindowController ()

@end

@implementation AnaylizerSetWindowController

@synthesize managedObjectContext;
@synthesize anaylizerTableView;
@synthesize anaylizerArrayController;

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
    
    [anaylizerTableView sizeLastColumnToFit];
    [anaylizerTableView setRowSizeStyle:NSTableViewRowSizeStyleCustom];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    StAnaylizer *ana = [[anaylizerArrayController arrangedObjects] objectAtIndex:row];
    CGFloat width = [[[tableView tableColumns] objectAtIndex:0] width];
    NSFont *font = [NSFont userFontOfSize:13.0];
    return heightForStringDrawing2(ana.descriptiveText, font, width) + 13;
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
#pragma unused (aNotification)
    NSUInteger count = [[anaylizerArrayController arrangedObjects] count];
    [anaylizerTableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
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
