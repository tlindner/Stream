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

NSStringEncoding Convert_String_To_Encoding( NSString *inEncoding );

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

- (void)loadView
{
    [super loadView];
    
    id ro = [self representedObject];
    
    if( [ro respondsToSelector:@selector(sourceUTI)] )
    {
        NSString *uti = [ro sourceUTI];
        if ([uti isEqualToString:@"com.microsoft.cocobasic.binary"]) {
            [ro setValue:@"Tokenized Color Computer BASIC Program" forKeyPath:@"optionsDictionary.TextAnaylizerViewController.encoding"];
        }
    }
    
    NSString *string = [self transformInput];
    [textView insertText:string];
}

- (NSString *)transformInput
{
    NSString *result = nil;
    id object = [self representedObject];
    NSData *bytes = nil;
    NSString *encodingStringRep = [object valueForKeyPath:@"optionsDictionary.TextAnaylizerViewController.encoding"];
    NSStringEncoding encoding = Convert_String_To_Encoding(encodingStringRep);
    
    if( [object isKindOfClass:[StAnaylizer class]] )
    {
        bytes = [[object parentStream] valueForKey:@"bytesCache"];
    }
    else if( [object isKindOfClass:[StBlock class]] )
    {
        bytes = [object getData];
    }
    else if( [object isKindOfClass:[NSData class]] )
    {
        // Nothing to do.
    }

    if (bytes != nil) {
        if (encoding != 0xFFFFFFFF) {
            /* The system can decode this */
            result = [[[NSString alloc] initWithData:bytes encoding:encoding] autorelease];
        }
        else if ([encodingStringRep isEqualToString:@"Tokenized Color Computer BASIC Program"]) {
            TextAnaylizer *modelObject = (TextAnaylizer *)[object anaylizerObject];
            result = [modelObject decodeColorComputerBASIC:bytes];
        }
    }

    if (result == nil || [result isEqualToString:@""]) {
        result = @"Unable to decode stream.";
    }
                          
    return result;
}

- (NSString *)nibName
{
    return @"TextAnaylizerViewController";
}

- (void)dealloc
{
    self.lastAnaylizer = nil;
    
    [super dealloc];
}
@end

NSStringEncoding Convert_String_To_Encoding( NSString *inEncoding )
{
    CFStringEncoding aEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)inEncoding);
    return CFStringConvertEncodingToNSStringEncoding(aEncoding);
}
