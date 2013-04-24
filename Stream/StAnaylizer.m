//
//  StAnaylizer.m
//  Stream
//
//  Created by tim lindner on 8/12/11.
//  Copyright (c) 2011 org.macmess. All rights reserved.
//

#import "StAnaylizer.h"
#import "StStream.h"
#import "Analyzation.h"
#import "HexFiendAnaylizer.h"

@implementation StAnaylizer

@dynamic anaylizerHeight;
@dynamic computedAnaylizerHeight;
@dynamic anaylizerKind;
@dynamic currentEditorView;
@dynamic optionsDictionary;
@dynamic editIndexSet;
@dynamic failIndexSet;
@dynamic parentStream;
@dynamic resultingData;
@dynamic sourceUTI;
@dynamic resultingUTI;
@dynamic collapse;
@dynamic removeEnabled;
@dynamic editEnabled;
@dynamic blockSettingsHidden;
@dynamic title;
@synthesize viewRange;
//@synthesize viewController;
@dynamic canChangeEditor;
@dynamic edits;

@dynamic anaylizerObject;

+ (void)initialize
{
    if ( self == [StAnaylizer class] )
    {
        // Setup standard value transformers
		streamLockValueTransformer *slvt;
		slvt = [[[streamLockValueTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:slvt forName:@"streamLockValueTransformer"];		
    }
}

+ (NSSet *)keyPathsForValuesAffectingAnaylizerObject
{
    return [NSSet setWithObjects:@"currentEditorView", nil];
}

- (NSObject *)anaylizerObject
{
    Class anaObjectClass = [[Analyzation sharedInstance] anaylizerClassforName:self.currentEditorView];
    
    if( anaObjectClass == nil )
        anaObjectClass = [HexFiendAnaylizer class];
    
    if( anaylizerObject == nil )
    {
        anaylizerObject = [[anaObjectClass alloc] init];
        [anaylizerObject setRepresentedObject:self];
    }
    else if( ![[anaylizerObject class] isSubclassOfClass:[[Analyzation sharedInstance] anaylizerClassforName:self.currentEditorView]] )
    {
        [anaylizerObject setRepresentedObject:nil];
        [anaylizerObject release];
        
        anaylizerObject = [[anaObjectClass alloc] init];
        [anaylizerObject setRepresentedObject:self];
    }
    
    return anaylizerObject;
}

- (void)dealloc
{
    if( anaylizerObject != nil )
    {
        [anaylizerObject setRepresentedObject:nil];
        [anaylizerObject release];
    }
    
    self.viewRange = nil;
    
    [super dealloc];
}

+ (NSSet *)keyPathsForValuesAffectingComputedAnaylizerHeight
{
    return [NSSet setWithObjects:@"anaylizerHeight", nil];
}

- (float) computedAnaylizerHeight
{
    if( self.collapse == NO )
        return 26.0;
    else
        return self.anaylizerHeight;
}

- (void) addSubOptionsDictionary:(NSString *)subOptionsID withDictionary:(NSMutableDictionary *)newOptions
{
    NSMutableDictionary *ourOptDict = self.optionsDictionary;
    
    if( [ourOptDict valueForKey:subOptionsID] == nil )
    {
        [ourOptDict setObject:newOptions forKey:subOptionsID];
        return;
    }
    
    NSMutableDictionary *dict = [ourOptDict objectForKey:subOptionsID];
    
    for (NSString *key in [newOptions allKeys])
    {
        id value = [dict objectForKey:key];
        
        if( value == nil )
            [dict setObject:[newOptions objectForKey:key] forKey:key];
    }
}

- (void) writebyte:(unsigned char)byte atOffset:(NSUInteger)offset
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:offset];
    NSRange range = NSMakeRange(offset, 1);
    
    /* make sure model object is listening */
    [self anaylizerObject];
    
    /* change byte in KVO approved ay */
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"resultingData"];
    [self.resultingData replaceBytesInRange:range withBytes:&byte];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"resultingData"];
    
    /* add byte index to edited index set */
    [self willChangeValueForKey:@"editIndexSet"];
    [self.editIndexSet addIndex:offset];
    [self didChangeValueForKey:@"editIndexSet"];
}

- (void)awakeFromInsert
{
    self.optionsDictionary = [[[NSMutableDictionary alloc] init] autorelease];
    self.editIndexSet = [[[NSMutableIndexSet alloc] init] autorelease];
    self.failIndexSet = [[[NSMutableIndexSet alloc] init] autorelease];
    self.resultingData = [[[NSMutableData alloc] init] autorelease];
}

- (void)awakeFromFetch
{
    /* the xml version of the fileformat seems to baken in the concreat versions of these properties */
    NSMutableDictionary *mutableOptions = [self.optionsDictionary mutableCopy];
    self.optionsDictionary = mutableOptions;
    [mutableOptions release];
    
    NSMutableIndexSet *mutableEditSet = [self.editIndexSet mutableCopy];
    self.editIndexSet = mutableEditSet;
    [mutableEditSet release];
    
    NSMutableIndexSet *mutableFailSet = [self.failIndexSet mutableCopy];
    self.failIndexSet = mutableFailSet;
    [mutableFailSet release];
    
    NSMutableData *mutableData = [self.resultingData mutableCopy];
    self.resultingData = mutableData;
    [mutableData release];
}

- (NSString *)sourceUTI
{
    NSString *result = nil;
    
    NSOrderedSet *streamSet = self.parentStream.anaylizers;
    NSUInteger theIndex = [streamSet indexOfObject:self];
    
    if( theIndex == 0 )
    {
        result = self.parentStream.sourceUTI;
    }
    else
    {
        StAnaylizer *previousAna = [streamSet objectAtIndex:theIndex-1];
        result = previousAna.resultingUTI;
    }
    
    return result;
}

- (void) setSourceUTI:(NSString *)parentUTI
{
    NSOrderedSet *streamSet = self.parentStream.anaylizers;
    NSUInteger theIndex = [streamSet indexOfObject:self];
    
    if( theIndex == 0 )
    {
        self.parentStream.sourceUTI = parentUTI;
    }
    else
    {
        StAnaylizer *previousAna = [streamSet objectAtIndex:theIndex-1];
        previousAna.resultingUTI = parentUTI;
    }
}

+ (NSSet *)keyPathsForValuesAffectingRemoveEnabled
{
    return [NSSet setWithObjects:@"parentStream.anaylizers", nil];
}

- (BOOL) removeEnabled
{
    BOOL result = NO;
    
    NSOrderedSet *streamSet = self.parentStream.anaylizers;
    NSUInteger indexOfMe = [streamSet indexOfObject:self];
    
    if( indexOfMe == 0 )
        result = NO;
    else if ( indexOfMe == ([streamSet count] - 1) )
        result = YES;
    
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingEditEnabled
{
    return [NSSet setWithObjects:@"parentStream", nil];
}

- (BOOL) editEnabled
{
    BOOL result = NO;
    
    if( self == [self.parentStream lastFilterAnayliser] )  
        result = YES;
    
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingBlockSettingsHidden
{
    return [NSSet setWithObjects:@"currentEditorView", nil];
}

- (BOOL) blockSettingsHidden
{
    BOOL result = YES;
    
    if( [self.currentEditorView isEqualToString:@"Blocker View" ])
        result = NO;
    
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingTitle
{
    return [NSSet setWithObjects:@"anaylizerKind", @"currentEditorView", nil];
}

- (NSString *) title
{
    NSString *result = nil;
    
    if( [self.currentEditorView isEqualToString:@"Blocker View" ])
        result = [NSString stringWithFormat:@"%@ — %@", self.anaylizerKind, self.currentEditorView];
    else
        result = self.currentEditorView;
    
    return result;    
}

- (NSURL *)urlForCachedData
{
    NSData *anaylizeData;
    StAnaylizer *previousAnaylizer = [self.parentStream previousAnayliser:self];
    
    if( previousAnaylizer == nil )
        anaylizeData = [self.parentStream bytesCache];
    else
        anaylizeData = [previousAnaylizer resultingData];
    
    NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cocoaudioanaylizer_tempfile.XXXXXX"];
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    int fileDescriptor = mkstemp(tempFileNameCString);
    NSString *tempFileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    free(tempFileNameCString);
    
    if (fileDescriptor == -1)
    {
        NSAssert(YES==NO, @"urlForCachedData: Could not create temporary file for cached data: %@", tempFileName);
        return nil;
    }
    
    NSFileHandle *tempFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:YES];
    [tempFileHandle writeData:anaylizeData];
    [tempFileHandle release];
    
    return [NSURL fileURLWithPath:tempFileName];
}

- (void) setResultingData:(NSMutableData *)inData andChangedIndexSet:(NSMutableIndexSet *)inIndexSet
{
    BOOL reBlock = NO;
    
    if( ![self.resultingData isEqualToData:inData] )
    {
        [self willChangeValueForKey:@"resultingData"];
        reBlock = YES;
        [self.resultingData setData:inData];
        [self didChangeValueForKey:@"resultingData"];

    }
    
    if( ![self.editIndexSet isEqualToIndexSet:inIndexSet] )
    {
        [self willChangeValueForKey:@"editIndexSet"];
        reBlock = YES; 
        [self.editIndexSet removeAllIndexes];
        [self.editIndexSet addIndexes:inIndexSet];
        [self didChangeValueForKey:@"editIndexSet"];
    }
    
    if( reBlock )
    {
        [self.parentStream regenerateAllBlocks];
    }
}

- (BOOL) streamEditedInRange:(NSRange)range
{
    NSIndexSet *changedIndexSet = [self editIndexSet];
    return [changedIndexSet intersectsIndexesInRange:range];
}

- (void)willTurnIntoFault
{
    if( anaylizerObject != nil)
    {
        [anaylizerObject setRepresentedObject:nil];
    }
}

- (BOOL) canChangeEditor
{
    BOOL result;
    
    result = ( self == [[[self parentStream] anaylizers] lastObject] );
    
    return result;
}

- (StAnaylizer *)previousAnaylizer
{
    return [[self parentStream] previousAnayliser:self];    
}

- (IBAction)ConfigurableButton1:(id)sender
{
//    if( [viewController respondsToSelector:@selector(ConfigurableButton1:)] )
//    {
//        [viewController ConfigurableButton1:(id)sender];
//    }
}

- (void) poseEdit:(NSData *)data range:(NSRange)range
{
    [self postEdit:data atLocation:range.location withLength:range.length];
}

- (void) postEdit: (NSData *)data atLocation: (int64_t)location withLength: (int64_t)length
{
    AnaylizerEdit *previousEdit = [[self edits] lastObject];
    
    if( previousEdit.location == location && previousEdit.length == length && [previousEdit.data length] == [data length] )
    {
        /* This edit replaced last edit */
        previousEdit.data = data;        
    }
    else
    {
        AnaylizerEdit *theEdit = [NSEntityDescription insertNewObjectForEntityForName:@"AnaylizerEdit" inManagedObjectContext:[self managedObjectContext]];
        theEdit.location = location;
        theEdit.length = length;
        theEdit.data = data;
        //    [self addEditsObject:theEdit];

        NSMutableOrderedSet *theSet = [self mutableOrderedSetValueForKey:@"edits"];
        //    [self willChangeValueForKey:@"edits" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:theEdit]];
        [theSet addObject:theEdit];
        //    [self didChangeValueForKey:@"edits" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:theEdit]];
    }
}

@end

@implementation streamLockValueTransformer

+ (Class)transformedValueClass
{
    return [NSImage class];
}

- (id)transformedValue:(id)value
{
    if( [value boolValue] )
    {
        return [NSImage imageNamed:@"NSRemoveTemplate"];
    }
    else
    {
        return [NSImage imageNamed:@"NSLockLockedTemplate"];
    }
}

@end

@implementation NSData (StreamKeyValueCoding)
- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes
{
    NSMutableArray *ma = [[NSMutableArray alloc] init];

    [indexes enumerateRangesUsingBlock:
     ^(NSRange range, BOOL *stop)
     {
         [ma addObject:[self subdataWithRange:range]];
     }];
    
    return [ma autorelease];
}

@end
