//
//  WaveFormView.h
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WaveFormView : NSView
{
    uint8 *audioFrames;
    NSUInteger frameCount;
    NSUInteger scale;

}

@property(nonatomic, assign) uint8 *audioFrames;
@property(nonatomic, assign) NSUInteger frameCount;
@property(nonatomic, assign) NSUInteger scale;

@end
