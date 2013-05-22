//
//  TextAnaylizerViewController.m
//  Stream
//
//  Created by tim lindner on 4/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TextAnaylizerViewController.h"
#import "TextAnaylizer.h"
#import "StAnaylizer.h"
#import "StBlock.h"
#import "StStream.h"
#import "StData.h"

@interface TextAnaylizerViewController ()

@end

@implementation TextAnaylizerViewController
@synthesize textView;
@synthesize lastAnaylizer;

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
//            [ro setValue:@"Tokenized CoCo BASIC Program" forKeyPath:@"optionsDictionary.TextAnaylizerViewController.encoding"];
//        }
//    }
    
    [textView setUsesFontPanel:YES];
    [textView setRichText:NO];
    [textView setEditable:![[[self representedObject] valueForKeyPath:@"optionsDictionary.TextAnaylizerViewController.readOnly"] boolValue]];
    BOOL fixedWidth = [[[self representedObject] valueForKeyPath:@"optionsDictionary.TextAnaylizerViewController.fixedWidthFont"] boolValue];
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
    TextAnaylizer *modelObject = (TextAnaylizer *)[object anaylizerObject];
    
    [modelObject anaylizeData];
    
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
    
    self.lastAnaylizer = [self representedObject];
    
    [self.lastAnaylizer addObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.wrapLines" options:NSKeyValueChangeSetting context:self];
    [self.lastAnaylizer addObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.overWriteMode" options:NSKeyValueChangeSetting context:self];
    [self.lastAnaylizer addObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.fixedWidthFont" options:NSKeyValueChangeSetting context:self];
    [self.lastAnaylizer addObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.encoding" options:NSKeyValueChangeSetting context:self];
    [self.lastAnaylizer addObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.readOnly" options:NSKeyValueChangeSetting context:self];
    observationsActive = YES;
}

- (void)stopObserving
{
    if (observationsActive) {
        [self.lastAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.wrapLines" context:self];
        [self.lastAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.overWriteMode" context:self];
        [self.lastAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.fixedWidthFont" context:self];
        [self.lastAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.encoding" context:self];
        [self.lastAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.TextAnaylizerViewController.readOnly" context:self];
        self.lastAnaylizer = nil;
        observationsActive = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
        if ([keyPath isEqualToString:@"optionsDictionary.TextAnaylizerViewController.wrapLines"]) {
            ;
        }
        else if ([keyPath isEqualToString:@"optionsDictionary.TextAnaylizerViewController.overWriteMode"]) {
            ;
        }
        else if ([keyPath isEqualToString:@"optionsDictionary.TextAnaylizerViewController.fixedWidthFont"]) {
            BOOL fixedWidth = [[[self representedObject] valueForKeyPath:@"optionsDictionary.TextAnaylizerViewController.fixedWidthFont"] boolValue];
            NSFont *font;
            
            if (fixedWidth) {
                font = [NSFont fontWithName:@"Monaco" size:12.0];
            }
            else {
                font = [NSFont systemFontOfSize:12.0];
            }
            
            [textView setFont:font];
        }
        else if ([keyPath isEqualToString:@"optionsDictionary.TextAnaylizerViewController.encoding"]) {
            [textView setString:[self transformInput]];
        }
        else if ([keyPath isEqualToString:@"optionsDictionary.TextAnaylizerViewController.readOnly"]) {
            BOOL editable = [[[self representedObject] valueForKeyPath:@"optionsDictionary.TextAnaylizerViewController.readOnly"] boolValue];
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
    return @"TextAnaylizerViewController";
}

- (void)dealloc
{
    [self stopObserving];
    self.lastAnaylizer = nil;
    
    [super dealloc];
}
@end
