//
//  HexFiendAnaylizerController.h
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HFLineCountingRepresenter.h"
#import "StAnaylizer.h"

@interface HexFiendAnaylizerController : NSViewController
{
    BOOL observationsActive;
    HFLineCountingRepresenter *lcRepresenter;
    StAnaylizer *lastAnaylizer;
}

- (void) setupRepresentedObject;
- (void) setLineNumberFormatString:(NSString *)inFormat;
- (void) reloadView;
- (void) setEditContentRanges;

- (void) suspendObservations;
- (void) resumeObservations;

@end
