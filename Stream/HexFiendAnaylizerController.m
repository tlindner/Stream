//
//  HexFiendAnaylizerController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendAnaylizerController.h"
#import "HFTextView.h"
#import "StAnaylizer.h"
#import "StBlock.h"

@implementation HexFiendAnaylizerController

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
    HFTextView *hexView = (HFTextView *)[self view];
    
    if( [representedObject isKindOfClass:[StAnaylizer class]] )
    {
        StAnaylizer *object = representedObject;
        [hexView setData:[object.parentStream valueForKey:@"bytesCache"]];      
        
        if( [[object valueForKey:@"initializedOD"] boolValue] == YES )
        {
        }
        else
        {
        }
    }
    else if( [representedObject isKindOfClass:[StBlock class]] )
    {
        StBlock *theBlock = representedObject;
        NSData *theData = [theBlock getData];
        [hexView setData:theData];
    }
    else if( [representedObject isKindOfClass:[NSData class]] )
    {
        NSData *theData = representedObject;
        [hexView setData:theData];
    }
    else
        NSLog( @"HexFiendAnaylizerController: Unknown type of represented object" );
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.data"];
}

+ (NSString *)anayliserName
{
    return @"Hex Editor";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"HFAccessoryView";
}

- (NSString *)nibName
{
    return @"HexFiendAnaylizerController";
}

+ (NSString *)anaylizerKey;
{
    return @"HexFiendAnaylizerController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"showOffset", nil] autorelease];
}

@end
