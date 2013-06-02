//
//  StAnalyzer.m
//  temp
//
//  Created by tim lindner on 5/7/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StAnalyzer.h"
#import "AnalyzerEdit.h"
#import "StStream.h"
#import "Analyzation.h"
#import "HexFiendAnalyzer.h"
#import "TextAnalyzer.h"
#import "Blockers.h"

NSURL *MakeTemporaryFile( NSString *pattern );

@implementation StAnalyzer

@dynamic analyzerHeight;
@dynamic analyzerKind;
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

+ (void)initialize
{
    if ( self == [StAnalyzer class] )
    {
        // Setup standard value transformers
		streamLockValueTransformer *slvt;
		slvt = [[[streamLockValueTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:slvt forName:@"streamLockValueTransformer"];		
    }
}

+ (NSSet *)keyPathsForValuesAffectingAnalyzerObject
{
    return [NSSet setWithObjects:@"currentEditorView", nil];
}

- (float) computedAnalyzerHeight
{
    if( self.paneExpanded == NO )
        return 26.0;
    else
        return self.analyzerHeight;
}

- (void) writebyte:(unsigned char)byte atOffset:(NSUInteger)offset
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:offset];
    NSRange range = NSMakeRange(offset, 1);
    
    /* make sure model object is listening */
    [self analyzerObject];
    
    /* change byte in KVO approved ay */
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"resultingData"];
    [self.analyzerObject replaceBytesInRange:range withBytes:&byte];
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
    
    StAnalyzer *previousAna = [self.parentStream previousAnalyzer:self];
    
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
    
    NSOrderedSet *streamSet = self.parentStream.analyzers;
    NSUInteger indexOfMe = [streamSet indexOfObject:self];
    
    if( indexOfMe == 0 )
        result = NO;
    else if ( indexOfMe == ([streamSet count] - 1) )
        result = YES;
    
    return result;
}

- (void) setSourceUTI:(NSString *)parentUTI
{
    StAnalyzer *previousAna = [self.parentStream previousAnalyzer:self];
    
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
    Class blockerClass = NSClassFromString([self valueForKey:@"analyzerKind"]);
    
    return [blockerClass blockerPopoverAccessoryViewNib] != nil;
 }

- (NSString *) title
{
    NSString *result = nil;
    
    if( [self.currentEditorView isEqualToString:@"Blocker View" ])
        result = [NSString stringWithFormat:@"%@ — %@", [NSClassFromString(self.analyzerKind) blockerName], self.currentEditorView];
    else
        result = self.currentEditorView;
    
    return result;    
}

- (BOOL) editEnabled
{
    BOOL result = NO;
    
    if( self == [self.parentStream lastFilterAnalyzer] )
        result = YES;
    
    return result;
}


- (NSURL *)urlForCachedData
{
    NSURL *result;
    StAnalyzer *previousAnalyzer = [self.parentStream previousAnalyzer:self];
    
    if( previousAnalyzer == nil )
    {   
        /* we are the first analyzer, data is in source stream */
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
        [previousAnalyzer.resultingData writeToURL:tempfile atomically:NO];
        result = tempfile;
    }

    return result;
}

- (NSData *)resultingData
{
    NSData *result;
    
    result = [self primitiveResultingData];
    
    if (result == nil) {
        StAnalyzer *previousAnalyzer = [self.parentStream previousAnalyzer:self];
        
        if( previousAnalyzer == nil )
        {   
            /* we are the first analyzer, data is in source stream */
            if( self.parentStream.sourceURL != nil )
            {
                result = [NSData dataWithContentsOfURL: self.parentStream.sourceURL];
            }
            else {
                result = self.parentStream.sourceBlock.resultingData;
            }
        }
        else
        {
            result = previousAnalyzer.analyzerObject.resultingData;
        }
        
        [self setPrimitiveResultingData:result];
    }
    
    return result;
}

- (void) setResultingData:(NSMutableData *)inData andChangedIndexSet:(NSMutableIndexSet *)inIndexSet
{
#pragma unused(inData)
#pragma unused(inIndexSet)
    NSLog( @"StAnalyzer: it is an error set set the resulting data like this" );
    NSAssert(NO,@"StAnalyzer: it is an error set set the resulting data like this");
}

- (BOOL) streamEditedInRange:(NSRange)range
{
    NSIndexSet *changedIndexSet = [self editIndexSet];
    return [changedIndexSet intersectsIndexesInRange:range];
}

- (void)willTurnIntoFault
{
    self.analyzerObject = nil;
    self.viewRange = nil;
}

- (BOOL) canChangeEditor
{
    BOOL result;
    
    result = ( self == [[[self parentStream] analyzers] lastObject] );
    
    return result;
}

- (StAnalyzer *)previousAnalyzer
{
    return [[self parentStream] previousAnalyzer:self];
}

- (void) postEdit:(NSData *)data range:(NSRange)range
{
    [self postEdit:data atLocation:range.location withLength:range.length];
}

- (void) postEdit: (NSData *)data atLocation: (int64_t)location withLength: (int64_t)length
{
    AnalyzerEdit *previousEdit = [[self edits] lastObject];
    
    if( previousEdit.location == location && previousEdit.length == length && [previousEdit.data length] == [data length] )
    {
        /* This edit replaced last edit */
        previousEdit.data = data;        
    }
    else
    {
        AnalyzerEdit *theEdit = [NSEntityDescription insertNewObjectForEntityForName:@"AnalyzerEdit" inManagedObjectContext:[self managedObjectContext]];
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
    return [NSString stringWithFormat:@"Analyzer Kind: %@, Current Editor View: %@, Pane Expanded: %@, Pane Height: %f, Source UTI: %@, Resulting UTI: %@, Options Dictionary: %@", self.analyzerKind, self.currentEditorView, self.paneExpanded ? @"Yes" : @"No", self.analyzerHeight, self.sourceUTI, self.resultingUTI, self.optionsDictionary];
}

+ (NSSet *)keyPathsForValuesAffectingTitle
{
    return [NSSet setWithObjects:@"analyzerKind", @"currentEditorView", nil];
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
    return [NSSet setWithObjects:@"parentStream.analyzers", nil];
}

+ (NSSet *)keyPathsForValuesAffectingComputedAnalyzerHeight
{
    return [NSSet setWithObjects:@"analyzerHeight", nil];
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

