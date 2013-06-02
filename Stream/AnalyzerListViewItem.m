//
//  AnalyzerListViewItem.m
//  Stream
//
//  Created by tim lindner on 4/21/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//


#import "AnalyzerListViewItem.h"
#import "StAnalyzer.h"
#import "MyDocument.h"
#import "colorGradientView.h"
#import "DragRegionView.h"
#import "Blockers.h"
#import "BlockerDataViewController.h"
#import "AnalyzerSettingPopOverViewController.h"
#import "Analyzation.h"

#define MINIMUM_HEIGHT 26.0

void AbleAllControlsInView( NSView *inView, BOOL able );

@interface AnalyzerListViewItem ()

@end

@implementation AnalyzerListViewItem

@synthesize dragView;
@synthesize disclosureTriangle;
@synthesize customView;
@synthesize editorController;
@synthesize colorGradientView;
@synthesize blockSettingsButton;
@synthesize blockSettingsViewController;
@synthesize analyzerSettingsViewController;
@synthesize analyzerErrorButton;
@synthesize imageWithPopover;
@synthesize blockTreeController;
@synthesize previousBoundBlock;
@synthesize analyzerSettingsButton;
@synthesize utiList;
@synthesize editorList;
@synthesize acceptsUTIList;
@synthesize selectedBlock;
@synthesize previousSelectedBlock;

- (void)loadView
{
    [super loadView];
    [self loadStreamEditor];
    
    if (self.blockTreeController == nil) {
        [[self representedObject] addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
        [[self representedObject] addObserver:self forKeyPath:@"sourceUTI" options:0 context:self];
        [[self.representedObject analyzerObject] analyzeData];
    } else {
        [self.blockTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:self];
        [[self selectedBlock] addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
        [[self selectedBlock] addObserver:self forKeyPath:@"sourceUTI" options:0 context:self];
    }
    
    [[self representedObject] addObserver:self forKeyPath:@"paneExpanded" options:0 context:self];
}

- (NSArray *)utiList
{
    return [Analyzation sharedInstance].utiList;
}

- (NSString *)acceptsUTIList
{
    StData *ro = self.representedObject;
    StBlock *block = [self selectedBlock];
    Class anaClass;
    
    if (block == nil) {
        anaClass = [[Analyzation sharedInstance] analyzerClassforName:ro.currentEditorView];
    } else {
        anaClass = [[Analyzation sharedInstance] analyzerClassforName:block.currentEditorView];
    }

    return [[anaClass analyzerUTIs] componentsJoinedByString:@", "];
}

- (NSArray *)editorList
{
    StData *ro = [self selectedBlock];
    
    if (ro == nil) {
        ro = [self representedObject];
    }
    
    return [[Analyzation sharedInstance] analyzersforUTI:[ro valueForKey:@"sourceUTI"]];
}

- (NSTreeController *)blockTreeController
{
    NSTreeController *result = nil;
    
    if ([[[self representedObject] currentEditorView] isEqualToString:@"Blocker View"]) {
        BlockerDataViewController *blockerController = (BlockerDataViewController *)self.editorController;
        result = blockerController.treeController;
    }
    
    return result;
}

- (StBlock *)selectedBlock
{
    StBlock *result = nil;
    
    if( self.blockTreeController != nil )
    {
        NSArray *selectedObjects = [self.blockTreeController selectedObjects];
        
        if( [selectedObjects count] > 0 )
        {
            result = [selectedObjects objectAtIndex:0];
        }
    }
    
    return result;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        if ([keyPath isEqualToString:@"sourceUTI"]) {
            StData *ro = [self selectedBlock];
            
            if (ro == nil) {
                ro =  self.representedObject;
            }

            if (![self.editorList containsObject:ro.currentEditorView]) {
                ro.currentEditorView = @"Hex Editor";
            }
            
            [self willChangeValueForKey:@"editorList"];
            [self didChangeValueForKey:@"editorList"];
        } else if ([keyPath isEqualToString:@"currentEditorView"]) {
            [self willChangeValueForKey:@"acceptsUTIList"];

            if (self.blockTreeController == nil) {
                [self loadStreamEditor];
            } else {
                if (analyzerSettingsViewController != nil) {
                    [self.analyzerSettingsViewController setAccessoryView];
                }
            }
            
            [self didChangeValueForKey:@"acceptsUTIList"];
        } else if ([keyPath isEqualToString:@"paneExpanded"]) {
            if (!dragView.doingLiveResize) {
                StAnalyzer *theAna = [self representedObject];
                BOOL paneExpanded = theAna.paneExpanded;
                
                if (paneExpanded) {
                    /* pane is opening */
                    [self setLiveResize:YES];
                    [self noteViewHeightChanged];
                    [dragView setCustomSubView:nil paneExpanded:paneExpanded];
                    [self setLiveResize:NO];
                }
                else {
                    /* pane is closing */
                    [self setLiveResize:YES];
                    [dragView setCustomSubView:nil paneExpanded:paneExpanded];
                    [self noteViewHeightChanged];
                    [self setLiveResize:NO];
                }
            }
        } else if ([keyPath isEqualToString:@"selectedObjects"]) {
            if ([[self.editorController class] isSubclassOfClass:[BlockerDataViewController class]]) {
                
                /* update error popups */
                [imageWithPopover unbind:@"errorMessage2"];
                StBlock *block = [self selectedBlock];
                if (block != nil) {
                    [imageWithPopover bind:@"errorMessage2" toObject:block withKeyPath:@"errorString" options:nil];
                }

                /* update setting pop over */
                if (analyzerSettingsViewController != nil) {
                    [self willChangeValueForKey:@"editorList"];
                    [self willChangeValueForKey:@"acceptsUTIList"];

                    [self.previousSelectedBlock removeObserver:self forKeyPath:@"currentEditorView" context:self];
                    [self.previousSelectedBlock removeObserver:self forKeyPath:@"sourceUTI" context:self];
                    [self.analyzerSettingsViewController setAccessoryView];
                    
                    self.previousSelectedBlock = [self selectedBlock];
                    [self.previousSelectedBlock addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
                    [self.previousSelectedBlock addObserver:self forKeyPath:@"sourceUTI" options:0 context:self];

                    [self didChangeValueForKey:@"acceptsUTIList"];
                    [self didChangeValueForKey:@"editorList"];
                }
            } else {
                NSLog(@"selected objects changed but, editor controller is not a block controller");
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    [self suspendObservations];
    
    if (analyzerSettingsViewController != nil) {
        [analyzerSettingsViewController.popover performClose:self];
    }
    
    self.editorController = nil;
    self.blockSettingsViewController = nil;
    [imageWithPopover unbind:@"errorMessage"];
    StAnalyzer *theAna = [self representedObject];
    theAna.viewController = nil;

    [super dealloc];
}

- (void)loadStreamEditor
{
    if (self.editorController != nil) {
        [self.editorController.view removeFromSuperview];
        self.editorController = nil;
    }
    
    StAnalyzer *theAna = [self representedObject];
    NSObject *analyzerObject = [theAna analyzerObject];
    
    NSRect adjustedFrame = [customView frame];
    adjustedFrame.origin.x = 0;
    adjustedFrame.origin.y = 0;
    self.editorController = [[[[analyzerObject viewControllerClass] alloc] initWithNibName:nil bundle:nil] autorelease];
    [theAna setViewController:self.editorController];
    [self.editorController setRepresentedObject:self.representedObject];
    [self.editorController loadView];
    [[self.editorController view] setFrame:adjustedFrame];
    [dragView setCustomSubView:[self.editorController view] paneExpanded:theAna.paneExpanded];
    
    [imageWithPopover unbind:@"errorMessage"];
    [imageWithPopover bind:@"errorMessage" toObject:theAna withKeyPath:@"errorString" options:nil];

    if (analyzerSettingsViewController != nil) {
        [self.analyzerSettingsViewController setAccessoryView];
    }
}

- (CGFloat) heightForGivenWidth:(CGFloat)width {
    #pragma unused(width)
    StAnalyzer *ana = (StAnalyzer *)self.representedObject;
    float result;

    if (dragView.doingLiveResize) {
        result = ana.analyzerHeight;
    }
    else if (ana.paneExpanded) {
        result = ana.analyzerHeight;
    }
    else {
        result = MINIMUM_HEIGHT;
    }

    return floor(result);
}

- (IBAction)removeAnalyzer:(id)sender
{
    #pragma unused(sender)
    MyDocument *ourPersistentDocument = [[[[self view] window] windowController] document];
    [ourPersistentDocument removeAnalyzer:[self representedObject]];
}

- (IBAction)collapse:(id)sender {
    #pragma unused(sender)
    StAnalyzer *ana = (StAnalyzer *)self.representedObject;
    ana.paneExpanded = !ana.paneExpanded;

    [self noteViewHeightChanged];
}

- (IBAction)blockSetttings:(id)sender
{
#pragma unused (sender)
    if (blockSettingsViewController == nil) {
        StAnalyzer *theAna = [self representedObject];
        
        Class blockerClass = NSClassFromString([theAna valueForKey:@"analyzerKind"]);
        Class viewControllerClass = NSClassFromString([blockerClass blockerPopoverAccessoryViewNib]);
        
        if (viewControllerClass != nil) {
            blockSettingsViewController = [(NSViewController *)[viewControllerClass alloc] initWithNibName:[blockerClass blockerPopoverAccessoryViewNib] bundle:nil];
            
            [blockSettingsViewController setRepresentedObject:theAna];
            [blockSettingsViewController loadView];
        }
    }
    
    [blockSettingsViewController showPopover:blockSettingsButton];
}

- (IBAction)analyzerSettings:(id)sender
{
#pragma unused (sender)
    if (analyzerSettingsViewController == nil) {
        if (self.blockTreeController == nil) {
            self.analyzerSettingsViewController = [[AnalyzerSettingPopOverViewController alloc] initWithNibName:@"AnalyzerSettingPopover" bundle:nil];
        } else {
            self.analyzerSettingsViewController = [[AnalyzerSettingPopOverViewController alloc] initWithNibName:@"AnalyzerBlockSettingPopover" bundle:nil];
            [self.selectedBlock addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
            [self.selectedBlock addObserver:self forKeyPath:@"sourceUTI" options:0 context:self];
            self.previousSelectedBlock = self.selectedBlock;
        }
        
        [self.analyzerSettingsViewController setRepresentedObject:self];
        [self.analyzerSettingsViewController loadView];
    }
    
    [self.analyzerSettingsViewController showPopover:analyzerSettingsButton];
    [self.analyzerSettingsViewController setAccessoryView];
}

- (void)popoverWillClose:(NSNotification *)notification
{
    if ([notification object] == analyzerSettingsViewController.popover) {
        /* analyzer view controller will close */
        [[self selectedBlock] removeObserver:self forKeyPath:@"currentEditorView" context:self];
        self.analyzerSettingsViewController = nil;
    }
}

- (void) suspendObservations
{
    [blockSettingsViewController suspendObservations];
    [editorController suspendObservations];

    if (self.blockTreeController == nil) {
        [[self representedObject] removeObserver:self forKeyPath:@"currentEditorView" context:self];
        [[self representedObject] removeObserver:self forKeyPath:@"sourceUTI" context:self];
    } else {
        if (analyzerSettingsViewController != nil) {
            [[self selectedBlock] removeObserver:self forKeyPath:@"currentEditorView" context:self];
            [[self selectedBlock] removeObserver:self forKeyPath:@"sourceUTI" context:self];
        }
        
        [self.blockTreeController removeObserver:self forKeyPath:@"selectedObjects" context:self];
    }

    [[self representedObject] removeObserver:self forKeyPath:@"paneExpanded" context:self];
}

- (void) resumeObservations
{
    [blockSettingsViewController resumeObservations];
    [editorController resumeObservations];

    if (self.blockTreeController == nil) {
        [[self representedObject] addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
        [[self representedObject] addObserver:self forKeyPath:@"sourceUTI" options:0 context:self];
    } else {
        if (analyzerSettingsViewController != nil) {
            [[self selectedBlock] addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
            [[self selectedBlock] addObserver:self forKeyPath:@"sourceUTI" options:0 context:self];
        }
        
        [self.blockTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:self];
    }

    [[self representedObject] addObserver:self forKeyPath:@"paneExpanded" options:0 context:self];
}

@end

void AbleAllControlsInView( NSView *inView, BOOL able )
{
    NSArray *subViews = [inView subviews];
    
    for (NSView *view in subViews) {
        if ([[view class] isSubclassOfClass:[NSControl class]]) {
            NSControl *control = (NSControl *)view;
            [control setEnabled:able];
        }
        
        AbleAllControlsInView(view, able);
    }
}
