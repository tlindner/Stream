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


@end
