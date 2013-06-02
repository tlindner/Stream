//
//  AnalyzerListViewItem.h
//  Stream
//
//  Created by tim lindner on 4/21/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "SDListViewItem.h"

@class DragRegionView, ColorGradientView, TLImageWithPopover, StBlock, AnalyzerSettingPopOverViewController;

@interface AnalyzerListViewItem : SDListViewItem
{
    NSViewController  *editorController;
}

@property (nonatomic, readonly) NSArray *utiList;
@property (nonatomic, readonly) NSArray *editorList;
@property (nonatomic, readonly) NSString *acceptsUTIList;
@property (nonatomic, readonly) StBlock *selectedBlock;
@property (nonatomic, assign) StBlock *previousSelectedBlock;

@property (assign) IBOutlet DragRegionView *dragView;
@property (assign) IBOutlet NSButton *disclosureTriangle;
@property (assign) IBOutlet NSView *customView;
@property (retain) NSViewController *editorController;
@property (assign) IBOutlet ColorGradientView *colorGradientView;
@property (assign) IBOutlet NSButton *blockSettingsButton;
@property (assign) IBOutlet NSButton *analyzerSettingsButton;
@property (assign) IBOutlet NSButton *analyzerErrorButton;

@property (assign) IBOutlet NSViewController *blockSettingsViewController;
@property (assign) IBOutlet AnalyzerSettingPopOverViewController *analyzerSettingsViewController;

@property (assign) IBOutlet TLImageWithPopover *imageWithPopover;
@property (nonatomic, readonly) NSTreeController *blockTreeController;
@property (assign) StBlock *previousBoundBlock;

- (IBAction)removeAnalyzer:(id)sender;
- (IBAction)collapse:(id)sender;
- (IBAction)blockSetttings:(id)sender;
- (IBAction)analyzerSettings:(id)sender;
- (void)popoverWillClose:(NSNotification *)notification;
- (void)loadStreamEditor;

- (void) suspendObservations;
- (void) resumeObservations;

@end
