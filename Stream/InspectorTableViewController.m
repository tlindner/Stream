//
//  InspectorTableViewController.m
//  Stream
//
//  Created by tim lindner on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InspectorTableViewController.h"

@implementation InspectorTableViewController

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
//    [streamTreeControler addObserver:self forKeyPath:@"selection" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return nil;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == streamTreeControler) {
        if ([keyPath isEqualToString:@"selection"]) {
            NSLog( @"I got a change: %@", [streamTreeControler selectedObjects] );
        }
    }
}

- (void)dealloc
{
//    [streamTreeControler removeObserver:self forKeyPath:@"selection" context:nil];
}
@end
