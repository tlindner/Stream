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
@property (nonatomic, retain) NSString * anaylizerKind;
@property (nonatomic, retain) NSString * currentEditorView;
@property (nonatomic, retain) NSMutableDictionary *optionsDictionary;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) NSMutableData *resultingData;
@property (nonatomic, assign) NSString * sourceUTI;
@property (nonatomic, retain) NSString * resultingUTI;

- (void) addSubOptionsDictionary:(NSString *)subOptionsID withDictionary:(NSMutableDictionary *)newOptions;

@end
