//
//  BlockAttributeViewTableView.h
//  Stream
//
//  Created by tim lindner on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BlockAttributeViewTableView : NSTableView

@end

@interface NSObject (BlockAttributeTableViewDelegate)
- (NSColor *)tableView:(NSTableView *)aTableView backgroundColorForRow:(NSInteger)rowIndex;
@end
