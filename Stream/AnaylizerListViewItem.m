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
#import "BlockerProtocol.h"

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
    
    [super dealloc];
}

- (void)loadStreamEditor
{
    if (self.editorController != nil) {
        [self.editorController.view removeFromSuperview];
        [self.editorController setRepresentedObject:nil];
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
//    [customView addSubview:[self.editorController view]];
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

        Class <BlockerProtocol> blockerClass = NSClassFromString([theAna valueForKey:@"anaylizerKind"]);
        Class <BlockerViewControllerProtocol> viewControllerClass = NSClassFromString([blockerClass AnaylizerPopoverAccessoryViewNib]);
        
        if (viewControllerClass != nil) {
             blockSettingsViewController = [[viewControllerClass alloc] initWithNibName:[blockerClass AnaylizerPopoverAccessoryViewNib] bundle:nil];

            [blockSettingsViewController setRepresentedObject:theAna];
            [blockSettingsViewController setShowView:blockSettingsButton];
            [blockSettingsViewController loadView];
        }
   }
    
    [blockSettingsViewController showPopover];
}

@end
