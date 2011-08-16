//
//  Analyzation.h
//  Stream
//
//  Created by tim lindner on 8/1/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Analyzation : NSObject
{
    NSMutableArray *classList;
    NSMutableDictionary *nameLookup;
}

@property(nonatomic, retain) NSMutableArray *classList;
@property(nonatomic, retain) NSMutableDictionary *nameLookup;

+ (Analyzation *)sharedInstance;
- (void) addAnalyzer:(NSString *)anaylizer;
- (NSArray *)anaylizersforUTI:(NSString *)inUTI;
- (Class)anaylizerClassforName:(NSString *)inName;

@end

@interface NSView(AnaylizationExtensions)
+ (NSArray *)anaylizerUTIs;
+ (NSString *)anayliserName;
- (void)setData:(NSData *)data;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;
- (void)prepareAccessoryView: (NSView *)baseView;
@end
