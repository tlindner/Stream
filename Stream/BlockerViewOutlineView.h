//
//  BlockerViewOutlineView.h
//  Stream
//
//  Created by tim lindner on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StBlock;

@interface BlockerViewOutlineView : NSOutlineView

- (IBAction)makeSubStream:(id)sender;

@end

@interface NSObject (BlockAttributeTableViewDelegate)

- (NSColor *)tableView:(NSOutlineView *)aTableView backgroundColorForRow:(NSInteger)rowIndex;
- (StBlock *)observingBlock;

@end
