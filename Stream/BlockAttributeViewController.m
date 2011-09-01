//
//  BlockAttributeViewController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockAttributeViewController.h"
#import "StBlock.h"

@implementation BlockAttributeViewController
@synthesize arrayController;

//@synthesize tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    StBlock *theBlock = representedObject;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *subBlocks = [theBlock.blocks sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    [arrayController addObjects:subBlocks];
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"org.macmess.stream.attribute"];
}

+ (NSString *)anayliserName
{
    return @"Block Attribute View";
}

/* Used for KVC and KVO in anaylizer options dictionary */
+ (NSString *)anaylizerKey;
{
    return @"BlockAttributeViewController";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"";
}

-(NSString *)nibName
{
    return @"BlockAttributeViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] init] autorelease];
}

@end
