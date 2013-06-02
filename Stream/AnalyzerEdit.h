//
//  AnalyzerEdit.h
//  temp
//
//  Created by tim lindner on 5/7/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StAnalyzer;

@interface AnalyzerEdit : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic) int64_t length;
@property (nonatomic) int64_t location;
@property (nonatomic, retain) StAnalyzer *parent;

@end
