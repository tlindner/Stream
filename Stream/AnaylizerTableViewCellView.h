//
//  AnaylizerTableViewCellView.h
//  Stream
//
//  Created by tim lindner on 7/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "ColorGradientView.h"

@interface AnaylizerTableViewCellView : NSTableCellView
{
    IBOutlet ColorGradientView *_cgv;
    IBOutlet NSView *_customView;
    id editorSubView;
    NSMutableArray *newConstraints;
    
}

@property(nonatomic, retain) id editorSubView;
@property(nonatomic, retain) NSMutableArray *newConstraints;

@end
