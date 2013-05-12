//
//  CoCoDiskFileBlocker.h
//  Stream
//
//  Created by tim lindner on 5/11/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "Blockers.h"

@interface CoCoDiskFileBlocker : Blockers

@end

@interface RSDOSFilenameTransformer : NSValueTransformer
{
}
- (id)reverseTransformedValue:(id)value ofSize:(size_t)size;
@end

