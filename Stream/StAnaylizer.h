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
    NSObject * anaylizerObject;
}

@property (nonatomic) float anaylizerHeight;
@property (nonatomic) BOOL collapse;
@property (nonatomic, retain) NSString * anaylizerKind;
@property (nonatomic, readonly) NSObject * anaylizerObject;
@property (nonatomic, readonly) float computedAnaylizerHeight;
@property (nonatomic, retain) NSString * currentEditorView;
@property (nonatomic, retain) NSMutableDictionary * optionsDictionary;
@property (nonatomic, retain) NSMutableIndexSet * editIndexSet;
@property (nonatomic, retain) NSMutableIndexSet * failIndexSet;
@property (nonatomic, retain) StStream *parentStream;
@property (nonatomic, retain) NSMutableData *resultingData;
@property (nonatomic, assign) NSString * sourceUTI;
@property (nonatomic, retain) NSString * resultingUTI;
@property (nonatomic, readonly) BOOL removeEnabled;
@property (nonatomic, readonly) BOOL editEnabled;
@property (nonatomic, readonly) BOOL blockSettingsHidden;
@property (nonatomic, readonly) NSString * title;
@property (nonatomic, assign ) NSViewController * viewController;
@property (nonatomic, readonly) BOOL canChangeEditor;

- (void) addSubOptionsDictionary:(NSString *)subOptionsID withDictionary:(NSMutableDictionary *)newOptions;
- (void) writebyte:(unsigned char) byte atOffset:(NSUInteger)offset;
- (NSURL *)urlForCachedData;
- (void) setResultingData:(NSMutableData *)inData andChangedIndexSet:(NSMutableIndexSet *)inIndexSet;
- (BOOL) streamEditedInRange:(NSRange)range;

@end

@interface streamLockValueTransformer : NSValueTransformer {
@private
}
@end

@interface NSValueTransformer (StreamsValueTransformerAdditions)
- (id)reverseTransformedValue:(id)value ofSize:(size_t)size;
@end

@interface NSData (StreamKeyValueCoding)
- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;
@end
