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
#import "AnaylizerSettingPopOverViewController.h"
#import "Analyzation.h"

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
@synthesize anaylizerSettingsViewController;
@synthesize anaylizerErrorButton;
@synthesize imageWithPopover;
@synthesize blockTreeController;
@synthesize previousBoundBlock;
@synthesize anaylizerSettingsButton;
@synthesize utiList;
@synthesize editorList;
@synthesize acceptsUTIList;
@synthesize selectedBlock;

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    if (representedObject != nil) {
        [representedObject addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
        [representedObject addObserver:self forKeyPath:@"paneExpanded" options:0 context:self];
//        [representedObject addObserver:self forKeyPath:@"sourceUTI" options:0 context:self];
    }    
}

- (void)loadView
{
    [super loadView];
    [self loadStreamEditor];
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
        anaClass = [[Analyzation sharedInstance] anaylizerClassforName:ro.currentEditorView];
    } else {
        anaClass = [[Analyzation sharedInstance] anaylizerClassforName:block.currentEditorView];
    }

    return [[anaClass anaylizerUTIs] componentsJoinedByString:@", "];
}

- (NSArray *)editorList
{
    StData *ro = [self selectedBlock];
    
    if (ro == nil) {
        ro = [self representedObject];
    }
    
    return [[Analyzation sharedInstance] anaylizersforUTI:[ro valueForKey:@"sourceUTI"]];
}

- (StBlock *)selectedBlock
{
    StBlock *result = nil;
    StData *ro = self.representedObject;
    
    if( [ro.currentEditorView isEqualToString:@"Blocker View"] )
    {
        BlockerDataViewController *blockerController = (BlockerDataViewController *)self.editorController;
        blockTreeController = blockerController.treeController;
        NSArray *selectedObjects = [blockTreeController selectedObjects];
        
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
        }
        else if ([keyPath isEqualToString:@"currentEditorView"]) {
            [self willChangeValueForKey:@"acceptsUTIList"];
            [self loadStreamEditor];
            [self didChangeValueForKey:@"acceptsUTIList"];
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
            if ([[self.editorController class] isSubclassOfClass:[BlockerDataViewController class]]) {
                
                /* update error popups */
                [imageWithPopover unbind:@"errorMessage2"];
                StBlock *block = [self selectedBlock];
                if (block != nil) {
                    [imageWithPopover bind:@"errorMessage2" toObject:block withKeyPath:@"errorString" options:nil];
                }
                
                /* update setting pop over */
                if (anaylizerSettingsViewController != nil) {
                    [self willChangeValueForKey:@"editorList"];
                    [self willChangeValueForKey:@"acceptsUTIList"];
                    [self.anaylizerSettingsViewController setAccessoryView];
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
    StAnaylizer *theAna = [self representedObject];
    
    if (self.representedObject != nil) {
        [self.representedObject removeObserver:self forKeyPath:@"currentEditorView" context:self];
        [self.representedObject removeObserver:self forKeyPath:@"paneExpanded" context:self];
        self.representedObject = nil;
    }
    
    if (self.editorController != nil) {
//        [self.editorController.view removeFromSuperview];
//        [self.editorController setRepresentedObject:nil];
        self.editorController = nil;
    }
    
    blockSettingsViewController = nil;
    
    if (self.blockTreeController != nil) {
        [self.blockTreeController removeObserver:self forKeyPath:@"selectedObjects" context:self];
        self.blockTreeController = nil;
    }

    [imageWithPopover unbind:@"errorMessage"];
    theAna.viewController = nil;
    
    [theAna setViewController:nil];
    
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
    
    if (anaylizerSettingsViewController != nil) {
        [self.anaylizerSettingsViewController setAccessoryView];
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

- (IBAction)anaylizerSettings:(id)sender
{
#pragma unused (sender)
    if (anaylizerSettingsViewController == nil) {
        StBlock *block = [self selectedBlock];
        
        if (block == nil) {
            self.anaylizerSettingsViewController = [[AnaylizerSettingPopOverViewController alloc] initWithNibName:@"AnaylizerSettingPopover" bundle:nil];
        } else {
            self.anaylizerSettingsViewController = [[AnaylizerSettingPopOverViewController alloc] initWithNibName:@"AnaylizerBlockSettingPopover" bundle:nil];
        }
        
        [self.anaylizerSettingsViewController setRepresentedObject:self];
        [self.anaylizerSettingsViewController loadView];
    }
    
    [self.anaylizerSettingsViewController showPopover:anaylizerSettingsButton];
    [self.anaylizerSettingsViewController setAccessoryView];
}

- (void)popoverWillClose:(NSNotification *)notification
{
    if ([notification object] == anaylizerSettingsViewController.popover) {
        /* anaylizer view controller will close */
        self.anaylizerSettingsViewController = nil;
    }
}

- (void) suspendObservations
{
    [blockSettingsViewController suspendObservations];
    [editorController suspendObservations];

    if ([self representedObject] != nil) {
        [[self representedObject] removeObserver:self forKeyPath:@"currentEditorView" context:self];
        [[self representedObject] removeObserver:self forKeyPath:@"paneExpanded" context:self];
//        [self.representedObject removeObserver:self forKeyPath:@"sourceUTI" context:self];
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
//        [[self representedObject] addObserver:self forKeyPath:@"sourceUTI" options:0 context:self];
    }
    
    if ([[[self representedObject] valueForKey:@"currentEditorView"] isEqualToString:@"Blocker View"]) {
        BlockerDataViewController *blockerController = (BlockerDataViewController *)self.editorController;
        blockTreeController = blockerController.treeController;
        [blockTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:self];
    }
}


@end
