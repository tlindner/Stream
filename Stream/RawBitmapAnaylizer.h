//
//  RawBitmapAnaylizer.h
//  Stream
//
//  Created by tim lindner on 5/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StAnaylizer;

@interface RawBitmapAnaylizer : NSObject
{
    StAnaylizer *_representedObject;
}

@property (nonatomic, assign) StAnaylizer *representedObject;
@property (nonatomic, retain) NSData *resultingData;

- (void)anaylizeData;

@end
