//
//  TextAnalyzerViewController.m
//  Stream
//
//  Created by tim lindner on 4/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TextAnalyzerViewController.h"
#import "TextAnalyzer.h"
#import "StAnalyzer.h"
#import "StBlock.h"
#import "StStream.h"
#import "StData.h"

@interface TextAnalyzerViewController ()

@end

@implementation TextAnalyzerViewController
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

- (void) loadView
{
    [super loadView];
    [self reloadView];
}

- (void)reloadView
{
//    id ro = [self representedObject];

    [self stopObserving];
    
//    if( [ro respondsToSelector:@selector(sourceUTI)] )
//    {
//        NSString *uti = [ro sourceUTI];
//        if ([uti isEqualToString:@"com.microsoft.cocobasic.binary"]) {
//            [ro setValue:@"Tokenized CoCo BASIC Program" forKeyPath:@"optionsDictionary.TextAnalyzerViewController.encoding"];
//        }
//    }
    
    [textView setUsesFontPanel:YES];
    [textView setRichText:NO];
    [textView setEditable:![[[self representedObject] valueForKeyPath:@"optionsDictionary.TextAnalyzerViewController.readOnly"] boolValue]];
    BOOL fixedWidth = [[[self representedObject] valueForKeyPath:@"optionsDictionary.TextAnalyzerViewController.fixedWidthFont"] boolValue];
    NSFont *font;
    
    if (fixedWidth) {
        font = [NSFont fontWithName:@"Monaco" size:12.0];
    }
    else {
        font = [NSFont systemFontOfSize:12.0];
    }
    
    [textView setFont:font];
    [textView setString:[self transformInput]];
    [self startObserving];
}

- (NSString *)transformInput
{
    NSString *result = nil;
    StData *object = [self representedObject];
    TextAnalyzer *modelObject = (TextAnalyzer *)[object analyzerObject];
    
    [modelObject analyzeData];
    
    result = [[[NSString alloc] initWithData:modelObject.resultingData encoding:NSUnicodeStringEncoding] autorelease];

    if (result == nil || [result isEqualToString:@""]) {
        result = @"Unable to decode stream.";
    }
                          
    return result;
}

- (void)startObserving
{
    if (observationsActive) {
        [self stopObserving];
    }
    
    self.lastAnalyzer = [self representedObject];
    
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.wrapLines" options:NSKeyValueChangeSetting context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.overWriteMode" options:NSKeyValueChangeSetting context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.fixedWidthFont" options:NSKeyValueChangeSetting context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.encoding" options:NSKeyValueChangeSetting context:self];
    [self.lastAnalyzer addObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.readOnly" options:NSKeyValueChangeSetting context:self];
    observationsActive = YES;
}

- (void)stopObserving
{
    if (observationsActive) {
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.wrapLines" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.overWriteMode" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.fixedWidthFont" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.encoding" context:self];
        [self.lastAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.TextAnalyzerViewController.readOnly" context:self];
        self.lastAnalyzer = nil;
        observationsActive = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        if ([keyPath isEqualToString:@"optionsDictionary.TextAnalyzerViewController.wrapLines"]) {
            ;
        }
        else if ([keyPath isEqualToString:@"optionsDictionary.TextAnalyzerViewController.overWriteMode"]) {
            ;
        }
        else if ([keyPath isEqualToString:@"optionsDictionary.TextAnalyzerViewController.fixedWidthFont"]) {
            BOOL fixedWidth = [[[self representedObject] valueForKeyPath:@"optionsDictionary.TextAnalyzerViewController.fixedWidthFont"] boolValue];
            NSFont *font;
            
            if (fixedWidth) {
                font = [NSFont fontWithName:@"Monaco" size:12.0];
            }
            else {
                font = [NSFont systemFontOfSize:12.0];
            }
            
            [textView setFont:font];
        }
        else if ([keyPath isEqualToString:@"optionsDictionary.TextAnalyzerViewController.encoding"]) {
            [textView setString:[self transformInput]];
        }
        else if ([keyPath isEqualToString:@"optionsDictionary.TextAnalyzerViewController.readOnly"]) {
            BOOL editable = [[[self representedObject] valueForKeyPath:@"optionsDictionary.TextAnalyzerViewController.readOnly"] boolValue];
            [textView setEditable:!editable];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
    return @"TextAnalyzerViewController";
}

- (void)dealloc
{
    [self stopObserving];
    self.lastAnalyzer = nil;
    
    [super dealloc];
}
@end
