#import <Cocoa/Cocoa.h>
#import "AnalyzerSettingPopOverAccessoryViewController.h"

#import "StAnalyzer.h"

@class AnalyzerListViewItem, DragRegionView;

@interface ColorGradientView : NSView
{
    NSColor *startingColor;
    NSColor *endingColor;
    int angle;
}
// Define the variables as properties
@property(nonatomic, retain) NSColor *startingColor;
@property(nonatomic, retain) NSColor *endingColor;
@property(assign) int angle;

@end