//
//  TextAnaylizer.m
//  Stream
//
//  Created by tim lindner on 4/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TextAnaylizer.h"
#import "TextAnaylizerViewController.h"

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

- (NSString *)decodeColorComputerBASIC:(NSData *)bufferObject
{
    unsigned char *buffer = (unsigned char *)[bufferObject bytes];
    NSUInteger size = [bufferObject length];
    
    NSUInteger file_size, value, line_number, pos;
    unsigned char c;
    
    if (*buffer == 0xff && size > 3) {
        pos = 1;
        
        file_size = buffer[pos++] << 8;
        file_size += buffer[pos++];
        
        if (file_size != (size-3)) {
            return [NSString stringWithFormat:@"BASIC Program size does not match internal size: %d != %d", file_size, size-3];
        }
    }
    else {
        pos = 0;
    }

    value = buffer[pos++] << 8;
    value += buffer[pos++];
    
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];

    while (value != 0 && pos < size) {
        /* Evaluate line Number */
        line_number = buffer[pos++] << 8;
        line_number += buffer[pos++];
        
        [result appendFormat:@"%d ", line_number];
        
        while ((c = buffer[pos++]) != 0 && pos < size) {
            if (c == 0xff) {
                /* a function call */
                c = buffer[pos++];
                
                if( functions[c - 0x80] != nil ) {
                    [result appendString:functions[c-0x80]];
                }
                else {
                    [result appendString:@"!"];
                }
            }
            else if (c >= 0x80) {
                /* a command call */
                if (commands[c-0x80] != nil) {
                    [result appendString:commands[c - 0x80]];
                }
                else {
                    [result appendString:@"!"];
                }
            }
            else if (c == ':' && (buffer[pos] == 0x83 || buffer[pos] == 0x84) ) {
                /* When colon-apostrophe is encountered, the colon is dropped. */
                /* When colon-ELSE is encountered, the colon is dropped */
            }
            else {
                [result appendFormat:@"%c", c];
            }
        }
        
        value = buffer[pos++] << 8;
        value += buffer[pos++];
        
        [result appendFormat:@"\r"];
    }
    
    return result;
}

- (NSString *)decodeOS9DirectoryFile:(NSData *)bufferObject
{
    NSMutableString *result = [[[NSMutableString alloc] init] autorelease];
    unsigned length = [bufferObject length], i=0;
    const unsigned char *bytes = [bufferObject bytes];
    NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:@"OS9String"];

    if (vt != nil) {
        while (length > 0) {
            
            if (bytes[i*32] != 0) {
                [result appendString:[vt transformedValue:[bufferObject subdataWithRange:NSMakeRange(i * 32, 29)]]];
                [result appendString:@", "];
                
                unsigned lsn = bytes[(i * 32) + 29] << 24;
                lsn += bytes[(i * 32) + 30] << 8;
                lsn += bytes[(i * 32) + 31];
                
                [result appendString:[NSString stringWithFormat:@"%d (0x%x)", lsn, lsn]];
                [result appendString:@"\n"];
            }
            
            i++;
            length -= 32;
        }
    }
    else {
        [result appendString:@"Missing OS-9 string tranfsormer."];
    }
    
    return result;
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObjects:@"public.text", @"com.microsoft.cocobasic.binary", @"com.microware.os9directoryfile", nil];
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
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"wrapLines", [NSNumber numberWithBool:YES], @"overWriteMode", [NSNumber numberWithBool:YES], @"fixedWidthFont", [NSMutableArray arrayWithObjects:@"UTF-8",@"US-ASCII",@"ISO-8859-1", @"macintosh", @"Tokenized CoCo BASIC Program", @"OS-9 Directory File", nil], @"encodingList", @"macintosh", @"encoding", [NSNumber numberWithBool:YES], @"readOnly", [NSNumber numberWithBool:NO], @"readOnlyEnabled", nil] autorelease];
}

@end
