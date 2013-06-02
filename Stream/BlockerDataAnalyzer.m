//
//  BlockerDataAnalyzer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerDataAnalyzer.h"
#import "BlockerDataViewController.h"

@implementation BlockerDataAnalyzer

@dynamic representedObject;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (StAnalyzer *)representedObject
{
    return representedObject;
}

- (void) setRepresentedObject:(StAnalyzer *)inRepresentedObject
{
    representedObject = inRepresentedObject;
    StAnalyzer *theAna = inRepresentedObject;
    
    if( theAna != nil )
    {
        [theAna addSubOptionsDictionary:[BlockerDataAnalyzer analyzerKey] withDictionary:[BlockerDataAnalyzer defaultOptions]];
    }
}

+ (NSArray *)analyzerUTIs
{
    return [NSArray arrayWithObject:@"org.macmess.stream.block"];
}

+ (NSString *)analyzerName
{
    return @"Blocker View";
}

+ (NSString *)analyzerKey
{
    return @"BlockerDataViewController";
}

+ (NSString *)AnalyzerPopoverAccessoryViewNib
{
    return @"BlockerViewAccessory";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"initializedOD", nil] autorelease];
}

- (Class)viewControllerClass
{
    return [BlockerDataViewController class];
}

- (NSData *)resultingData
{
    return nil;
}

- (void) analyzeData
{
    /* Nothing to do */
}

@end
