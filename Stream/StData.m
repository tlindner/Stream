//
//  StData.m
//  temp
//
//  Created by tim lindner on 5/7/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StData.h"
#import "Analyzation.h"
#import "HexFiendAnalyzer.h"
#import "TextAnalyzer.h"


@implementation StData

@dynamic resultingUTI;
@dynamic sourceUTI;
@dynamic analyzerKind;
@dynamic currentEditorView;
@dynamic readOnly;
@dynamic optionsDictionary;
@dynamic analyzerObject;
@dynamic viewController;
@dynamic resultingData;
@dynamic unionRange;
@dynamic errorString;

- (NSObject *)analyzerObject
{
    NSObject *_analyzerObject = [self primitiveAnalyzerObject];
    
    Class anaObjectClass = [[Analyzation sharedInstance] analyzerClassforName:self.currentEditorView];
    
    if( anaObjectClass == nil )
    {
        if ([self.sourceUTI isEqualToString:@"public.text"]) {
            anaObjectClass = [TextAnalyzer class];
        }
        else {
            anaObjectClass = [HexFiendAnalyzer class];
            [_analyzerObject analyzeData];
        }
    }
    
    if( _analyzerObject == nil )
    {
        _analyzerObject = [[[anaObjectClass alloc] init] autorelease];
        [_analyzerObject setRepresentedObject:self];
        [self setPrimitiveAnalyzerObject:_analyzerObject];
    }
    else if( ![[_analyzerObject class] isSubclassOfClass:[[Analyzation sharedInstance] analyzerClassforName:self.currentEditorView]] )
    {
        [_analyzerObject setRepresentedObject:nil];
        [self setPrimitiveAnalyzerObject:nil];
        
        _analyzerObject = [[[anaObjectClass alloc] init] autorelease];
        [_analyzerObject setRepresentedObject:self];
        [self setPrimitiveAnalyzerObject:_analyzerObject];
        [_analyzerObject analyzeData];
    }
    
    return _analyzerObject;
}

- (void) analyzeData
{
    [[self analyzerObject] analyzeData];
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
