//
//  DisassemblerAnalyzerViewController.m
//  Stream
//
//  Created by tim lindner on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DisassemblerAnalyzerViewController.h"
#import "DisassemblerAnalyzer.h"
#import "StAnalyzer.h"
#import "StBlock.h"
#import "StStream.h"

@interface DisassemblerAnalyzerViewController ()

@end

@implementation DisassemblerAnalyzerViewController

@synthesize textView;
@synthesize lastAnalyzer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) setRepresentedObject:(id)inRepresentedObject
{
    super.representedObject = inRepresentedObject;

    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[DisassemblerAnalyzer analyzerKey] withDictionary:[DisassemblerAnalyzer defaultOptions]];
    }
}

- (void) loadView
{
    [super loadView];
    [self reloadView];
}

- (void)reloadView
{
//    [self stopObserving];

    id ro = [self representedObject];

    [textView setUsesFontPanel:YES];
    [textView setRichText:NO];
    [textView setEditable:![[[self representedObject] valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.readOnly"] boolValue]];
    [textView setFont:[NSFont fontWithName:@"Monaco" size:12.0]];
    
    DisassemblerAnalyzer *modelObject = (DisassemblerAnalyzer *)[ro analyzerObject];
    [modelObject analyzeData];
    
    NSString *result = [[[NSString alloc] initWithData:modelObject.resultingData encoding:NSUnicodeStringEncoding] autorelease];
    
    if (result == nil || [result isEqualToString:@""]) {
        result = @"Unable to decode stream.";
    }

    [textView setString:result];
    [self startObserving];
 }

- (void)startObserving
{
    if (observationsActive) {
        [self stopObserving];
    }
    
    self.lastAnalyzer = [self representedObject];
    
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.directPageValue" options:0 context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.transferAddresses" options:0 context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetAddress" options:0 context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.support6309" options:0 context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showAddresses" options:0 context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showOS9" options:0 context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showHex" options:0 context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.followPC" options:0 context:self];
    
    observationsActive = YES;
}

- (void)stopObserving
{
    if (observationsActive) {
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.directPageValue" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.transferAddresses" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetAddress" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.support6309" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showAddresses" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showOS9" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showHex" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.followPC" context:self];
        self.lastAnalyzer = nil;
        observationsActive = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        if ([keyPath isEqualToString:@"optionsDictionary.DisassemblerAnalyzerViewController.transferAddresses"]) {
            [self reloadView];
        } else if ([keyPath isEqualToString:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetAddress"]) {
            [self reloadView];
        } else if ([keyPath isEqualToString:@"optionsDictionary.DisassemblerAnalyzerViewController.support6309"]) {
            [self reloadView];
        } else if ([keyPath isEqualToString:@"optionsDictionary.DisassemblerAnalyzerViewController.showAddresses"]) {
            [self reloadView];
        } else if ([keyPath isEqualToString:@"optionsDictionary.DisassemblerAnalyzerViewController.showOS9"]) {
            [self reloadView];
        } else if ([keyPath isEqualToString:@"optionsDictionary.DisassemblerAnalyzerViewController.showHex"]) {
            [self reloadView];
        } else if ([keyPath isEqualToString:@"optionsDictionary.DisassemblerAnalyzerViewController.followPC"]) {
            BOOL followPC = [[self.lastAnalyzer valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.followPC"] boolValue];
            [self.lastAnalyzer setValue:[NSNumber numberWithBool:followPC ] forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.transferAddressEnable"];
            [self reloadView];
        } else if ([keyPath isEqualToString:@"optionsDictionary.DisassemblerAnalyzerViewController.directPageValue"]) {
            [self reloadView];
        } else {
            NSLog( @"DisassemblerAnalyzerViewController: Unknown keypath for observerValueForKeyPath:ofObject:change:context: %@", keyPath );
        }    
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    [self stopObserving];
    self.lastAnalyzer = nil;
    
    [super dealloc];
}

- (void) suspendObservations
{
    [self stopObserving];
}

- (void) resumeObservations
{
    [self startObserving];
}

- (NSString *)nibName
{
    return @"DisassemblerAnalyzerViewController";
}

@end
