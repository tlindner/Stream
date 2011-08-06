//
//  ViewAutoLayoutSubView.m
//  Stream
//
//  Created by tim lindner on 8/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewAutoLayoutSubView.h"

@implementation ViewAutoLayoutSubView

@synthesize newConstraints;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)didAddSubview:(NSView *)subview
{
    if (self.newConstraints != nil) {
        [self removeConstraints:self.constraints];
        [self.newConstraints removeAllObjects];
    }
    else
        self.newConstraints = [[[NSMutableArray alloc] init] autorelease];

    NSDictionary *views = NSDictionaryOfVariableBindings(subview);
    self.newConstraints = [[[NSMutableArray alloc] init] autorelease];
    [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[subview]-0-|" options:0 metrics:nil views:views]];
    [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]-0-|" options:0 metrics:nil views:views]];
    [self addConstraints:newConstraints];
}

- (void)willRemoveSubview:(NSView *)subview
{
    if (self.newConstraints != nil)
    {
        [self removeConstraints:self.constraints];
        [self.newConstraints removeAllObjects];
        self.newConstraints = nil;
    }

}

- (void)dealloc
{
    self.newConstraints = nil;
    [super dealloc];
}
@end
