//
//  StAnaylizer.m
//  temp
//
//  Created by tim lindner on 5/7/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StAnaylizer.h"
#import "AnaylizerEdit.h"
#import "StStream.h"
#import "Analyzation.h"
#import "HexFiendAnaylizer.h"
#import "TextAnaylizer.h"
#import "Blockers.h"

NSURL *MakeTemporaryFile( NSString *pattern );

@implementation StAnaylizer

@dynamic anaylizerHeight;
@dynamic anaylizerKind;
@dynamic paneExpanded;
@dynamic removeEnabled;
@dynamic blockSettingsEnabled;
@dynamic blockSettingsHidden;
@dynamic currentEditorView;
@dynamic editIndexSet;
@dynamic resultingData;
@dynamic viewRange;
@dynamic edits;
@dynamic parentStream;
@dynamic title;
@dynamic failIndexSet;
@dynamic sourceData;

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

- (NSData *)sourceData
{
    NSData *_sourceData;
    
    _sourceData = [self primitiveSourceData];
    
    if (_sourceData == nil) {
        _sourceData = [[[NSData alloc] initWithContentsOfURL:[self urlForCachedData]] autorelease];
        [self setPrimitiveSourceData:_sourceData];
    }
    
    return _sourceData;
}

+ (NSSet *)keyPathsForValuesAffectingAnaylizerObject
{
    return [NSSet setWithObjects:@"currentEditorView", nil];
}

- (float) computedAnaylizerHeight
{
    if( self.paneExpanded == NO )
        return 26.0;
    else
        return self.anaylizerHeight;
}

- (void) writebyte:(unsigned char)byte atOffset:(NSUInteger)offset
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:offset];
    NSRange range = NSMakeRange(offset, 1);
    
    /* make sure model object is listening */
    [self anaylizerObject];
    
    /* change byte in KVO approved ay */
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"resultingData"];
    [self.anaylizerObject replaceBytesInRange:range withBytes:&byte];
//    [self.resultingData replaceBytesInRange:range withBytes:&byte];
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
}

- (void)awakeFromFetch
{
    /* the xml version of the fileformat seems to brake in the concreat versions of these properties */
    NSMutableDictionary *mutableOptions = [self.optionsDictionary mutableCopy];
    self.optionsDictionary = mutableOptions;
    [mutableOptions release];
    
    NSMutableIndexSet *mutableEditSet = [self.editIndexSet mutableCopy];
    self.editIndexSet = mutableEditSet;
    [mutableEditSet release];
    
    NSMutableIndexSet *mutableFailSet = [self.failIndexSet mutableCopy];
    self.failIndexSet = mutableFailSet;
    [mutableFailSet release];
}

- (NSString *)sourceUTI
{
    NSString *result = nil;
    
    StAnaylizer *previousAna = [self.parentStream previousAnayliser:self];
    
    if (previousAna == nil) {
        result = self.parentStream.sourceUTI;
    }
    else {
        result = previousAna.sourceUTI;
    }

    return result;
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

- (void) setSourceUTI:(NSString *)parentUTI
{
    StAnaylizer *previousAna = [self.parentStream previousAnayliser:self];
    
    if (previousAna == nil) {
        self.parentStream.sourceUTI = parentUTI;
    }
    else {
        previousAna.resultingUTI = parentUTI;
    }
}

- (BOOL) blockSettingsHidden
{
    BOOL result = YES;
    
    if( [self.currentEditorView isEqualToString:@"Blocker View" ])
        result = NO;
    
    return result;
}

- (BOOL) blockSettingsEnabled
{
    Class blockerClass = NSClassFromString([self valueForKey:@"anaylizerKind"]);
    
    return [blockerClass blockerPopoverAccessoryViewNib] != nil;
 }

- (NSString *) title
{
    NSString *result = nil;
    
    if( [self.currentEditorView isEqualToString:@"Blocker View" ])
        result = [NSString stringWithFormat:@"%@ — %@", [NSClassFromString(self.anaylizerKind) blockerName], self.currentEditorView];
    else
        result = self.currentEditorView;
    
    return result;    
}

- (BOOL) editEnabled
{
    BOOL result = NO;
    
    if( self == [self.parentStream lastFilterAnayliser] )  
        result = YES;
    
    return result;
}


- (NSURL *)urlForCachedData
{
    NSURL *result;
    StAnaylizer *previousAnaylizer = [self.parentStream previousAnayliser:self];
    
    if( previousAnaylizer == nil )
    {   
        /* we are the first anaylizer, data is in source stream */
        if( self.parentStream.sourceURL != nil )
        {
            result = self.parentStream.sourceURL;
        }
        else {
            NSURL *tempfile = MakeTemporaryFile( @"org.macmess.streams.tempfile.XXXXXX" );
            [self.parentStream.sourceBlock.resultingData writeToURL:tempfile atomically:NO];
            result = tempfile;
        }
    }
    else
    {
        NSURL *tempfile = MakeTemporaryFile( @"org.macmess.streams.tempfile.XXXXXX" );
        [previousAnaylizer.resultingData writeToURL:tempfile atomically:NO];
        result = tempfile;
    }

    return result;
}

- (NSData *)resultingData
{
    return self.anaylizerObject.resultingData;
}

- (void) setResultingData:(NSMutableData *)inData andChangedIndexSet:(NSMutableIndexSet *)inIndexSet
{
#pragma unused(inData)
#pragma unused(inIndexSet)
    NSLog( @"StAnaylizer: it is an error set set the resulting data like this" );
    NSAssert(NO,@"StAnaylizer: it is an error set set the resulting data like this");
}

- (BOOL) streamEditedInRange:(NSRange)range
{
    NSIndexSet *changedIndexSet = [self editIndexSet];
    return [changedIndexSet intersectsIndexesInRange:range];
}

- (void)willTurnIntoFault
{
    self.anaylizerObject = nil;
    self.viewRange = nil;
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

- (void) postEdit:(NSData *)data range:(NSRange)range
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

- (void) suspendObservations
{
    [[self viewController] suspendObservations];
}

- (void) resumeObservations
{
    [[self viewController] resumeObservations];
    
}

- (IBAction)ConfigurableButton1:(id)sender
{
    if( [self.viewController respondsToSelector:@selector(ConfigurableButton1:)] )
    {
        [self.viewController ConfigurableButton1:(id)sender];
    }
}

- (IBAction)ConfigurableButton2:(id)sender
{
    if( [self.viewController respondsToSelector:@selector(ConfigurableButton2:)] )
    {
        [self.viewController ConfigurableButton2:(id)sender];
    }
}

- (NSString *) descriptiveText
{
    return [NSString stringWithFormat:@"Anaylizer Kind: %@, Current Editor View: %@, Pane Expanded: %@, Pane Height: %f, Source UTI: %@, Resulting UTI: %@, Options Dictionary: %@", self.anaylizerKind, self.currentEditorView, self.paneExpanded ? @"Yes" : @"No", self.anaylizerHeight, self.sourceUTI, self.resultingUTI, self.optionsDictionary];
}

+ (NSSet *)keyPathsForValuesAffectingTitle
{
    return [NSSet setWithObjects:@"anaylizerKind", @"currentEditorView", nil];
}

+ (NSSet *)keyPathsForValuesAffectingEditEnabled
{
    return [NSSet setWithObjects:@"parentStream", nil];
}

+ (NSSet *)keyPathsForValuesAffectingBlockSettingsHidden
{
    return [NSSet setWithObjects:@"currentEditorView", nil];
}

+ (NSSet *)keyPathsForValuesAffectingRemoveEnabled
{
    return [NSSet setWithObjects:@"parentStream.anaylizers", nil];
}

+ (NSSet *)keyPathsForValuesAffectingComputedAnaylizerHeight
{
    return [NSSet setWithObjects:@"anaylizerHeight", nil];
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
#pragma unused(stop)
         [ma addObject:[self subdataWithRange:range]];
     }];
    
    return [ma autorelease];
}

@end

NSURL *MakeTemporaryFile( NSString *pattern )
{
    NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:pattern];
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    int fileDescriptor = mkstemp(tempFileNameCString);
    close(fileDescriptor);
    NSString *tempFileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    free(tempFileNameCString);
    
    return [NSURL fileURLWithPath:tempFileName];
}

