//
//  AnaylizerListViewItem.m
//  Stream
//
//  Created by tim lindner on 4/21/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//


#import "AnaylizerListViewItem.h"
#import "StAnaylizer.h"
#import "MyDocument.h"
#import "colorGradientView.h"
#import "DragRegionView.h"
#import "Blockers.h"
#import "BlockerDataViewController.h"

#define MINIMUM_HEIGHT 26.0

@interface AnaylizerListViewItem ()

@end

@implementation AnaylizerListViewItem

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}

@synthesize dragView;
@synthesize disclosureTriangle;
@synthesize customView;
@synthesize editorController;
@synthesize colorGradientView;
@synthesize blockSettingsButton;
@synthesize blockSettingsViewController;
@synthesize anaylizerErrorButton;
@synthesize imageWithPopover;
@synthesize blockTreeController;
@synthesize previousBoundBlock;

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    if (representedObject != nil) {
        [representedObject addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
        [representedObject addObserver:self forKeyPath:@"paneExpanded" options:0 context:self];
    }    
}

- (void)loadView
{
    [super loadView];
    [self loadStreamEditor];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        if ([keyPath isEqualToString:@"currentEditorView"]) {
            [self loadStreamEditor];
        }
        else if ([keyPath isEqualToString:@"paneExpanded"]) {
            if (!dragView.doingLiveResize) {
                StAnaylizer *theAna = [self representedObject];
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
            BlockerDataViewController *blockerController = (BlockerDataViewController *)self.editorController;
            blockTreeController = blockerController.treeController;
            NSArray *selectedObjects = [blockTreeController selectedObjects];
            
            [imageWithPopover unbind:@"errorMessage2"];
            
            if ([selectedObjects count] == 1 ) {
                StBlock *selectObject = [selectedObjects objectAtIndex:0];
                [imageWithPopover bind:@"errorMessage2" toObject:selectObject withKeyPath:@"errorString" options:nil];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    StAnaylizer *theAna = [self representedObject];
    [theAna setViewController:nil];

    if (self.representedObject != nil) {
        [self.representedObject removeObserver:self forKeyPath:@"currentEditorView" context:self];
        [self.representedObject removeObserver:self forKeyPath:@"paneExpanded" context:self];
        self.representedObject = nil;
    }
    
    if (self.editorController != nil) {
        [self.editorController.view removeFromSuperview];
        [self.editorController setRepresentedObject:nil];
        self.editorController = nil;
    }
    
    blockSettingsViewController = nil;
    
    if (self.blockTreeController != nil) {
        [self.blockTreeController removeObserver:self forKeyPath:@"selectedObjects" context:self];
        self.blockTreeController = nil;
    }

    [imageWithPopover unbind:@"errorMessage"];

    [super dealloc];
}

- (void)loadStreamEditor
{
    if (self.editorController != nil) {
        [self.editorController.view removeFromSuperview];
        self.editorController = nil;
    }
    
    StAnaylizer *theAna = [self representedObject];
    NSObject *anaylizerObject = [theAna anaylizerObject];
    
    NSRect adjustedFrame = [customView frame];
    adjustedFrame.origin.x = 0;
    adjustedFrame.origin.y = 0;
    self.editorController = [[[[anaylizerObject viewControllerClass] alloc] initWithNibName:nil bundle:nil] autorelease];
    [theAna setViewController:self.editorController];
    [self.editorController setRepresentedObject:self.representedObject];
    [self.editorController loadView];
    [[self.editorController view] setFrame:adjustedFrame];
    [dragView setCustomSubView:[self.editorController view] paneExpanded:theAna.paneExpanded];
    
    
    [imageWithPopover unbind:@"errorMessage"];
    [imageWithPopover bind:@"errorMessage" toObject:theAna withKeyPath:@"errorString" options:nil];
    
    if ([[theAna valueForKey:@"currentEditorView"] isEqualToString:@"Blocker View"]) {
        BlockerDataViewController *blockerController = (BlockerDataViewController *)self.editorController;
        blockTreeController = blockerController.treeController;
        [blockTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:self];
    }
}

- (CGFloat) heightForGivenWidth:(CGFloat)width {
    #pragma unused(width)
    StAnaylizer *ana = (StAnaylizer *)self.representedObject;
    float result;

    if (dragView.doingLiveResize) {
        result = ana.anaylizerHeight;
    }
    else if (ana.paneExpanded) {
        result = ana.anaylizerHeight;
    }
    else {
        result = MINIMUM_HEIGHT;
    }

    return floor(result);
}

- (IBAction)removeAnaylizer:(id)sender
{
    #pragma unused(sender)
    MyDocument *ourPerstantDocument = [[[[self view] window] windowController] document];
    [ourPerstantDocument removeAnaylizer:[self representedObject]];
}

- (IBAction)collapse:(id)sender {
    #pragma unused(sender)
    StAnaylizer *ana = (StAnaylizer *)self.representedObject;
    ana.paneExpanded = !ana.paneExpanded;

    [self noteViewHeightChanged];
}

- (IBAction)blockSetttings:(id)sender
{
#pragma unused (sender)
    if (blockSettingsViewController == nil) {
        StAnaylizer *theAna = [self representedObject];

        Class blockerClass = NSClassFromString([theAna valueForKey:@"anaylizerKind"]);
        Class viewControllerClass = NSClassFromString([blockerClass blockerPopoverAccessoryViewNib]);
        
        if (viewControllerClass != nil) {
             blockSettingsViewController = [(NSViewController *)[viewControllerClass alloc] initWithNibName:[blockerClass blockerPopoverAccessoryViewNib] bundle:nil];

            [blockSettingsViewController setRepresentedObject:theAna];
            [blockSettingsViewController loadView];
        }
   }
    
    [blockSettingsViewController showPopover:blockSettingsButton];
}

- (void) suspendObservations
{
    [blockSettingsViewController suspendObservations];
    [editorController suspendObservations];
    
    if ([self representedObject] != nil) {
        [[self representedObject] removeObserver:self forKeyPath:@"currentEditorView" context:self];
        [[self representedObject] removeObserver:self forKeyPath:@"paneExpanded" context:self];
    }

    if ([[[self representedObject] valueForKey:@"currentEditorView"] isEqualToString:@"Blocker View"]) {
        BlockerDataViewController *blockerController = (BlockerDataViewController *)self.editorController;
        blockTreeController = blockerController.treeController;
        [blockTreeController removeObserver:self forKeyPath:@"selectedObjects" context:self];
    }
}

- (void) resumeObservations
{
    [blockSettingsViewController resumeObservations];
    [editorController resumeObservations];
    
    if ([self representedObject] != nil) {
        [[self representedObject] addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
        [[self representedObject] addObserver:self forKeyPath:@"paneExpanded" options:0 context:self];
    }
    
    if ([[[self representedObject] valueForKey:@"currentEditorView"] isEqualToString:@"Blocker View"]) {
        BlockerDataViewController *blockerController = (BlockerDataViewController *)self.editorController;
        blockTreeController = blockerController.treeController;
        [blockTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:self];
    }
}


@end
