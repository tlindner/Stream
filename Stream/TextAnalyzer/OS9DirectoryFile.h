//
//  OS9DirectoryFile.h
//  Stream
//
//  Created by tim lindner on 5/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TextAnalyzer.h"

@interface OS9DirectoryFile : TextAnalyzer

- (NSString *)convertToString:(NSData *)source;

@end
