//
//  AudioAnaScrollView.h
//  Stream
//
//  Created by tim lindner on 8/8/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioAnaylizerViewController.h"

@class AudioAnaylizerViewController;

@interface AudioAnaScrollView : NSScrollView

@property (nonatomic, assign) AudioAnaylizerViewController *viewController;

@end
