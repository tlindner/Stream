//
//  DisassemblerAnalyzer.h
//  Stream
//
//  Created by tim lindner on 4/29/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Analyzation.h"
#import "StStream.h"
#import "StAnalyzer.h"
#import "StBlock.h"

@interface DisassemblerAnalyzer : NSObject
{
    StAnalyzer *representedObject;
}

@property (nonatomic, assign) StAnalyzer *representedObject;
@property (nonatomic, retain) NSData *resultingData;

- (NSString *)disassemble6809:(NSData *)bufferObject;

@end

@interface tlValue : NSObject <NSCoding>
{
    NSString *stringValue;
}
@property (nonatomic, retain) NSString *stringValue;

+ (id)valueWithString: (NSString *)aString;
- (id)initWithString:(NSString *)aString;
- (int)intValue;

@end