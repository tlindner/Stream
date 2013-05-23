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
- (IBAction)exportBlocks:(id)sender;

@end
