//
//  StAnaylizer.m
//  Stream
//
//  Created by tim lindner on 8/12/11.
//  Copyright (c) 2011 org.macmess. All rights reserved.
//

#import "StAnaylizer.h"
#import "StStream.h"

@implementation StAnaylizer

@dynamic anaylizerHeight;
@dynamic anaylizerKind;
@dynamic currentEditorView;
@dynamic optionsDictionary;
@dynamic parentStream;
@dynamic resultingData;
@dynamic sourceUTI;
@dynamic resultingUTI;
@dynamic previousAnaylizerHeight;
@dynamic collapse;
@dynamic removeEnabled;
@dynamic blockSettingsHidden;

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

- (void)awakeFromInsert
{
    self.optionsDictionary = [[[NSMutableDictionary alloc] init] autorelease];
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

- (BOOL) removeEnabled
{
    BOOL result = NO;
    
    NSOrderedSet *streamSet = self.parentStream.anaylizers;
    NSUInteger indexOfMe = [streamSet indexOfObject:self];
    
    if( indexOfMe == 0 )
        result = NO;
    else if ( indexOfMe == ([streamSet count] - 1) )
        result = YES;
    else
        result = NO;
    
    return result;
}

- (BOOL) blockSettingsHidden
{
    BOOL result = YES;
    
    if( [self.currentEditorView isEqualToString:@"Blocker View" ])
        result = NO;
    
    return result;
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
