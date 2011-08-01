//
//  Analyzation.h
//  Stream
//
//  Created by tim lindner on 8/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Analyzation : NSObject
{
    NSMutableArray *classList;
}

@property(nonatomic, retain) NSMutableArray *classList;

+ (Analyzation *)sharedInstance;
- (void) addAnalyzer:(NSString *)anaylizer;

@end
