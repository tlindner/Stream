//
//  StAnaylizer.m
//  Stream
//
//  Created by tim lindner on 8/12/11.
//  Copyright (c) 2011 org.macmess. All rights reserved.
//

#import "StAnaylizer.h"

@implementation StAnaylizer
@dynamic anaylizerHeight;
@dynamic anaylizerKind;
@dynamic currentEditorView;
@dynamic optionsDictionary;
@dynamic parentStream;

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

@end
