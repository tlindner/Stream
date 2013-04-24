//
//  HexFiendAnaylizer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendAnaylizer.h"
#import "HexFiendAnaylizerController.h"
#import "StAnaylizer.h"

@implementation HexFiendAnaylizer

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
    
    if( inRepresentedObject != nil )
    {
        [theAna addSubOptionsDictionary:[HexFiendAnaylizer anaylizerKey] withDictionary:[HexFiendAnaylizer defaultOptions]];
        
        if( observationsActive == NO )
        {
//            [theAna addObserver:self forKeyPath:@"resultingData" options:NSKeyValueChangeReplacement context:nil];
            observationsActive = YES;
        }
    }
    else
    {
        if( observationsActive == YES )
        {
//            [theAna removeObserver:self forKeyPath:@"resultingData"];
            observationsActive = NO;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"ObserveValueForKeyPath: %@\nofObject: %@\nchange: %@\ncontext: %p", keyPath, object, change, context);

    if( [keyPath isEqualToString:@"resultingData"] )
    {
        NSUInteger kind = [[change objectForKey:@"kind"] unsignedIntegerValue];
        if( kind == NSKeyValueChangeReplacement )
        {
            if( [[self representedObject] isKindOfClass:[StAnaylizer class]] )
            {
                NSLog( @"HexFiendAnaylizer observeValueForKeyPath: resultingData: StAnaylizer object type unimplemented" );
            }
            else if( [[self representedObject] isKindOfClass:[StBlock class]] )
            {
                NSLog( @"HexFiendAnaylizer observeValueForKeyPath: resultingData: StBlock object type unimplemented" );
            }
            else
            {
                NSLog( @"HexFiendAnaylizer observeValueForKeyPath: resultingData: unknown represented object type" );
            }
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc
{
    StAnaylizer *theAna = representedObject;

    if( theAna != nil && observationsActive == YES )
    {
//        [theAna removeObserver:self forKeyPath:@"resultingData"];
        observationsActive = NO;
    }

    [super dealloc];
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

- (Class)viewControllerClass
{
    return [HexFiendAnaylizerController class];
}

+ (NSString *)anaylizerKey;
{
    return @"HexFiendAnaylizerController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"showOffset", @"Hexadecimal", @"offsetBase",[NSArray arrayWithObjects:@"Hexadecimal", @"Decimal", nil], @"offsetBaseOptions", [NSNumber numberWithBool:YES], @"overWriteMode", nil] autorelease];
}


@end
