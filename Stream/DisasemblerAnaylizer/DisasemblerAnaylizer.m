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
                        tlValue *transferAddress = [tlValue valueWithString:[transferAddressNumber stringValue]];
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
    NSMutableString *result = [NSMutableString string];
    memory = calloc(0x10000, 1);
    NSPointerArray *pa = [NSPointerArray pointerArrayWithStrongObjects];
    [pa setCount:0x10000];
    
    BOOL showAddress = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.showAddresses"] boolValue];
    BOOL showHex = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.showHex"] boolValue];
    BOOL support6309 = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.support6309"] boolValue];
    BOOL showOS9 = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.showOS9"] boolValue];
    BOOL followPC = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.followPC"] boolValue];
    NSMutableArray *transferAddressesStack = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.transferAddresses"] mutableCopy];
    
    if (transferAddressesStack != nil && [transferAddressesStack count] > 0) {
        NSNull *aNull = [NSNull null];
        tlValue *value = [transferAddressesStack lastObject];
        unsigned int pc = [value intValue];
        [transferAddressesStack removeLastObject];
        unsigned int offsetAddress = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisasemblerAnaylizerViewController.offsetAddress"] intValue];
        
        pc &= 0xffff;
        offsetAddress &= 0xffff;
        unsigned pc_mode;
        unsigned address;
        const unsigned char *bufferBytes = [bufferObject bytes];
        NSUInteger length = [bufferObject length];
        NSUInteger lengthToCopy = MIN( length, 0x10000-offsetAddress );
        memcpy( &memory[offsetAddress], bufferBytes, lengthToCopy);
        NSMutableArray *filledRanges = [NSMutableArray arrayWithObject:[NSValue valueWithRange:NSMakeRange(offsetAddress, lengthToCopy)]];
        
        if (support6309) {
            codes             = h6309_codes;
            codes10           = h6309_codes10;
            codes11           = h6309_codes11;
            exg_tfr           = h6309_exg_tfr;
            allow_6309_codes  = TRUE;
        }
        else {
            codes             = m6809_codes;
            codes10           = m6809_codes10;
            codes11           = m6809_codes11;
            exg_tfr           = m6809_exg_tfr;
            allow_6309_codes  = FALSE;
        }
        
        if (showOS9) {
            os9_patch = TRUE;
        } else {
            os9_patch = FALSE;
        }

        if (!followPC) [result appendFormat:@"; org $%04X \n",pc];

        do {
            char string[30];
            int add;
            
            if ([pa pointerAtIndex:pc] == NULL) {

                if (showAddress) {
                    [result appendFormat:@"%04X: ", pc];
                }
                
                add=Dasm(string,pc,&pc_mode,&address);

                if (showHex) {
                    for( int i=0, j=add; i<5; i++) {
                        if (j) {
                            j--;
                            [result appendFormat:@"%02X ",memory[(pc+i)&0xFFFF]];
                        }
                        else
                            [result appendFormat:@"   "];
                    }
                }
                
                if ((!showAddress)&&(!showHex)) [result appendFormat:@"\t"];
                
                [result appendFormat:@"%s", string];
                
                if (followPC) {
                    [pa replacePointerAtIndex:pc withPointer: result];
                    
                    for (int i=1; i<add; i++) {
                        [pa replacePointerAtIndex:pc+i withPointer:aNull];
                    }
                         
                    switch (pc_mode) {
                        case _pc_pul:
                        case _pc_ret:
                        case _pc_end:
                            value = [transferAddressesStack lastObject];
                            
                            if (value != nil) {
                                pc = [value intValue];
                                [transferAddressesStack removeLastObject];
                            }
                            else {
                                pc = 0x10000;
                            }
                            break;
                            
                        case _pc_jmp:
                        case _pc_tfr:
                            /* Need to check if the new address is in range */
                            pc = address;
                            break;
                            
                        case _pc_bra:
                            /* Need to check if the new address is in range */
                            [transferAddressesStack addObject:[tlValue valueWithString:[NSString stringWithFormat:@"%d",address]]];
                            pc+=add;
                            break;
                            
                        default:
                            pc+=add;
                            break;
                    }
                    
                    result = [NSMutableString string];
                }
                else {
                    [result appendFormat:@"\n"];
                    pc+=add;
               }
                
            }
            else {
                value = [transferAddressesStack lastObject];
                
                if (value != nil) {
                    pc = [value intValue];
                    [transferAddressesStack removeLastObject];
                }
                else {
                    pc = 0x10000;
                }
                
            }
            
        } while( pc < offsetAddress+lengthToCopy);
        
        if (followPC) {
            int i = 0, nil_start = 0, nil_end = 0;

            for (NSString *line in pa) {
                
                if (line == nil) {
                    nil_end = i;
                }
                else {
                    if (line == (void *)aNull) {
                        nil_start = i+1;
                    }
                    else {
                        if( nil_start != i )
                        {
//                            [result appendFormat:@"nil from %x to %x\n", nil_start, nil_end];
                            NSRange nillRange = NSMakeRange(nil_start, nil_end - nil_start);
                            
                            /* display FCBs for unassembled bytes */
                            for (NSValue *aRange in filledRanges) {
                                NSRange theRange = [aRange rangeValue];
                                NSRange intersectionRange = NSIntersectionRange(nillRange, theRange);
                                
                                if (intersectionRange.length > 0) {
                                    for (int j=0; j<intersectionRange.length; j += 8) {
                                        if (showAddress) [result appendFormat:@"%4X: ", intersectionRange.location+j];
                                        if (showHex) [result appendFormat:@"               "];
                                        if ((!showAddress)&&(!showHex)) [result appendFormat:@"\t"];
                                        [result appendFormat:@"FCB", intersectionRange.location+j];
                                        int min = MIN(8, j - intersectionRange.length);
                                        
                                        for (int k=0; k<min; k++) {
                                            [result appendFormat:@" $%02X%s", memory[intersectionRange.location+j+k], k<min-1 ? "," : ""];
                                        }
                                        
                                        [result appendFormat:@"\n"];
                                    }
                                }
                            }
                        }
                        
                        nil_start = i+1;

                        [result appendFormat:@"%@\n", line];
                    }
                  }
                
                i++;
            }
            
            if (nil_start < 0x10000) {
//                [result appendFormat:@"nill from %x to 0xffff\n", nil_start];
                NSRange nillRange = NSMakeRange(nil_start, 0xffff - nil_start);
                
                /* display FCBs for unassembled bytes */
                for (NSValue *aRange in filledRanges) {
                    NSRange theRange = [aRange rangeValue];
                    NSRange intersectionRange = NSIntersectionRange(nillRange, theRange);
                    
                    if (intersectionRange.length > 0) {
                        for (int j=0; j<intersectionRange.length; j += 8) {
                            if (showAddress) [result appendFormat:@"%4X: ", intersectionRange.location+j];
                            if (showHex) [result appendFormat:@"               "];
                            if ((!showAddress)&&(!showHex)) [result appendFormat:@"\t"];
                            [result appendFormat:@"FCB", intersectionRange.location+j];
                            int min = MIN(8, j - intersectionRange.length);
                            
                            for (int k=0; k<min; k++) {
                                [result appendFormat:@" $%02X%s", memory[intersectionRange.location+j+k], k<min-1 ? "," : ""];
                            }
                            
                            [result appendFormat:@"\n"];
                        }
                    }
                }
            }
        }
    }
    else {
        [result appendString:@"No transfer addresses found"];
    }
    
    free(memory);
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
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", [NSMutableArray array], @"transferAddresses", [NSNumber numberWithInt:-1], @"offsetAddress", [NSNumber numberWithBool:NO], @"support6309", [NSNumber numberWithBool:YES], @"showAddresses", [NSNumber numberWithBool:NO], @"showOS9", [NSNumber numberWithBool:YES], @"showHex", [NSNumber numberWithBool:NO], @"followPC", nil] autorelease];
}

@end

@implementation tlValue

@synthesize stringValue;

+ (id)valueWithString: (NSString *)aString
{
    return [[[self alloc] initWithString:aString] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.stringValue = nil;
    }
    return self;
}

- (id)initWithString:(NSString *)aString
{
    self = [super init];
    if (self) {
        self.stringValue = aString;
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

- (int)intValue
{
    NSScanner *pScanner = [NSScanner scannerWithString: self.stringValue];
    unsigned int result;
    
    if ([self.stringValue hasPrefix:@"0x"]) {
        [pScanner scanHexInt: &result];
    } else {
        result = [self.stringValue intValue];
    }

    return result;
}

-(NSString *)description
{
    return self.stringValue;
}

- (void)dealloc
{
    self.stringValue = nil;
    
    [super dealloc];
}

@end
