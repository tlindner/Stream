//
//  StAnaylizer.m
//  Stream
//
//  Created by tim lindner on 8/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
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
    if( self.optionsDictionary == nil )
        self.optionsDictionary = [[[NSMutableDictionary alloc] init] autorelease];
    
    if( [self.optionsDictionary valueForKey:subOptionsID] == nil )
    {
       [self.optionsDictionary setObject:newOptions forKey:subOptionsID];
        return;
    }
    
    NSMutableDictionary *dict = [self.optionsDictionary objectForKey:subOptionsID];

    for (NSString *key in [newOptions allKeys])
    {
        id value = [dict objectForKey:key];
        
        if( value == nil )
            [dict setObject:[newOptions objectForKey:key] forKey:key];
    }
}
         
@end
