//
//  StData.h
//  temp
//
//  Created by tim lindner on 5/7/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface StData : NSManagedObject

@property (nonatomic, retain) NSString * resultingUTI;
@property (nonatomic, retain) NSString * sourceUTI;
@property (nonatomic, retain) NSString * analyzerKind;
@property (nonatomic, retain) NSString * currentEditorView;
@property (nonatomic) BOOL readOnly;
@property (nonatomic, retain) NSMutableDictionary *optionsDictionary;
@property (nonatomic, retain) NSObject *analyzerObject;
@property (nonatomic, assign, readwrite) NSViewController *viewController;
@property (nonatomic, retain) NSData *resultingData;
@property (nonatomic, retain) NSValue *unionRange;
@property (nonatomic, retain) NSString *errorString;

- (void) addSubOptionsDictionary:(NSString *)subOptionsID withDictionary:(NSMutableDictionary *)newOptions;
- (void) analyzeData;

@end

@interface StData (CoreDataGeneratedAccessors)

- (NSData *)primitiveResultingData;
- (void)setPrimitiveResultingData:(NSData *)data;
- (NSValue *)primitiveUnionRange;
- (void)setPrimitiveUnionRange:(NSValue *)value;

- (NSObject *)primitiveAnalyzerObject;
- (void)setPrimitiveAnalyzerObject:(NSObject *)ao;

@end

@interface NSObject (AnalyzerObjectAdditions)
- (void) analyzeData;
@end