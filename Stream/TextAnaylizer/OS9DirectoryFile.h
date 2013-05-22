//
//  OS9DirectoryFile.h
//  Stream
//
//  Created by tim lindner on 5/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TextAnaylizer.h"

@interface OS9DirectoryFile : TextAnaylizer

- (NSString *)convertToString:(NSData *)source;

@end
