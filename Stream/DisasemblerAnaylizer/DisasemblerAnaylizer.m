//
//  DisasemblerAnaylizer.m
//  Stream
//
//  Created by tim lindner on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DisasemblerAnaylizer.h"
#import "DisasemblerAnaylizerViewController.h"

unsigned char *memory = NULL;
#define OPCODE(address)  memory[address&0xffff]
#define ARGBYTE(address) memory[address&0xffff]
#define ARGWORD(address) (word)((memory[address&0xffff]<<8)|memory[(address+1)&0xffff])
#include "dasm09.h"

@implementation DisasemblerAnaylizer

@synthesize representedObject;

- (void) setRepresentedObject:(id)inRepresentedObject
{
    representedObject = inRepresentedObject;
    
    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[DisasemblerAnaylizer anaylizerKey] withDictionary:[DisasemblerAnaylizer defaultOptions]];
    }
}

- (NSString *)disasemble6809:(NSData *)bufferObject
{
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    memory = calloc(0x10000, 1);
//    NSPointerArray *pa = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality | NSPointerFunctionsCopyIn];
    NSPointerArray *pa = [NSPointerArray pointerArrayWithStrongObjects];
    [pa setCount:0x10000];
    
    unsigned int pc = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.transferAddress"] intValue];
    unsigned int offsetAddress = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.offsetAddress"] intValue];
    pc &= 0xffff;
    offsetAddress &= 0xffff;
    const unsigned char *bufferBytes = [bufferObject bytes];
    NSUInteger length = [bufferObject length];
    NSUInteger lengthToCopy = MIN( length, 0x10000-offsetAddress );
    memcpy( &memory[offsetAddress], bufferBytes, lengthToCopy);
    
    do {
        char string[30];
        int add;
        
        add=Dasm(string,pc);
        [result appendFormat:@"%04X: %s\r", pc, string];
        pc += add;
        
    } while( pc <= offsetAddress+lengthToCopy);
    
    return result;
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObjects:@"com.microsoft.cocobasic.object", @"com.microsoft.cocobasic.gapsobject",nil];
}

+ (NSString *)anayliserName
{
    return @"6809 Dissasembler";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"DisasemblerAccessoryView";
}

- (Class)viewControllerClass
{
    return [DisasemblerAnaylizerViewController class];
}

+ (NSString *)anaylizerKey;
{
    return @"DisasemblerAnaylizerViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", [NSNumber numberWithInt:0], @"transferAddress", [NSNumber numberWithInt:0], @"offsetAddress", nil] autorelease];
}

@end
