//
//  StRange.h
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StBlock;

@interface StRange : NSManagedObject {
@private
}
@property (nonatomic) int64_t length;
@property (nonatomic) int64_t offset;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * uiName;
@property (nonatomic, retain) NSData * checkbytes;
@property (nonatomic, retain) StBlock *parentBlock;

@end
