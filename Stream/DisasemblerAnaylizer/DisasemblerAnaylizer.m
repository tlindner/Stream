//
//  DisasemblerAnaylizer.m
//  Stream
//
//  Created by tim lindner on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DisasemblerAnaylizer.h"
#import "DisasemblerAnaylizerViewController.h"
#import "StBlock.h"

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
    
    if( [representedObject respondsToSelector:@selector(sourceUTI)] )
    {
        NSString *uti = [representedObject sourceUTI];
        StBlock *ro = (StBlock *)representedObject;
        
        if ([uti isEqualToString:@"com.microsoft.cocobasic.object"]) {
            NSMutableArray *transferAddresses = [ro valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.transferAddresses"];
            
            if ([transferAddresses count] == 0) {
                NSNumber *transferAddressNumber = [ro getAttributeDatawithUIName:@"ML Exec Address"];
                tlValue *transferAddress = [[tlValue alloc] init];
                transferAddress.stringValue = [transferAddressNumber stringValue];
                [transferAddresses addObject:transferAddress];
            }
            
            NSNumber *offsetAddress = [ro valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.offsetAddress"];
            
            if ([offsetAddress intValue] == -1) {
                offsetAddress = [ro getAttributeDatawithUIName:@"ML Load Address"];
                [representedObject setValue:offsetAddress forKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.offsetAddress"];
            }
        }
    }
}

- (NSString *)disasemble6809:(NSData *)bufferObject
{
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    memory = calloc(0x10000, 1);
//    NSPointerArray *pa = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality | NSPointerFunctionsCopyIn];
    NSPointerArray *pa = [NSPointerArray pointerArrayWithStrongObjects];
    [pa setCount:0x10000];
    
    NSArray *transferAddresses = [[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.transferAddresses"];
    unsigned int pc = [[[transferAddresses objectAtIndex:0] stringValue] intValue];
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
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", [NSMutableArray array], @"transferAddresses", [NSNumber numberWithInt:-1], @"offsetAddress", [NSNumber numberWithBool:NO], @"support6309", [NSNumber numberWithBool:NO], @"showAddresses", [NSNumber numberWithBool:NO], @"showOS9", [NSNumber numberWithBool:NO], @"showHex", nil] autorelease];
}

@end

@implementation tlValue

@synthesize stringValue;

- (id)init
{
    self = [super init];
    if (self) {
        self.stringValue = nil;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self) {
        self.stringValue = [coder decodeObjectForKey:@"TLStringValue"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.stringValue forKey:@"TLStringValue"];
}

- (void)dealloc
{
    self.stringValue = nil;
    
    [super dealloc];
}

@end
