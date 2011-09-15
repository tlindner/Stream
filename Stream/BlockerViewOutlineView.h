//
//  BlockerViewOutlineView.h
//  Stream
//
//  Created by tim lindner on 9/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BlockerViewOutlineView : NSOutlineView

@end

@interface NSObject (BlockAttributeTableViewDelegate)
- (NSColor *)tableView:(NSOutlineView *)aTableView backgroundColorForRow:(NSInteger)rowIndex;
@end
