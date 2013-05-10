//
//  GenericArbitraryGroupBlocker.h
//  Stream
//
//  Created by tim lindner on 5/10/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GenericArbitraryGroupBlocker : NSObject

@end

@interface namedRange : NSObject <NSCoding>
{
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSValue *range;

+ (id)namedRange: (NSValue *)aRange withName:(NSString*)aName;
@end