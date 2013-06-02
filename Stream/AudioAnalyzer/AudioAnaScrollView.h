//
//  AudioAnaScrollView.h
//  Stream
//
//  Created by tim lindner on 8/8/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioAnalyzerViewController.h"

@class AudioAnalyzerViewController;

@interface AudioAnaScrollView : NSScrollView

@property (nonatomic, assign) AudioAnalyzerViewController *viewController;

@end
