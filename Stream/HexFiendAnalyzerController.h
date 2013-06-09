//
//  HexFiendAnalyzerController.h
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HexFiend/HFLineCountingRepresenter.h"
#import "StAnalyzer.h"

@interface HexFiendAnalyzerController : NSViewController
{
    BOOL observationsActive;
    HFLineCountingRepresenter *lcRepresenter;
//    StAnalyzer *lastAnalyzer;
}

- (void) setupRepresentedObject;
- (void) setLineNumberFormatString:(NSString *)inFormat;
- (void) reloadView;
// - (void) setEditContentRanges;

- (void) suspendObservations;
- (void) resumeObservations;

@end
