//
//  StAnaylizer.h
//  temp
//
//  Created by tim lindner on 5/7/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "StData.h"

@class AnaylizerEdit, StStream;

@interface StAnaylizer : StData

@property (nonatomic) float anaylizerHeight;
@property (nonatomic, retain) NSString *anaylizerKind;
@property (nonatomic) BOOL paneExpanded;
@property (nonatomic) BOOL removeEnabled;
@property (nonatomic) BOOL blockSettingsHidden;
@property (nonatomic) BOOL blockSettingsEnabled;
@property (nonatomic, retain) NSString *currentEditorView;
@property (nonatomic, retain) NSMutableIndexSet *editIndexSet;
@property (nonatomic, retain) NSMutableIndexSet *failIndexSet;
@property (nonatomic, retain) NSData *resultingData;
@property (nonatomic, retain) NSValue *viewRange;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, retain) NSOrderedSet *edits;
@property (nonatomic, retain) NSData *sourceData;
@property (nonatomic, retain) StStream *parentStream;

- (float) computedAnaylizerHeight;
- (void) writebyte:(unsigned char)byte atOffset:(NSUInteger)offset;
- (NSURL *)urlForCachedData;
- (void) setResultingData:(NSMutableData *)inData andChangedIndexSet:(NSMutableIndexSet *)inIndexSet;
- (BOOL) streamEditedInRange:(NSRange)range;
- (StAnaylizer *)previousAnaylizer;
- (void) postEdit:(NSData *)data range:(NSRange)range;
- (void) postEdit: (NSData *)data atLocation: (int64_t)location withLength: (int64_t)length;
- (void) suspendObservations;
- (void) resumeObservations;
- (NSString *) descriptiveText;

- (IBAction)ConfigurableButton1:(id)sender;
- (IBAction)ConfigurableButton2:(id)sender;
@end

@interface StAnaylizer (CoreDataGeneratedAccessors)

- (void)insertObject:(AnaylizerEdit *)value inEditsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromEditsAtIndex:(NSUInteger)idx;
- (void)insertEdits:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeEditsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInEditsAtIndex:(NSUInteger)idx withObject:(AnaylizerEdit *)value;
- (void)replaceEditsAtIndexes:(NSIndexSet *)indexes withEdits:(NSArray *)values;
- (void)addEditsObject:(AnaylizerEdit *)value;
- (void)removeEditsObject:(AnaylizerEdit *)value;
- (void)addEdits:(NSOrderedSet *)values;
- (void)removeEdits:(NSOrderedSet *)values;

- (NSData *)primitiveSourceData;
- (void)setPrimitiveSourceData:(NSData *)data;

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

@interface NSViewController (StreamViewControllerExtras)
- (void)reloadView;
- (void) suspendObservations;
- (void) resumeObservations;
- (IBAction)ConfigurableButton1:(id)sender;
- (IBAction)ConfigurableButton2:(id)sender;
@end

@interface NSObject (StAnaylizerExtensions)
- (Class)viewControllerClass;
- (NSData *)resultingData;
- (void)replaceBytesInRange:(NSRange)range withBytes:(unsigned char *)byte;
@end


