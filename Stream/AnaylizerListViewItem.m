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
@synthesize savedCustomView;

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    if (representedObject != nil) {
        [representedObject addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
        [representedObject addObserver:self forKeyPath:@"collapse" options:0 context:self];
        
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
        else if ([keyPath isEqualToString:@"collapse"]) {
            [self noteViewHeightChanged];
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
        [self.representedObject removeObserver:self forKeyPath:@"collapse" context:self];
        self.representedObject = nil;
    }
    
    if (self.editorController != nil) {
        [self.editorController.view removeFromSuperview];
        [self.editorController setRepresentedObject:nil];
        self.editorController = nil;
    }
    
    self.savedCustomView = nil;
    
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
    [customView addSubview:[self.editorController view]];
}

- (CGFloat) heightForGivenWidth:(CGFloat)width {
    #pragma unused(width)
    StAnaylizer *ana = (StAnaylizer *)self.representedObject;
    float result = MINIMUM_HEIGHT;

    
    if (ana.collapse) {
//        if (self.savedCustomView != nil) {
//            if ([[self view] frame].size.height > MINIMUM_HEIGHT + 75 ) {
//                [[self view] addSubview:self.savedCustomView];
//                self.customView = self.savedCustomView;
//                self.savedCustomView = nil;
//                NSRect frame = [self.customView frame];
//                frame.size.height = [[self view] frame].size.height - MINIMUM_HEIGHT;
//                [self.customView setFrame:frame];
//            }
//        }
        
        result = ana.anaylizerHeight;
    }
    else {
//        if (self.savedCustomView == nil) {
//            self.savedCustomView = self.customView;
//            [[self customView] removeFromSuperviewWithoutNeedingDisplay];
//        }
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
    ana.collapse = !ana.collapse;

    [self noteViewHeightChanged];
}

@end
