//
//  BlockAttributeAnaylizer.h
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Analyzation.h"
#import "StStream.h"
#import "StAnaylizer.h"
#import "StBlock.h"

@interface BlockAttributeAnaylizer : NSObject
{
    StAnaylizer *representedObject;
}
@property (assign) StAnaylizer * representedObject;

@end
