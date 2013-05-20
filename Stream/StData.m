//
//  StData.m
//  temp
//
//  Created by tim lindner on 5/7/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StData.h"
#import "Analyzation.h"
#import "HexFiendAnaylizer.h"
#import "TextAnaylizer.h"


@implementation StData

@dynamic resultingUTI;
@dynamic sourceUTI;
@dynamic anaylizerKind;
@dynamic currentEditorView;
@dynamic readOnly;
@dynamic optionsDictionary;
@dynamic anaylizerObject;
@dynamic viewController;
@dynamic resultingData;
@dynamic unionRange;
@dynamic errorString;

- (NSObject *)anaylizerObject
{
    NSObject *_anaylizerObject = [self primitiveAnaylizerObject];
    
    Class anaObjectClass = [[Analyzation sharedInstance] anaylizerClassforName:self.currentEditorView];
    
    if( anaObjectClass == nil )
    {
        if ([self.sourceUTI isEqualToString:@"public.text"]) {
            anaObjectClass = [TextAnaylizer class];
        }
        else {
            anaObjectClass = [HexFiendAnaylizer class];
        }
    }
    
    if( _anaylizerObject == nil )
    {
        _anaylizerObject = [[[anaObjectClass alloc] init] autorelease];
        [_anaylizerObject setRepresentedObject:self];
        [self setPrimitiveAnaylizerObject:_anaylizerObject];
    }
    else if( ![[_anaylizerObject class] isSubclassOfClass:[[Analyzation sharedInstance] anaylizerClassforName:self.currentEditorView]] )
    {
        [_anaylizerObject setRepresentedObject:nil];
        [self setPrimitiveAnaylizerObject:nil];
        
        _anaylizerObject = [[[anaObjectClass alloc] init] autorelease];
        [_anaylizerObject setRepresentedObject:self];
        [self setPrimitiveAnaylizerObject:_anaylizerObject];
    }
    
    return _anaylizerObject;
}

- (void) anaylizeData
{
    [[self anaylizerObject] anaylizeData];
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

@end
