//
//  StreamEdit.h
//  Stream
//
//  Created by tim lindner on 4/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StStream;

@interface StreamEdit : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic) int64_t location;
@property (nonatomic) int64_t length;
@property (nonatomic, retain) StStream *parentStream;

@end
