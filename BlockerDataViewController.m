//
//  BlockerDataViewController.m
//  Stream
//
//  Created by tim lindner on 8/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerDataViewController.h"

@implementation BlockerDataViewController
@synthesize parentView;
@synthesize treeController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    [treeController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueChangeSetting context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"selectedObjects"] )
    {
//        NSLog( @"selection changed:%@", [object selectedObjects] );
        NSLog( @"the view rect: %@", NSStringFromRect([[self view] frame]) );
   }
}

- (void)dealloc
{
    [self removeObserver:treeController forKeyPath:@"selection"];
    [super dealloc];
}
@end
