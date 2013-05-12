//
//  TextAnaylizer.m
//  Stream
//
//  Created by tim lindner on 4/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TextAnaylizer.h"
#import "TextAnaylizerViewController.h"
#import "StData.h"

NSStringEncoding Convert_String_To_Encoding( NSString *inEncoding );

@implementation TextAnaylizer

@synthesize representedObject;

- (void) setRepresentedObject:(id)inRepresentedObject
{
    representedObject = inRepresentedObject;
    
    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[TextAnaylizer anaylizerKey] withDictionary:[TextAnaylizer defaultOptions]];
    }
}

- (NSString *)anaylizeData:(NSData *)bufferObject
{
    StData *object = [self representedObject];
    NSString *encodingStringRep = [object valueForKeyPath:@"optionsDictionary.TextAnaylizerViewController.encoding"];
    NSStringEncoding encoding = Convert_String_To_Encoding(encodingStringRep);
    NSString *result = [[[NSString alloc] initWithData:bufferObject encoding:encoding] autorelease];

    return result;
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(unsigned char *)byte
{
    NSLog( @"Text Anaylizer: Unimplemented: replaceBytesInRange: %@ withByte 0x%x", NSStringFromRange(range), *byte);
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObjects:@"public.text", nil];
}

+ (NSString *)anayliserName
{
    return @"Text Editor";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"TextAccessoryView";
}

- (Class)viewControllerClass
{
    return [TextAnaylizerViewController class];
}

+ (NSString *)anaylizerKey
{
    return @"TextAnaylizerViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"wrapLines", [NSNumber numberWithBool:YES], @"overWriteMode", [NSNumber numberWithBool:YES], @"fixedWidthFont", [NSMutableArray arrayWithObjects:@"UTF-8",@"US-ASCII",@"ISO-8859-1", @"macintosh", nil], @"encodingList", @"macintosh", @"encoding", [NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", nil] autorelease];
}

@end

NSStringEncoding Convert_String_To_Encoding( NSString *inEncoding )
{
    CFStringEncoding aEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)inEncoding);
    return CFStringConvertEncodingToNSStringEncoding(aEncoding);
}
