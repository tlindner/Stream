//
//  BlockerDataAnaylizer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerDataAnaylizer.h"
#import "BlockerDataViewController.h"

@implementation BlockerDataAnaylizer

@dynamic representedObject;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (StAnaylizer *)representedObject
{
    return representedObject;
}

- (void) setRepresentedObject:(StAnaylizer *)inRepresentedObject
{
    representedObject = inRepresentedObject;
    StAnaylizer *theAna = inRepresentedObject;
    
    if( theAna != nil )
    {
        [theAna addSubOptionsDictionary:[BlockerDataAnaylizer anaylizerKey] withDictionary:[BlockerDataAnaylizer defaultOptions]];
    }
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"org.macmess.stream.block"];
}

+ (NSString *)anayliserName
{
    return @"Blocker View";
}

+ (NSString *)anaylizerKey
{
    return @"BlockerDataViewController";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
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

@end
