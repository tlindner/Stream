//
//  GenericArbitraryGroupBlocker.h
//  Stream
//
//  Created by tim lindner on 5/10/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StAnaylizer, StStream;

@interface GenericArbitraryGroupBlocker : NSObject

+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;

+ (void) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer;

@end

@interface namedRange : NSObject <NSCoding>
{
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSValue *range;

+ (id)namedRange: (NSValue *)aRange withName:(NSString*)aName;
@end