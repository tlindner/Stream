//
//  HexFiendAnaylizerController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendAnaylizerController.h"
#import "HexFiendAnaylizer.h"
#import "Analyzation.h"
#import "HFTextView.h"
#import "StStream.h"
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

- (void)setRepresentedObject:(id)inRepresentedObject
{
    if( observationsActive )
    {
        StAnaylizer *theAna = [self representedObject];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.readOnly"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"];
        if( lastAnaylizer != nil )
        {
            [lastAnaylizer removeObserver:self forKeyPath:@"editIndexSet"];
            [lastAnaylizer release];
            lastAnaylizer = nil;
        }
        
        HFTextView *hexView = (HFTextView *)[self view];
        [hexView removeObserver:self forKeyPath:@"data"];
        
        observationsActive = NO;
    }

    [super setRepresentedObject:inRepresentedObject];
}

- (void)loadView
{
    [super loadView];
    [self reloadView];
}

- (void) reloadView
{
    HFTextView *hexView = (HFTextView *)[self view];
    HexFiendAnaylizer *modelObject = (HexFiendAnaylizer *)[[self representedObject] anaylizerObject];
   
    if( [[self representedObject] isKindOfClass:[StAnaylizer class]] )
    {
        StAnaylizer *object = [self representedObject];
        [[hexView controller] setInOverwriteMode:NO];
        [hexView setData:[modelObject anaylizeData:object.sourceData]];
        [self setupRepresentedObject];
    }
    else if( [[self representedObject] isKindOfClass:[StBlock class]] )
    {
        StBlock *theBlock = [self representedObject];
        lastAnaylizer = [[[theBlock getStream] lastFilterAnayliser] retain];
        NSData *theData = [theBlock resultingData];
        [[hexView controller] setInOverwriteMode:NO];
        [hexView setData:[modelObject anaylizeData:theData]];
        [self setupRepresentedObject];
    }
    else if( [[self representedObject] isKindOfClass:[NSData class]] )
    {
        NSData *theData = [self representedObject];
        [[hexView controller] setInOverwriteMode:NO];
        [hexView setData:theData];
    }
    else
        NSLog( @"HexFiendAnaylizerController: Unknown type of represented object" );
}

- (void) setupRepresentedObject
{
    HFTextView *hexView = (HFTextView *)[self view];

    BOOL showOffset = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset"] boolValue];
    BOOL readOnly = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.readOnly"] boolValue];
    NSString *offsetBase = [[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"];
    
    if( showOffset == YES && lcRepresenter == nil )
    {
        lcRepresenter = [[[HFLineCountingRepresenter alloc] init] autorelease];
        [[hexView controller] addRepresenter:lcRepresenter];
        [[hexView layoutRepresenter] addRepresenter:lcRepresenter];
        [[hexView controller] setUndoManager:[[[self representedObject] managedObjectContext] undoManager]];
    }
    else if( showOffset == NO && lcRepresenter != nil )
    {
        [[hexView layoutRepresenter] removeRepresenter:lcRepresenter];
        [[hexView controller] removeRepresenter:lcRepresenter];
        lcRepresenter = nil;
    }

    [self setLineNumberFormatString:offsetBase];

    BOOL overWriteMode = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"] boolValue];
    [[hexView controller] setInOverwriteMode:overWriteMode];
    [[hexView controller] setEditable:!readOnly];
    [self setEditContentRanges];
    
    NSAssert(observationsActive == NO, @"HexFieldAnaylizerController: double observer fault");
    
    [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.readOnly" options:NSKeyValueChangeSetting context:nil];
    [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset" options:NSKeyValueChangeSetting context:nil];
    [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase" options:NSKeyValueChangeSetting context:nil];
    [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode" options:NSKeyValueChangeSetting context:nil];
    
    if( lastAnaylizer != nil )
        [lastAnaylizer addObserver:self forKeyPath:@"editIndexSet" options:NSKeyValueChangeSetting context:nil];
    
    [hexView addObserver:self forKeyPath:@"data" options:NSKeyValueChangeReplacement context:nil];
    
    observationsActive = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BOOL showOffset = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset"] boolValue];
    BOOL readOnly = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.readOnly"] boolValue];
    NSString *offsetBase = [[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"];
    BOOL overWriteMode = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"] boolValue];
    
    if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnaylizerController.showOffset"])
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
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
        }
    }
    else if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"])
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
        {
            [self setLineNumberFormatString:offsetBase];
        }
    }
    else if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnaylizerController.readOnly"])
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
        {
            HFTextView *hexView = (HFTextView *)[self view];
            [[hexView controller] setEditable:!readOnly];
        }
    }
    else if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"])
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
        {
            HFTextView *hexView = (HFTextView *)[self view];
            [[hexView controller] setInOverwriteMode:overWriteMode];
        }
    }
    else if( [keyPath isEqualToString:@"data"] )
    {
        //NSLog(@"ObserveValueForKeyPath: %@\nofObject: %@\nchange: %@\ncontext: %p", keyPath, object, change, context);
        NSIndexSet *changes = [change objectForKey:@"indexes"];
        NSUInteger kind = [[change objectForKey:@"kind"] intValue];
        
        if( kind == NSKeyValueChangeReplacement && changes != nil)
        {
            if( [[self representedObject] isKindOfClass:[StAnaylizer class]] )
            {
                NSAssert(YES==NO, @"StAnayliser: data: not implemented yet");
//                StAnaylizer *object = [self representedObject];
//                [hexView setData:[object.parentStream valueForKey:@"bytesCache"]];      
//                [self setupRepresentedObject];
            }
            else if( [[self representedObject] isKindOfClass:[StBlock class]] )
            {
                StBlock *theBlock = [self representedObject];
                if( ! ( [[[theBlock managedObjectContext] undoManager] isUndoing] || [[[theBlock managedObjectContext] undoManager] isRedoing] ) )
                {
                    StStream *theStream = [theBlock getStream];
                    HFTextView *hexView = (HFTextView *)[self view];
                    
                    [changes enumerateRangesUsingBlock: ^(NSRange range, BOOL *stop)
                     {
                         #pragma unused(stop)
                         NSLog( @"Calling set block: %@", NSStringFromRange(range) );
                         [theStream setBlock:theBlock withData:[hexView data] inRange:range];
                     }];
                }
            }
            else if( [[self representedObject] isKindOfClass:[NSData class]] )
            {
                NSAssert(YES==NO, @"NSData: not implemented yet");
            }
            else
                NSLog( @"HexFiendAnaylizerController: Unknown type of represented object" );
        }
    }
    else if( [keyPath isEqualToString:@"editIndexSet"] )
    {
        if( [[self representedObject] isKindOfClass:[StAnaylizer class]] )
        {
            NSAssert(YES==NO, @"StAnayliser: editIndexSet: not implemented yet");
        }
        else if( [[self representedObject] isKindOfClass:[StBlock class]] )
        {
            [self setEditContentRanges];
        }
        else if( [[self representedObject] isKindOfClass:[NSData class]] )
        {
            NSAssert(YES==NO, @"NSData: editIndexSet: not implemented yet");
        }
        else
            NSLog( @"HexFiendAnaylizerController: editIndexSet: Unknown type of represented object" );
        
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) setEditContentRanges
{
    if( [[self representedObject] isKindOfClass:[StAnaylizer class]] )
    {
        NSLog( @"HexFiendAnaylizerController: setEditContentRanges: StAnaylizer unimplemented" );
    }
    else if( [[self representedObject] isKindOfClass:[StBlock class]] )
    {
        StBlock *theBlock = [self representedObject];
        HFTextView *hexView = (HFTextView *)[self view];
        NSMutableArray *editRanges = [[NSMutableArray alloc] init];
        NSIndexSet *theEditSet = [theBlock editSet];
        
        [theEditSet enumerateRangesUsingBlock:
         ^(NSRange range, BOOL *stop)
         {
             #pragma unused(stop)
             [editRanges addObject:[NSValue valueWithRange:range]];
         }];
        
        [[hexView controller] setEditContentsRanges:editRanges];
        [editRanges release];
    }
    else
        NSLog( @"HexFiendAnaylizerController: setEditContentRanges: unknown represented object class" );
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
    StAnaylizer *theAna = [self representedObject];
//    theAna.viewController = nil;

    if( observationsActive == YES )
    {
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.readOnly"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.showOffset"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.offsetBase"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnaylizerController.overWriteMode"];

        if( lastAnaylizer != nil )
        {
            [lastAnaylizer removeObserver:self forKeyPath:@"editIndexSet"];
            [lastAnaylizer release];
            lastAnaylizer = nil;
        }
        
        HFTextView *hexView = (HFTextView *)[self view];
        [hexView removeObserver:self forKeyPath:@"data"];
        
        observationsActive = NO;
    }

    [super dealloc];
}

- (NSString *)nibName
{
    return @"HexFiendAnaylizerController";
}

@end
