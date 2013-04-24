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

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    if (representedObject != nil) {
        [representedObject addObserver:self forKeyPath:@"currentEditorView" options:0 context:self];
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
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    if (self.representedObject != nil) {
        [self.representedObject removeObserver:self forKeyPath:@"currentEditorView" context:self];
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
    [self.editorController setRepresentedObject:self.representedObject];
    [self.editorController loadView];
    [[self.editorController view] setFrame:adjustedFrame];
    [customView addSubview:[self.editorController view]];
}

- (CGFloat) heightForGivenWidth:(CGFloat)width {
    StAnaylizer *ana = (StAnaylizer *)self.representedObject;
    float result = MINIMUM_HEIGHT;

    if (ana.collapse) {
        result = ana.anaylizerHeight;
    }
    
    return result;
}

- (IBAction)removeAnaylizer:(id)sender
{
    MyDocument *ourPerstantDocument = [[[[self view] window] windowController] document];
    [ourPerstantDocument removeAnaylizer:[self representedObject]];
}

- (IBAction)collapse:(id)sender {
    StAnaylizer *ana = (StAnaylizer *)self.representedObject;
    ana.collapse = !ana.collapse;

    [self noteViewHeightChanged];
}

@end
