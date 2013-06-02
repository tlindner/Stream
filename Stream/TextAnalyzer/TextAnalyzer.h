//
//  TextAnalyzer.h
//  Stream
//
//  Created by tim lindner on 4/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Analyzation.h"
#import "StStream.h"
#import "StAnalyzer.h"
#import "StBlock.h"

@interface TextAnalyzer : NSObject
{
    StAnalyzer *representedObject;
}

@property (nonatomic, assign) StAnalyzer *representedObject;
@property (nonatomic, retain) NSData *resultingData;

- (void)analyzeData;
@end
