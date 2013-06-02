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
@property(nonatomic, retain) NSMutableArray *utiList;

+ (Analyzation *)sharedInstance;
- (void) addAnalyzer:(NSString *)analyzer;
- (NSArray *)analyzersforUTI:(NSString *)inUTI;
- (Class)analyzerClassforName:(NSString *)inName;

@end

@interface NSObject (AnalyzationExtensions)
+ (NSArray *)analyzerUTIs;
+ (NSString *)analyzerName;
+ (NSString *)analyzerKey;
+ (NSString *)AnalyzerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;
- (Class)viewControllerClass;
- (void)setRepresentedObject:(id)representedObject;
- (void)prepareAccessoryView: (NSView *)baseView;
@end

@interface NSViewController (StreamViewControllerExtensions)
- (void) startObserving;
@end
