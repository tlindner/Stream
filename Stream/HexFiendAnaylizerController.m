//
//  HexFiendAnaylizerController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendAnaylizerController.h"
#import "Analyzation.h"
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
    if( representedObject == nil )
    {
        if( observationsActive )
        {
            [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset"];
            [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"];
            [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"];
            
            observationsActive = NO;
        }
    }
    
    [super setRepresentedObject:representedObject];
}

- (void)loadView
{
    [super loadView];
    
    HFTextView *hexView = (HFTextView *)[self view];
    
    if( [[self representedObject] isKindOfClass:[StAnaylizer class]] )
    {
        StAnaylizer *object = [self representedObject];
        [hexView setData:[object.parentStream valueForKey:@"bytesCache"]];      
        [self setupRepresentedObject];
    }
    else if( [[self representedObject] isKindOfClass:[StBlock class]] )
    {
        StBlock *theBlock = [self representedObject];
        [theBlock addSubOptionsDictionary:[HexFiendAnaylizerController anaylizerKey] withDictionary:[HexFiendAnaylizerController defaultOptions]];
        NSData *theData = [theBlock getData];
        [hexView setData:theData];
        [self setupRepresentedObject];
    }
    else if( [[self representedObject] isKindOfClass:[NSData class]] )
    {
        NSData *theData = [self representedObject];
        [hexView setData:theData];
    }
    else
        NSLog( @"HexFiendAnaylizerController: Unknown type of represented object" );
}

- (void) setupRepresentedObject
{
    HFTextView *hexView = (HFTextView *)[self view];

    BOOL showOffset = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset"] boolValue];
    NSString *offsetBase = [[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"];
    
    if( showOffset )
    {
        lcRepresenter = [[[HFLineCountingRepresenter alloc] init] autorelease];
        [self setLineNumberFormatString:offsetBase];
        [[hexView controller] addRepresenter:lcRepresenter];
        [[hexView layoutRepresenter] addRepresenter:lcRepresenter];
    }

    BOOL overWriteMode = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"] boolValue];
    [[hexView controller] setInOverwriteMode:overWriteMode];
    
    [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset" options:NSKeyValueChangeSetting context:nil];
    [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase" options:NSKeyValueChangeSetting context:nil];
    [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode" options:NSKeyValueChangeSetting context:nil];

    observationsActive = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BOOL showOffset = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset"] boolValue];
    NSString *offsetBase = [[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"];
    BOOL overWriteMode = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"] boolValue];
    
    if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnaylizerController.showOffset"])
    {
        HFTextView *hexView = (HFTextView *)[self view];
        if( showOffset == YES && lcRepresenter == nil )
        {
            lcRepresenter = [[[HFLineCountingRepresenter alloc] init] autorelease];
            [self setLineNumberFormatString:offsetBase];
            [[hexView controller] addRepresenter:lcRepresenter];
            [[hexView layoutRepresenter] addRepresenter:lcRepresenter];
        }
        else if( showOffset == NO && lcRepresenter != nil )
        {
            [[hexView layoutRepresenter] removeRepresenter:lcRepresenter];
            [[hexView controller] removeRepresenter:lcRepresenter];
            lcRepresenter = nil;
        }
                
        return;
    }
    else if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"])
    {
        [self setLineNumberFormatString:offsetBase];
        return;
    }
    else if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"])
    {
        HFTextView *hexView = (HFTextView *)[self view];
        [[hexView controller] setInOverwriteMode:overWriteMode];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void) setLineNumberFormatString:(NSString *)inFormat
{
    if( lcRepresenter != nil )
    {
        if( [inFormat isEqualToString:@"Decimal"] )
        {
            [lcRepresenter setLineNumberFormat:HFLineNumberFormatDecimal];
        }
        else if( [inFormat isEqualToString:@"Hexadecimal"] )
        {
            [lcRepresenter setLineNumberFormat:HFLineNumberFormatHexadecimal];
        }
        else
            NSLog( @"HexFiendAnaylizerController: unknown offsetbase: %@", inFormat );
    }
}

- (void)dealloc
{
    if( observationsActive == YES )
    {
        [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset"];
        [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"];
        [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"];
        
        observationsActive = NO;
    }

    [super dealloc];
}

- (NSString *)nibName
{
    return @"HexFiendAnaylizerController";
}

@end
