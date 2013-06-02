//
//  RawBitmapAnalyzer.h
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StAnalyzer;

@interface RawBitmapAnalyzer : NSObject
{
    StAnalyzer *_representedObject;
}

@property (nonatomic, assign) StAnalyzer *representedObject;
@property (nonatomic, retain) NSData *resultingData;

- (void)analyzeData;

@end
