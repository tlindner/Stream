//
//  BlockerProtocol.h
//  Stream
//
//  Created by tim lindner on 9/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef Stream_BlockerProtocol_h
#define Stream_BlockerProtocol_h

@class StStream, StAnaylizer;

@protocol BlockerProtocol <NSObject>
@optional
+ (NSString *)anayliserName;
+ (NSString *)anaylizerKey;
+ (NSString *)AnaylizerPopoverAccessoryViewNib;
+ (NSMutableDictionary *)defaultOptions;
+ (void) makeBlocks:(StStream *)stream withAnaylizer:(StAnaylizer *)anaylizer;
@end

#endif
