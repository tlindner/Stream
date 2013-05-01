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
        
        StBlock *getObject;
        id setObject;

        if ([[representedObject class] isSubclassOfClass:[StAnaylizer class]]) {
            getObject = [[representedObject parentStream] sourceBlock];
            setObject = representedObject;
        }
        else if ([[representedObject class] isSubclassOfClass:[StBlock class]]) {
            getObject = (StBlock *)representedObject;
            setObject = representedObject;
        }
        else {
            getObject = nil;
            setObject = nil;
        }
        
        if (getObject != nil) {
            if ([uti isEqualToString:@"com.microsoft.cocobasic.object"]) {
                NSMutableArray *transferAddresses = [setObject valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.transferAddresses"];
                
                if ([transferAddresses count] == 0) {
                    NSNumber *transferAddressNumber = [getObject getAttributeDatawithUIName:@"ML Exec Address"];
                    
                    if (transferAddressNumber == nil) {
                        /* no transfer address found in that block. This might be a multi segment block, so let's look for the transfer address block */
                        StStream *sourceStream = [getObject parentStream];
                        StBlock *transferBlock = [sourceStream blockNamed:@"Transfer 0"];
                        transferAddressNumber = [transferBlock getAttributeDatawithUIName:@"ML Exec Address"];
                    }
                    
                    if (transferAddressNumber != nil) {
                        tlValue *transferAddress = [[tlValue alloc] init];
                        transferAddress.stringValue = [transferAddressNumber stringValue];
                        [transferAddresses addObject:transferAddress];
                    }
                }
                
                NSNumber *offsetAddress = [getObject valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.offsetAddress"];
                
                if ([offsetAddress intValue] == -1) {
                    offsetAddress = [getObject getAttributeDatawithUIName:@"ML Load Address"];
                    [setObject setValue:offsetAddress forKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.offsetAddress"];
                }
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
    
    BOOL showAddress = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.showAddresses"] boolValue];
    BOOL showHex = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.showHex"] boolValue];
    BOOL support6309 = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.support6309"] boolValue];
    BOOL showOS9 = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.showOS9"] boolValue];
    NSArray *transferAddresses = [[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.transferAddresses"];
    
    if (transferAddresses != nil && [transferAddresses count] > 0) {
        
        unsigned int pc = [[[transferAddresses objectAtIndex:0] stringValue] intValue];
        unsigned int offsetAddress = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.offsetAddress"] intValue];
        pc &= 0xffff;
        offsetAddress &= 0xffff;
        const unsigned char *bufferBytes = [bufferObject bytes];
        NSUInteger length = [bufferObject length];
        NSUInteger lengthToCopy = MIN( length, 0x10000-offsetAddress );
        memcpy( &memory[offsetAddress], bufferBytes, lengthToCopy);
     
        if (support6309) {
            codes             = h6309_codes;
            codes10           = h6309_codes10;
            codes11           = h6309_codes11;
            exg_tfr           = h6309_exg_tfr;
            allow_6309_codes  = TRUE;
        }
        
        if (showOS9) {
            os9_patch = TRUE;
        }

        [result appendFormat:@"; org $%04X \n",pc];

        do {
            char string[30];
            int add;
            
            if (showAddress) {
                [result appendFormat:@"%04X: ", pc];
            }
            
            add=Dasm(string,pc);

            if (showHex) {
                for( int i=0; i<5; i++) {
                    if (add) {
                        add--;
                        [result appendFormat:@"%02X ",memory[(pc++)&0xFFFF]];
                    }
                    else
                        [result appendFormat:@"   "];
                }
            } else
                pc+=add;

            if ((!showAddress)&&(!showHex))
                [result appendFormat:@"\t"];

            [result appendFormat:@"%s\n", string];
                    
        } while( pc < offsetAddress+lengthToCopy);
    }
    else {
        [result appendString:@"No transfer addresses found"];
    }
    
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
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", [NSMutableArray array], @"transferAddresses", [NSNumber numberWithInt:-1], @"offsetAddress", [NSNumber numberWithBool:NO], @"support6309", [NSNumber numberWithBool:YES], @"showAddresses", [NSNumber numberWithBool:NO], @"showOS9", [NSNumber numberWithBool:YES], @"showHex", nil] autorelease];
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
