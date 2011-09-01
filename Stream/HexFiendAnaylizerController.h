//
//  HexFiendAnaylizerController.h
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HFLineCountingRepresenter.h"

@interface HexFiendAnaylizerController : NSViewController
{
    BOOL observationsActive;
    HFLineCountingRepresenter *lcRepresenter;
}

- (void) setupRepresentedObject;
- (void) setLineNumberFormatString:(NSString *)inFormat;

@end
