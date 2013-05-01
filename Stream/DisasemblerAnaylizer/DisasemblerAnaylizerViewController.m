//
//  DisasemblerAnaylizerViewController.m
//  Stream
//
//  Created by tim lindner on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DisasemblerAnaylizerViewController.h"
#import "DisasemblerAnaylizer.h"
#import "StAnaylizer.h"
#import "StBlock.h"
#import "StStream.h"

@interface DisasemblerAnaylizerViewController ()

@end

@implementation DisasemblerAnaylizerViewController

@synthesize textView;

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
        [inRepresentedObject addSubOptionsDictionary:[DisasemblerAnaylizer anaylizerKey] withDictionary:[DisasemblerAnaylizer defaultOptions]];
    }
}

- (void) loadView
{
    [super loadView];
    [self reloadView];
}

- (void)reloadView
{
    id ro = [self representedObject];

    if( [ro respondsToSelector:@selector(sourceUTI)] )
    {
        NSString *uti = [ro sourceUTI];
        if ([uti isEqualToString:@"com.microsoft.cocobasic.object"]) {
            NSNumber *transfterAddress = [ro getAttributeDatawithUIName:@"ML Exec Address"];
            [ro setValue:[NSMutableArray arrayWithObject:transfterAddress] forKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.transferAddresses"];
            NSNumber *offsetAddress = [ro getAttributeDatawithUIName:@"ML Load Address"];
            [ro setValue:offsetAddress forKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.offsetAddress"];
        }
    }
    
    [textView setUsesFontPanel:YES];
    [textView setRichText:NO];
    [textView setEditable:![[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.readOnly"] boolValue]];
    BOOL fixedWidth = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.fixedWidthFont"] boolValue];
    NSFont *font;
    
    if (fixedWidth) {
        font = [NSFont fontWithName:@"Monaco" size:12.0];
    }
    else {
        font = [NSFont systemFontOfSize:12.0];
    }
    
    [textView setFont:font];
    
    NSData *bytes;
    if( [ro isKindOfClass:[StAnaylizer class]] )
    {
        bytes = [[ro parentStream] valueForKey:@"bytesCache"];
    }
    else if( [ro isKindOfClass:[StBlock class]] )
    {
        bytes = [ro getData];
    }
    else if( [ro isKindOfClass:[NSData class]] )
    {
        bytes = ro;
    }
    
    DisasemblerAnaylizer *modelObject = (DisasemblerAnaylizer *)[ro anaylizerObject];
    [textView setString:[modelObject disasemble6809:bytes]];
 }

- (NSString *)nibName
{
    return @"DisasemblerAnaylizerViewController";
}

@end
