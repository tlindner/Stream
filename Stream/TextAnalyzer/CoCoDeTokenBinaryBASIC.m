//
//  CoCoDeTokenBinaryBASIC.m
//  Stream
//
//  Created by tim lindner on 5/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CoCoDeTokenBinaryBASIC.h"

/* CoCo function tokens */
NSString *functions[128] = {@"SGN", @"INT", @"ABS", @"USR", @"RND", @"SIN", @"PEEK",
    @"LEN", @"STR$", @"VAL", @"ASC", @"CHR$", @"EOF", @"JOYSTK",
    @"LEFT$", @"RIGHT$", @"MID$", @"POINT", @"INKEY$", @"MEM",
    @"ATN", @"COS", @"TAN", @"EXP", @"FIX", @"LOG", @"POS", @"SQR",
    @"HEX$", @"VARPTR", @"INSTR", @"TIMER", @"PPOINT", @"STRING$",
    @"CVN", @"FREE", @"LOC", @"LOF", @"MKN$", @"AS", @"", @"LPEEK",
    @"BUTTON", @"HPOINT", @"ERNO", @"ERLIN", nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil, nil, nil };

/* Dragon Function tokens */
NSString *d_functions[128] = {@"SGN", @"INT", @"ABS", @"POS", @"RND", @"SQR", @"LOG",
    @"EXP", @"SIN", @"COS", @"TAN", @"ATN", @"PEEK", @"LEN",
    @"STR$", @"VAL", @"ASC", @"CHR$", @"EOF", @"JOYSTK",
    @"FIX", @"HEX$", @"LEFT$", @"RIGHT$", @"MID$", @"POINT", @"INKEY$", @"MEM",
    @"VARPTR", @"INSTR", @"TIMER", @"PPOINT", @"STRING$", @"USR", @"LOF",
    @"FREE", @"ERL", @"ERR", @"HIMEM", @"LOC", @"FRE$", nil };

/* CoCo command tokens */
NSString *commands[128] = {@"FOR", @"GO", @"REM", @"'", @"ELSE", @"IF",
    @"DATA", @"PRINT", @"ON", @"INPUT", @"END", @"NEXT",
    @"DIM", @"READ", @"RUN", @"RESTORE", @"RETURN", @"STOP",
    @"POKE", @"CONT", @"LIST", @"CLEAR", @"NEW", @"CLOAD",
    @"CSAVE", @"OPEN", @"CLOSE", @"LLIST", @"SET", @"RESET",
    @"CLS", @"MOTOR", @"SOUND", @"AUDIO", @"EXEC", @"SKIPF",
    @"TAB(", @"TO", @"SUB", @"THEN", @"NOT", @"STEP",
    @"OFF", @"+", @"-", @"*", @"/", @"^",
    @"AND", @"OR", @">", @"=", @"<", @"DEL",
    @"EDIT", @"TRON", @"TROFF", @"DEF", @"LET", @"LINE", @"PCLS",
    @"PSET", @"PRESET", @"SCREEN", @"PCLEAR", @"COLOR", @"CIRCLE",
    @"PAINT", @"GET", @"PUT", @"DRAW", @"PCOPY", @"PMODE",
    @"PLAY", @"DLOAD", @"RENUM", @"FN", @"USING", @"DIR",
    @"DRIVE", @"FIELD", @"FILES", @"KILL", @"LOAD", @"LSET",
    @"MERGE", @"RENAME", @"RSET", @"SAVE", @"WRITE", @"VERIFY",
    @"UNLOAD", @"DSKINI", @"BACKUP", @"COPY", @"DSKI$", @"DSKO$",
    @"DOS", @"WIDTH", @"PALETTE", @"HSCREEN", @"LPOKE", @"HCLS",
    @"HCOLOR", @"HPAINT", @"HCIRCLE", @"HLINE", @"HGET", @"HPUT",
    @"HBUFF", @"HPRINT", @"ERR", @"BRK", @"LOCATE", @"HSTAT",
    @"HSET", @"HRESET", @"HDRAW", @"CMP", @"RGB", @"ATTR",
    nil, nil, nil, nil, nil, nil, nil };

/* Dragon command tokens */
NSString *d_commands[128] = {@"FOR", @"GO", @"REM", @"'", @"ELSE", @"IF", @"DATA", @"PRINT",
    @"ON", @"INPUT", @"END", @"NEXT", @"DIM", @"READ", @"LET", @"RUN",
    @"RESTORE", @"RETURN", @"STOP", @"POKE", @"CONT", @"LIST", @"CLEAR",
    @"NEW", @"DEF", @"CLOAD", @"CSAVE", @"OPEN", @"CLOSE", @"LLIST",
    @"SET", @"RESET", @"CLS", @"MOTOR", @"SOUND", @"AUDIO", @"EXEC",
    @"SKIPF", @"DEL", @"EDIT", @"TRON", @"TROFF", @"LINE", @"PCLS", @"PSET",
    @"PRESET", @"SCREEN", @"PCLEAR", @"COLOR", @"CIRCLE", @"PAINT",
    @"GET", @"PUT", @"DRAW", @"PCOPY", @"PMODE", @"PLAY", @"DLOAD", @"RENUM",
    @"TAB(", @"TO", @"SUB", @"FN", @"THEN", @"NOT", @"STEP", @"OFF", @"+",
    @"-", @"*", @"/", @"^", @"AND", @"OR", @">", @"=", @"<", @"USING", @"AUTO",
    @"BACKUP", @"BEEP", @"BOOT", @"CHAIN", @"COPY", @"CREATE", @"DIR",
    @"DRIVE", @"DSKINIT", @"FREAD", @"FWRITE", @"ERROR", @"KILL", @"LOAD",
    @"MERGE", @"PROTECT", @"WAIT", @"RENAME", @"SAVE", @"SREAD", @"SWRITE",
    @"VERIFY", @"FROM", @"FLREAD", @"SWAP",  nil };

@implementation CoCoDeTokenBinaryBASIC

+ (NSArray *)analyzerUTIs
{
    return [NSArray arrayWithObjects:@"com.microsoft.cocobasic.binary", nil];
}

+ (NSString *)analyzerName
{
    return @"DeToken Binary CoCo BASIC";
}

+ (NSString *)analyzerKey
{
    return @"CoCoDeTokenBinaryBASIC";
}

- (void)analyzeData
{
    StData *object = [self representedObject];
    NSData *sourceData = [object resultingData];
    NSString *result = [self convertToString:sourceData];
    self.resultingData = [result dataUsingEncoding:NSUnicodeStringEncoding];
    
    object.resultingUTI = @"public.utf16-plain-text";
    
    if (self.resultingData == nil) {
        self.resultingData = [NSData data];
    }
}

- (NSString *)convertToString:(NSData *)source
{
    unsigned char *buffer = (unsigned char *)[source bytes];
    NSUInteger bufferSize = [source length];
    
    NSUInteger file_size, value, line_number, pos;
    unsigned char c;
    
    if (*buffer == 0xff && bufferSize > 3) {
        pos = 1;
        
        file_size = buffer[pos++] << 8;
        file_size += buffer[pos++];
        
        if (file_size < (bufferSize-3)) {
            StData *ro = self.representedObject;
            ro.errorString = [NSString stringWithFormat:@"BASIC Program size is less than the internal size: %ld < %ld", (unsigned long)file_size, bufferSize-3];
        }

        if (file_size > (bufferSize-3)) {
            StData *ro = self.representedObject;
            ro.errorString = [NSString stringWithFormat:@"BASIC Program size is greater than the internal size: %ld > %ld", (unsigned long)file_size, bufferSize-3];
        }
    }
    else {
        pos = 0;
    }
    
    value = buffer[pos++] << 8;
    value += buffer[pos++];
    
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    
    while (value != 0 && pos < bufferSize) {
        /* Evaluate line Number */
        line_number = buffer[pos++] << 8;
        line_number += buffer[pos++];
        
        [result appendFormat:@"%ld ", (unsigned long)line_number];
        
        while ((c = buffer[pos++]) != 0 && pos < bufferSize) {
            if (c == 0xff) {
                /* a function call */
                c = buffer[pos++];
                
                if (c >= 0x80) {
                    if( functions[c - 0x80] != nil ) {
                        [result appendString:functions[c-0x80]];
                    } else {
                        [result appendString:@"!"];
                    }
                } else {
                    [result appendFormat:@"%c", c];
                }
            } else if (c >= 0x80) {
                /* a command call */
                if (commands[c-0x80] != nil) {
                    [result appendString:commands[c - 0x80]];
                } else {
                    [result appendString:@"!"];
                }
            } else if (c == ':' && (buffer[pos] == 0x83 || buffer[pos] == 0x84) ) {
                /* When colon-apostrophe is encountered, the colon is dropped. */
                /* When colon-ELSE is encountered, the colon is dropped */
            } else {
                [result appendFormat:@"%c", c];
            }
        }
        
        value = buffer[pos++] << 8;
        value += buffer[pos++];
        
        [result appendFormat:@"\r"];
    }
    
    if (pos < bufferSize) {
        [result appendString:@"\n\nBytes after BASIC program:\n\n"];
        
        for (NSUInteger i=0; pos+i < bufferSize; i+=16) {
            NSUInteger j, jMin = MIN((NSUInteger)16, bufferSize - (pos+i));
            
            [result appendFormat:@"%04lX ", pos+i];
            
            for (j=0; j<jMin; j++) {
                [result appendFormat:@"%02X", buffer[pos+i+j]];
            }
            
            for (; j<16; j++) {
                [result appendString:@"  "];
            }
            
            [result appendString:@" "];

            for (unsigned j=0; j<jMin; j++) {
                [result appendFormat:@"%c", isprint(buffer[pos+i+j]) ? buffer[pos+i+j] : '.' ];
            }
            
            [result appendString:@"\n"];
        }

        [result appendString:@"\n"];
    }
    
    return result;
}

@end
