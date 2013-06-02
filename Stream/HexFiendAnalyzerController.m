//
//  HexFiendAnalyzerController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HexFiendAnalyzerController.h"
#import "HexFiendAnalyzer.h"
#import "Analyzation.h"
#import "HFTextView.h"
#import "StStream.h"
#import "StAnalyzer.h"
#import "StBlock.h"

@implementation HexFiendAnalyzerController

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
    if (self.representedObject != inRepresentedObject) {
        [self suspendObservations];
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
    HexFiendAnalyzer *modelObject = (HexFiendAnalyzer *)[[self representedObject] analyzerObject];
    [modelObject analyzeData];

    [[hexView controller] setInOverwriteMode:NO];
    
    [hexView setData:[modelObject resultingData]];
    
    BOOL overWriteMode = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.overWriteMode"] boolValue];
    [[hexView controller] setInOverwriteMode:overWriteMode];
    
    [self setupRepresentedObject];
}

- (void) setupRepresentedObject
{
    HFTextView *hexView = (HFTextView *)[self view];

    [self resumeObservations];
    BOOL showOffset = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.showOffset"] boolValue];
    BOOL readOnly = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.readOnly"] boolValue];
    NSString *offsetBase = [[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.offsetBase"];
    
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

    BOOL overWriteMode = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.overWriteMode"] boolValue];
    [[hexView controller] setInOverwriteMode:overWriteMode];
    [[hexView controller] setEditable:!readOnly];
//    [self setEditContentRanges];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    BOOL showOffset = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.showOffset"] boolValue];
    BOOL readOnly = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.readOnly"] boolValue];
    NSString *offsetBase = [[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.offsetBase"];
    BOOL overWriteMode = [[[self representedObject] valueForKeyPath:@"optionsDictionary.HexFiendAnalyzerController.overWriteMode"] boolValue];
    
    if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnalyzerController.showOffset"])
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
    else if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnalyzerController.offsetBase"])
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
        {
            [self setLineNumberFormatString:offsetBase];
        }
    }
    else if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnalyzerController.readOnly"])
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
        {
            HFTextView *hexView = (HFTextView *)[self view];
            [[hexView controller] setEditable:!readOnly];
        }
    }
    else if ([keyPath isEqualToString:@"optionsDictionary.HexFiendAnalyzerController.overWriteMode"])
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
            if( [[self representedObject] isKindOfClass:[StAnalyzer class]] )
            {
                NSAssert(YES==NO, @"StAnalyzer: data: not implemented yet");
//                StAnalyzer *object = [self representedObject];
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
                NSLog( @"HexFiendAnalyzerController: Unknown type of represented object" );
        }
    }
    else if( [keyPath isEqualToString:@"editIndexSet"] )
    {
        if( [[self representedObject] isKindOfClass:[StAnalyzer class]] )
        {
            NSAssert(YES==NO, @"StAnalyzer: editIndexSet: not implemented yet");
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
            NSLog( @"HexFiendAnalyzerController: editIndexSet: Unknown type of represented object" );
        
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) setEditContentRanges
{
    if( [[self representedObject] isKindOfClass:[StAnalyzer class]] )
    {
        NSLog( @"HexFiendAnalyzerController: setEditContentRanges: StAnalyzer unimplemented" );
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
        NSLog( @"HexFiendAnalyzerController: setEditContentRanges: unknown represented object class" );
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
            NSLog( @"HexFiendAnalyzerController: unknown offsetbase: %@", inFormat );
    }
}

- (void)dealloc
{
    [self suspendObservations];
    [super dealloc];
}

- (void) suspendObservations
{
    if( observationsActive == YES )
    {
        StAnalyzer *theAna = [self representedObject];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnalyzerController.readOnly"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnalyzerController.showOffset"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnalyzerController.offsetBase"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.HexFiendAnalyzerController.overWriteMode"];

        HFTextView *hexView = (HFTextView *)[self view];
        [hexView removeObserver:self forKeyPath:@"data"];
        
        observationsActive = NO;
    }
}

- (void) resumeObservations
{
    if( observationsActive == NO )
    {
        [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnalyzerController.readOnly" options:NSKeyValueChangeSetting context:nil];
        [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnalyzerController.showOffset" options:NSKeyValueChangeSetting context:nil];
        [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnalyzerController.offsetBase" options:NSKeyValueChangeSetting context:nil];
        [[self representedObject] addObserver:self forKeyPath:@"optionsDictionary.HexFiendAnalyzerController.overWriteMode" options:NSKeyValueChangeSetting context:nil];

        HFTextView *hexView = (HFTextView *)[self view];
        [hexView addObserver:self forKeyPath:@"data" options:NSKeyValueChangeReplacement context:nil];
        
        observationsActive = YES;
    }
}

- (NSString *)nibName
{
    return @"HexFiendAnalyzerController";
}

@end
