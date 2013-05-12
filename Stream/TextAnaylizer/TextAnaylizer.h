//
//  TextAnaylizer.h
//  Stream
//
//  Created by tim lindner on 4/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Analyzation.h"
#import "StStream.h"
#import "StAnaylizer.h"
#import "StBlock.h"

@interface TextAnaylizer : NSObject
{
    StAnaylizer *representedObject;
}

@property (nonatomic, assign) StAnaylizer *representedObject;

- (NSString *)anaylizeData:(NSData *)bufferObject;

@end
