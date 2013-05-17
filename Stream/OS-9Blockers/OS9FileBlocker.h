//
//  OS9FileBlocker.h
//  Stream
//
//  Created by tim lindner on 5/6/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Blockers.h"
#import "StStream.h"
#import "AppDelegate.h"

@interface OS9FileBlocker : Blockers
{
    NSMutableIndexSet   *processedLSNs;
}

@end
