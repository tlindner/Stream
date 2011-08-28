//
//  HFAnaylizer.h
//  Stream
//
//  Created by tim lindner on 8/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HFTextView.h"

@interface HFAnaylizer : NSView
{
    HFTextView *hexView;
}

@property (assign) id objectValue;

- (void)setRepresentedObject:(id)representedObject;

@end
