//
//  StAnaylizer.h
//  Stream
//
//  Created by tim lindner on 8/12/11.
//  Copyright (c) 2011 org.macmess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StStream;

@interface StAnaylizer : NSManagedObject
{
@private
}

@property (nonatomic) float anaylizerHeight;
@property (nonatomic) float previousAnaylizerHeight;
@property (nonatomic) BOOL collapse;
@property (nonatomic, retain) NSString * anaylizerKind;
@property (nonatomic, retain) NSString * currentEditorView;
@property (nonatomic, retain) NSMutableDictionary *optionsDictionary;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) NSMutableData *resultingData;
@property (nonatomic, assign) NSString * sourceUTI;
@property (nonatomic, retain) NSString * resultingUTI;
@property (nonatomic, readonly) BOOL removeEnabled;
@property (nonatomic, readonly) BOOL blockSettingsHidden;
@property (nonatomic, readonly) NSString * title;

- (void) addSubOptionsDictionary:(NSString *)subOptionsID withDictionary:(NSMutableDictionary *)newOptions;

@end

@interface streamLockValueTransformer : NSValueTransformer {
@private
}
@end