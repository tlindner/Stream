//
//  AnaylizerTableViewCellView.m
//  Stream
//
//  Created by tim lindner on 7/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AnaylizerTableViewCellView.h"
#import "HFTextView.h"
#import "AudioAnaylizer.h"
#import "Analyzation.h"

@implementation AnaylizerTableViewCellView

@synthesize editorSubView;
@synthesize newConstraints;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self addObserver:self forKeyPath:@"objectValue.currentEditorView" options:NSKeyValueChangeSetting context:nil];
    [super awakeFromNib];
}

- (void)updateConstraints {
    if( newConstraints == nil )
    {
        NSDictionary *views = NSDictionaryOfVariableBindings(_customView, _cgv);
        self.newConstraints = [[[NSMutableArray alloc] init] autorelease];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[_customView]-0-|" options:0 metrics:nil views:views]];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[_cgv]-0-|" options:0 metrics:nil views:views]];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_cgv(==20)]-0-[_customView]-0-|" options:0 metrics:nil views:views]];
        [self removeConstraints:[self constraints]];
        [self addConstraints:newConstraints];
    }
    
    [super updateConstraints];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:@"objectValue.currentEditorView"]) {
        //NSLog( @"Anaylizer table view cell view change.\n object: %@\n key path: %@\nchange: %@", object, keyPath, change );
        
        if( self.editorSubView != nil )
        {
            //teardown exiting sub view editor
            [self.editorSubView removeFromSuperview];
            self.editorSubView = nil;
        }
        
        // Create sub view editor.
        Class editorViewClass = [[Analyzation sharedInstance] anaylizerClassforName:[change objectForKey:@"new"]];
        
        if (editorViewClass == nil)
        {
            editorViewClass = [HFTextView class];
        }
        
        self.editorSubView = [[[editorViewClass alloc] initWithFrame:[_customView frame]] autorelease];

        [_customView addSubview:self.editorSubView];
        [self.editorSubView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
        [self.editorSubView setData:[self.objectValue valueForKeyPath:@"parentStream.bytesCache"]];      
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"objectValue.currentEditorView"];
    self.editorSubView = nil;
    self.newConstraints= nil;
    [super dealloc];
}

@end
