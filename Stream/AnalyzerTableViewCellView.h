//
//  AnalyzerTableViewCellView.h
//  Stream
//
//  Created by tim lindner on 7/30/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "ColorGradientView.h"

@interface AnalyzerTableViewCellView : NSTableCellView
{
    IBOutlet ColorGradientView *_cgv;
    IBOutlet NSView *_customView;
    IBOutlet NSView *dragThumbView;
    IBOutlet NSButton *tlDisclosure;
    NSViewController *editorController;
    NSSize dragOffsetIntoGrowBox;
    BOOL ignoreEvent;
    float rowHeight;
}

@property(nonatomic, retain) NSViewController *editorController;

- (IBAction)removeAnalyzer:(id)sender;

@end
