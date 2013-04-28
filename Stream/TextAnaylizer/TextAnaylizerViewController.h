//
//  TextAnaylizerViewController.h
//  Stream
//
//  Created by tim lindner on 4/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StAnaylizer.h"

@interface TextAnaylizerViewController : NSViewController
@property (assign) IBOutlet NSTextView *textView;
@property (nonatomic,retain) StAnaylizer *lastAnaylizer;

- (NSString *) transformInput;

@end