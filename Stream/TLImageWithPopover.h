//
//  TLImageWithPopover.h
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TLImageWithPopover : NSImageView
{
    NSString *_errorMessage, *_errorMessage2;
}

@property (assign) NSString *errorMessage;
@property (assign) NSString *errorMessage2;

@end


@interface InsetTextView : NSTextView

@end