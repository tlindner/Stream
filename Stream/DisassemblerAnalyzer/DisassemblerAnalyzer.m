//
//  DisassemblerAnalyzer.m
//  Stream
//
//  Created by tim lindner on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DisassemblerAnalyzer.h"
#import "DisassemblerAnalyzerViewController.h"
#import "StBlock.h"

BOOL ValueInRanges( unsigned int value, NSArray *rangesArray );
unsigned int PopAddressFromQueue( NSMutableArray *stack );
void FCB_Dump( NSMutableString *result, unsigned char *memory, NSRange nilRange, NSArray *filledRanges, BOOL showAddress, BOOL showHex );
NSString *PrintORG (NSUInteger i, NSArray *filledRanges);
void QueueAddressOnce( unsigned short segAddress, NSMutableArray *queue );

unsigned char *memory = NULL;
#define OPCODE(address)  memory[address&0xffff]
#define ARGBYTE(address) memory[address&0xffff]
#define ARGWORD(address) (word)((memory[address&0xffff]<<8)|memory[(address+1)&0xffff])
#include "dasm09.h"

@implementation DisassemblerAnalyzer

@synthesize representedObject;
@synthesize resultingData;

- (void) setRepresentedObject:(id)inRepresentedObject
{
    representedObject = inRepresentedObject;
    
    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[DisassemblerAnalyzer analyzerKey] withDictionary:[DisassemblerAnalyzer defaultOptions]];
    }
    
    /* fill in some settings for known blocks */
    if( [representedObject respondsToSelector:@selector(sourceUTI)] )
    {
        NSString *uti = [representedObject sourceUTI];
        
        StBlock *getObject;
        id setObject;

        if ([[representedObject class] isSubclassOfClass:[StAnalyzer class]]) {
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
                NSMutableArray *transferAddresses = [setObject valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.transferAddresses"];
                
                if ([transferAddresses count] == 0) {
                    NSNumber *transferAddressNumber = [getObject getAttributeDatawithUIName:@"ML Exec Address"];
                    
                    if (transferAddressNumber == nil) {
                        /* no transfer address found in that block. Just set the offset to be the transfer address */
                        transferAddressNumber = [getObject valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetAddress"];
                    }
                    
                    if (transferAddressNumber != nil) {
                        NSString *transferAddressHex = [NSString stringWithFormat:@"0x%X", [transferAddressNumber intValue]];
                        tlValue *transferAddress = [tlValue valueWithString:transferAddressHex];
                        [transferAddresses addObject:transferAddress];
                    }
                }
                
                NSNumber *offsetAddress = [getObject valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetAddress"];
                
                if ([offsetAddress intValue] == -1) {
                    offsetAddress = [getObject getAttributeDatawithUIName:@"ML Load Address"];
                    [setObject setValue:offsetAddress forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetAddress"];
                }
            } else if ([uti isEqualToString:@"com.microsoft.cocobasic.gapsobject"]) {
                [setObject setValue:[NSNumber numberWithBool:NO] forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetEnable"];
                [setObject setValue:@"Using Segment Offsets" forKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetAddress"];
            }
        }
    }
}

- (NSString *)disassemble6809:(NSData *)bufferObject
{
    NSMutableString *result = [NSMutableString string];
    memory = calloc(0x10000, 1);
    NSPointerArray *pa = [NSPointerArray pointerArrayWithStrongObjects];
    [pa setCount:0x10000];
    const unsigned char *bufferBytes = [bufferObject bytes];
    NSUInteger length = [bufferObject length];
    NSUInteger i;
    unsigned int offsetAddress;
    NSMutableArray *filledRanges;
    NSMutableArray *transferAddressesOptions = [[self representedObject] valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.transferAddresses"];
    BOOL showAddress = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showAddresses"] boolValue];
    BOOL showHex = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showHex"] boolValue];
    BOOL support6309 = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.support6309"] boolValue];
    BOOL showOS9 = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.showOS9"] boolValue];
    BOOL followPC = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.followPC"] boolValue];
    NSMutableArray *transferAddressesQueue;
    
    NSString *uti = [representedObject sourceUTI];
    if ([uti isEqualToString:@"com.microsoft.cocobasic.gapsobject"]) {
        /* decode coco basic gaps object */
        filledRanges = [NSMutableArray array];
        i = 0;
        while (i<length) {
            
            if (i+5 < length && bufferBytes[i] == 0) {
                /* read a block header */
//                unsigned char segAmble;
                unsigned short segAddress, segLength, actualLength, actualActualLength;
                
//                segAmble = bufferBytes[i+0];
                segLength = bufferBytes[i+1] << 8;
                segLength += bufferBytes[i+2];
                segAddress = bufferBytes[i+3] << 8;
                segAddress += bufferBytes[i+4];
                actualLength = MIN(segLength, (i + 5 + segLength) - length); /* don't read past the block */
                actualActualLength = MIN( actualLength, 0xffff - segAddress ); /* don't write past the buffer */
               
                /* copy block data */
                [filledRanges addObject:[NSValue valueWithRange:NSMakeRange(segAddress, actualActualLength)]];
                memcpy(&(memory[segAddress]), &(bufferBytes[i+5]), actualActualLength);
                
                if (actualLength > actualActualLength) {
                    /* wrap around back to zero and write remaining bytes */
                    unsigned short remainingLength = actualLength - actualActualLength;

                    [filledRanges addObject:[NSValue valueWithRange:NSMakeRange(0, remainingLength)]];
                    memcpy(&(memory[0]), &(bufferBytes[i+5+actualActualLength]), remainingLength);
                }
                
                i += 5 + segLength;
                
                if (!followPC) QueueAddressOnce( segAddress, transferAddressesOptions );
                
            } else if (i+4 < length && bufferBytes[i] == 0xff) {
                /* insert transfer address into stack if not already there */
//                unsigned char segAmble;
                unsigned short segAddress;
//                unsigned short segLength;
                
//                segAmble = bufferBytes[i+0];
//                segLength = bufferBytes[i+1] << 8;
//                segLength += bufferBytes[i+2];
                segAddress = bufferBytes[i+3] << 8;
                segAddress += bufferBytes[i+4];
                
                if (followPC) QueueAddressOnce( segAddress, transferAddressesOptions );
                
                break;
            }
        }
        
        transferAddressesQueue = [transferAddressesOptions mutableCopy];
    }
    else {
        offsetAddress = [[[self representedObject] valueForKeyPath:@"optionsDictionary.DisassemblerAnalyzerViewController.offsetAddress"] intValue];
        offsetAddress &= 0xffff;
        NSUInteger lengthToCopy = MIN( length, 0x10000-offsetAddress );
        memcpy( &memory[offsetAddress], bufferBytes, lengthToCopy);
        filledRanges = [NSMutableArray arrayWithObject:[NSValue valueWithRange:NSMakeRange(offsetAddress, lengthToCopy)]];
        
        if (followPC) {
            transferAddressesQueue = [transferAddressesOptions mutableCopy];
        } else {
            NSString *stringExecAddressHex = [NSString stringWithFormat:@"0x%X", offsetAddress];
            transferAddressesQueue = [[NSMutableArray alloc] initWithObjects:[tlValue valueWithString:stringExecAddressHex], nil];
        }
    }

    unsigned int pc;

    if (transferAddressesQueue != nil && [transferAddressesQueue count] > 0 && (pc = PopAddressFromQueue (transferAddressesQueue)) < 0xffff) {
        NSNull *aNull = [NSNull null];
        unsigned pc_mode;
        unsigned address;
        
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

        do {

            if (!followPC) [result appendFormat:@"; org $%04X\n",pc];

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
                            case _pc_jmp:
                            case _pc_tfr:
                                if (ValueInRanges (address, filledRanges)) {
                                    pc = address;
                                    break;
                                }
                                else {
                                    pc = PopAddressFromQueue( transferAddressesQueue );
                                    break;
                                }
                            case _pc_pul:
                            case _pc_ret:
                            case _pc_end:
                                pc = PopAddressFromQueue( transferAddressesQueue );
                                break;
                                                            
                            case _pc_bra:
                                if (ValueInRanges (pc+add, filledRanges)) {
                                    [transferAddressesQueue addObject:[tlValue valueWithString:[NSString stringWithFormat:@"%d",pc+add]]];
                                }
                                
                                pc = address;
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
                    pc = PopAddressFromQueue( transferAddressesQueue );
                }
                
            } while (ValueInRanges(pc, filledRanges));
            
            pc = PopAddressFromQueue( transferAddressesQueue );
            if (!followPC) [result appendFormat:@"\n"];
            
        } while (ValueInRanges(pc, filledRanges));
        
        if (followPC) {
            int i = 0, nil_start = 0, nil_end = 0;

            for (NSString *line in pa) {
                
                if (line == nil) {
                    nil_end = i;
                }
                else {
                    [result appendString:PrintORG (i, filledRanges)];
                    
                    if (line == (void *)aNull) {
                        nil_start = i+1;
                    }
                    else {
                        if( nil_start != i )
                        {
                             FCB_Dump( result, memory, NSMakeRange(nil_start, nil_end - nil_start), filledRanges, showAddress, showHex );
                        }
                        
                        nil_start = i+1;

                        [result appendFormat:@"%@\n", line];
                    }
                  }
                
                i++;
            }
            
            if (nil_start < 0x10000) {
                FCB_Dump( result, memory, NSMakeRange(nil_start, nil_end - nil_start), filledRanges, showAddress, showHex );
            }
        }
    }
    else {
        for (NSValue *rangeValue in filledRanges) {
            FCB_Dump( result, memory, [rangeValue rangeValue], filledRanges, showAddress, showHex );
        }
    }
    
    [transferAddressesQueue release];
    free(memory);
    return result;
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(unsigned char *)byte
{
    NSLog( @"Dissasembler: replaceBytesInRange: %@ withByte 0x%x", NSStringFromRange(range), *byte);
}

- (void)analyzeData
{
    StData *object = [self representedObject];
    NSData *sourceData = [object resultingData];
    NSString *result = [self disassemble6809:sourceData];
    self.resultingData = [result dataUsingEncoding:NSUnicodeStringEncoding];
    
    object.resultingUTI = @"public.utf16-plain-text";
    
    if (self.resultingData == nil) {
        self.resultingData = [NSData data];
    }
}

+ (NSArray *)analyzerUTIs
{
    return [NSArray arrayWithObjects:@"com.microsoft.cocobasic.object", @"com.microsoft.cocobasic.gapsobject",nil];
}

+ (NSString *)analyzerName
{
    return @"6809 Dissasembler";
}

+ (NSString *)AnalyzerPopoverAccessoryViewNib
{
    return @"DisassemblerAccessoryView";
}

- (Class)viewControllerClass
{
    return [DisassemblerAnalyzerViewController class];
}

+ (NSString *)analyzerKey
{
    return @"DisassemblerAnalyzerViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", [NSMutableArray array], @"transferAddresses", [NSNumber numberWithBool:NO], @"transferAddressEnable", [NSNumber numberWithInt:0], @"directPageValue", [NSNumber numberWithInt:-1], @"offsetAddress", [NSNumber numberWithBool:YES], @"offsetEnable", [NSNumber numberWithBool:NO], @"support6309", [NSNumber numberWithBool:YES], @"showAddresses", [NSNumber numberWithBool:NO], @"showOS9", [NSNumber numberWithBool:YES], @"showHex", [NSNumber numberWithBool:NO], @"followPC", nil] autorelease];
}

- (void)dealloc
{
    self.resultingData = nil;
    [super dealloc];
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

BOOL ValueInRanges( unsigned int value, NSArray *rangesArray )
{
    BOOL result = NO;
    
    for (NSValue *rangeValue in rangesArray) {
        NSRange range = [rangeValue rangeValue];
        
        if (value >= range.location && value < range.location+range.length) {
            result = YES;
            break;
        }
        
    }
    
    return result;
}

unsigned int PopAddressFromQueue( NSMutableArray *stack )
{
    unsigned int result = 0x10000;
    
    if ([stack count] > 0) {
        tlValue *value = [stack objectAtIndex:0];

        if (value != nil) {
            result = [value intValue];
            result &= 0xffff;

            [stack removeObjectAtIndex:0];
        }
    }
    
    return result;
}

void FCB_Dump( NSMutableString *result, unsigned char *memory, NSRange nilRange, NSArray *filledRanges, BOOL showAddress, BOOL showHex )
{
    for (NSValue *aRange in filledRanges) {
        NSRange theRange = [aRange rangeValue];
        NSRange intersectionRange = NSIntersectionRange(nilRange, theRange);
        
        if (intersectionRange.length > 0) {
            [result appendString:PrintORG (intersectionRange.location, filledRanges)];
            for (NSUInteger j=0; j<intersectionRange.length; j += 8) {
                if (showAddress) [result appendFormat:@"%04X: ", intersectionRange.location+j];
                if (showHex) [result appendFormat:@"               "];
                if ((!showAddress)&&(!showHex)) [result appendFormat:@"\t"];
                [result appendFormat:@"FCB", intersectionRange.location+j];
                int min = MIN((NSUInteger)8, intersectionRange.length - j);
                for (int k=0; k<min; k++) {
                    [result appendFormat:@" $%02X%s", memory[intersectionRange.location+j+k], k<min-1 ? "," : ""];
                }
                
                [result appendFormat:@"\n"];
            }
        }
    }
}

NSString *PrintORG (NSUInteger i, NSArray *filledRanges)
{
    NSString *result = @"";
    
    for (NSValue *aRange in filledRanges) {
        NSRange theRange = [aRange rangeValue];
        
        if (i == theRange.location) {
            result = [NSString stringWithFormat:@"; org $%04X\n",i];
            break;
        }
    }

    return result;
}

void QueueAddressOnce( unsigned short address, NSMutableArray *queue )
{
    BOOL found = NO;
    NSString *transferString = [NSString stringWithFormat:@"0x%X", address];
    for (tlValue *value in queue) {
        if ([value intValue] == address) {
            found = YES;
            break;
        }
    }

    if (found == NO) {
        [queue addObject:[tlValue valueWithString:transferString]];
    }
}

