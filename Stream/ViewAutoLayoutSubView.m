//
//  ViewAutoLayoutSubView.m
//  Stream
//
//  Created by tim lindner on 8/3/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "ViewAutoLayoutSubView.h"

@implementation ViewAutoLayoutSubView

@synthesize additionalConstraints;

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
    if (additionalConstraints != nil) {
        [self removeConstraints:self.constraints];
        [additionalConstraints removeAllObjects];
    }
    else
        self.additionalConstraints = [[[NSMutableArray alloc] init] autorelease];

    NSDictionary *views = NSDictionaryOfVariableBindings(subview);
    self.additionalConstraints = [[[NSMutableArray alloc] init] autorelease];
    [additionalConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[subview]-0-|" options:0 metrics:nil views:views]];
    [additionalConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]-0-|" options:0 metrics:nil views:views]];
    [self addConstraints:additionalConstraints];
}

- (void)willRemoveSubview:(NSView *)subview
{
    if (additionalConstraints != nil)
    {
        [self removeConstraints:self.constraints];
        [additionalConstraints removeAllObjects];
        self.additionalConstraints = nil;
    }

}

- (void)dealloc
{
    self.additionalConstraints = nil;
    [super dealloc];
}
@end
