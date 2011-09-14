//
//  WaveFormView.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "WaveFormView.h"
#import "CoCoAudioAnaylizer.h"
#import "Accelerate/Accelerate.h"
#import "AudioToolbox/AudioConverter.h"
#import "MyDocument.h"

#define WFVSelection 0
#define WFVPan 1
#define WFVLupe 2

#define DOT_HANDLE_SCALE 0.5
#define DATA_SPACE 19.0

void SamplesSamples_max( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, AudioSampleType *lastFrame );
void SamplesSamples_avg( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, AudioSampleType *lastFrame );
void SamplesSamples_1to1( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, AudioSampleType *lastFrame );
void SamplesSamples_resample( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, AudioSampleType *lastFrame );
OSStatus EncoderDataProc(AudioConverterRef inAudioConverter, UInt32* ioNumberDataPackets, AudioBufferList* ioData, AudioStreamPacketDescription**	outDataPacketDescription, void* inUserData);
double CubicHermite(double t, double p0, double p1, double m0, double m1);
double Interpolate( double timeToAccel, double timeCruising, double timeToDecel, double finalPosition, double currentTime);

typedef struct
{
	AudioSampleType *inBuffer;
    UInt32 count;
    BOOL done;
    vDSP_Stride stride;
} AudioFileIO;

@implementation WaveFormView

@synthesize viewController;
@synthesize cachedAnaylizer;
@synthesize anaylizationError;
@synthesize errorString;
@synthesize observationsActive;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        selectedSample = NSUIntegerMax;
        selectedSampleLength = 1;
    }
    
    return self;
}

- (void) activateObservations
{
    if( observationsActive == NO )
    {
        [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle" options:NSKeyValueChangeSetting context:nil];
        [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle" options:NSKeyValueChangeSetting context:nil];
        [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold" options:NSKeyValueChangeSetting context:nil];
        [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel" options:NSKeyValueChangeSetting context:nil];
        [self.cachedAnaylizer addObserver:self forKeyPath:@"resultingData" options:NSKeyValueChangeReplacement context:nil];
        [self.cachedAnaylizer addObserver:self forKeyPath:@"frameBufferObject" options:NSKeyValueChangeSetting context:nil];
        
        observationsActive = YES;
    }
}

- (void) deactivateObservations
{
    if( observationsActive == YES )
    {
        [self.cachedAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"];
        [self.cachedAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"];
        [self.cachedAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"];
        [self.cachedAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"];
        [self.cachedAnaylizer removeObserver:self forKeyPath:@"resultingData"];
        [self.cachedAnaylizer removeObserver:self forKeyPath:@"frameBufferObject"];
        observationsActive = NO;
    }     
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSAssert(self.cachedAnaylizer != nil, @"Anaylize Audio Data: anaylizer can not be nil");
    NSDictionary *optionsDict = [self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController"];
    
    NSMutableData *coalescedObject = [optionsDict objectForKey:@"coalescedObject"];
    NSMutableData *characterObject = [self.cachedAnaylizer valueForKey:@"resultingData"];
    AudioSampleType *audioFrames = [[optionsDict objectForKey:@"frameBufferObject"] mutableBytes];
    NSRange *characters = [[optionsDict objectForKey:@"charactersObject"] mutableBytes];
    NSInteger currentChannel = [[optionsDict objectForKey:@"audioChannel"] intValue];
    unsigned long long frameCount = [[optionsDict objectForKey:@"frameCount"] unsignedLongLongValue];
    double sampleRate = [[optionsDict objectForKey:@"sampleRate"] doubleValue];
    
    NSUInteger char_count = [characterObject length];
    NSRange *coalescedCharacters = [coalescedObject mutableBytes];
    NSUInteger coa_char_count = [coalescedObject length]/sizeof(NSRange);
    unsigned char *character = [characterObject mutableBytes];
    
    /* Drawing code here. */
    if( anaylizationError == YES )
    {
        if (errorString == nil) self.errorString = @"No error message set!";
        
        [errorString drawInRect:dirtyRect withAttributes:nil];
        
        [[NSColor grayColor] set];
        NSRectFill(dirtyRect);
        return;
    }
    
    if( audioFrames != nil )
    {
        CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
        CGFloat currentFrameWidth = [[self superview] frame].size.width;
        
        CGFloat scale = currentBoundsWidth/currentFrameWidth;
        
        NSAffineTransform *at = [NSAffineTransform transform];
        [at scaleXBy:scale yBy:1.0f];
        [at concat];
        
        CGFloat viewHeight = [self frame].size.height;
        CGFloat viewWaveHeight = viewHeight - DATA_SPACE;
        CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
        
        float origin = dirtyRect.origin.x / scale;
        float width = dirtyRect.size.width / scale;
        
        /* Create sub-sample array */
        
        Float32 *viewFloats;
        int offset = dirtyRect.origin.x;
        if( offset < 0 ) offset = 0;
        AudioSampleType *frameStart = audioFrames + offset; // Interleaved samples
        
        if( resample == YES )
        {
            free( previousBuffer );
            resample = NO;
            viewFloats = malloc(sizeof(Float32)*width);
            SamplesSamples_max( sampleRate, viewFloats, frameStart, scale, width, &(audioFrames[frameCount]) );
            previousBuffer = viewFloats;
            previousOffset = offset;
            previousBoundsWidth = currentBoundsWidth;
            previousFrameWidth = currentFrameWidth;
            previousCurrentChannel = currentChannel;
        }
        else if( (previousOffset == offset) && (previousBoundsWidth == currentBoundsWidth) && (previousFrameWidth == currentFrameWidth) && (previousCurrentChannel == currentChannel) )
        {
            viewFloats = previousBuffer;
        }
        else
        {
            free( previousBuffer );
            viewFloats = malloc(sizeof(Float32)*width);
            SamplesSamples_max( sampleRate, viewFloats, frameStart, scale, width, &(audioFrames[frameCount]) );
            previousBuffer = viewFloats;
            previousOffset = offset;
            previousBoundsWidth = currentBoundsWidth;
            previousFrameWidth = currentFrameWidth;
            previousCurrentChannel = currentChannel;
        }
        
        /* blank background */
        NSRect rect;
        [[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
        rect = NSMakeRect(dirtyRect.origin.x/scale, dirtyRect.origin.y, dirtyRect.size.width/scale, dirtyRect.size.height);
        NSRectFill(rect);
        
        /* decoded data values and data regions */
        int i = 0;
        if( ((sampleRate / 2400.0) * 8 / scale) > 9.5)
        {
            /* we're zoomed enought to draw segemented frames around byte groups and actual values */
            while ( i < char_count && characters[i].location < dirtyRect.origin.x) i++;
            
            if( i>0 ) i--;
            
            NSColor *lightColor = [NSColor colorWithCalibratedWhite:0.8 alpha:0.5];
            NSColor *darkColor = [NSColor colorWithCalibratedWhite:0.65 alpha:0.5];
            while( i < char_count && characters[i].location < dirtyRect.origin.x+dirtyRect.size.width )
            {
                /* Draw decoded values */
                [[NSColor blackColor] set];
                NSString *string = [NSString stringWithFormat:@"%2.2X" , character[i]];
                NSSize charWidth = [string sizeWithAttributes:nil];
                NSPoint thePoint = NSMakePoint((characters[i].location+(characters[i].length/2)-(charWidth.width/2))/scale, viewHeight-(DATA_SPACE)+1.0);
                [string drawAtPoint:thePoint withAttributes:nil];
                
                /* Draw byte grouping */
                if (i & 0x1 )
                    [lightColor set];
                else
                    [darkColor set];
                
                NSBezierPath* aPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect((characters[i].location)/scale, 0.0, ((characters[i].length)/scale), viewWaveHeight) xRadius:5.0 yRadius:5.0];
                [aPath fill];
                i++;
            }
        }
        else
        {
            /* we're zoomed too far out to see detial */
            while ( (i < coa_char_count) && (coalescedCharacters[i].location < dirtyRect.origin.x)) i++;
            
            if( i>0 ) i--;
            
            NSColor *aLightGrey = [NSColor colorWithCalibratedWhite:0.85 alpha:1.0];
            [aLightGrey set];
            
            while( (i < coa_char_count) && (coalescedCharacters[i].location < dirtyRect.origin.x+dirtyRect.size.width) )
            {
                /* Draw backound grouping */
                rect = NSMakeRect((coalescedCharacters[i].location)/scale, 0, ((coalescedCharacters[i].length)/scale), viewWaveHeight);
                NSRectFill(rect);
                
                /* Draw value bar */
                rect.origin.y = viewWaveHeight+2.0;
                rect.size.height = 13;
                NSRectFill(rect);
                i++;
            }
        }
        
        /* Draw zero line */
        [[NSColor grayColor] set];
        rect = NSMakeRect(dirtyRect.origin.x/scale, viewWaveHalfHeight, dirtyRect.size.width/scale, 1);
        NSRectFill(rect);
        
        /* Draw wave form */
        [[NSColor blackColor] set];
        
        if( scale < 3.0 )
        {
            /* Near 1:1 zoom, draw vertical lines connecting points to points */
            CGFloat lastHeight = viewWaveHalfHeight, thisHeight;
            for( i=0; i<width; i++ )
            {
                thisHeight = viewWaveHalfHeight+(viewFloats[i]*viewWaveHalfHeight);
                
                if (thisHeight > lastHeight)
                    rect = NSMakeRect(i+origin, lastHeight, 1, thisHeight - lastHeight);
                else
                    rect = NSMakeRect(i+origin, thisHeight, 1, lastHeight - thisHeight);
                
                NSRectFill(rect);
                lastHeight = thisHeight;
            }
            
            /* draw handles */
            if( scale <= DOT_HANDLE_SCALE )
            {
                CGFloat x = floor(origin);
                i = 0;
                
                while( x<(origin+width) )
                {
                    if( selectedSample == NSUIntegerMax)
                    {
                        /* no selected samples, draw all normally */
                        rect = NSMakeRect(x-1.0, (viewWaveHalfHeight+(frameStart[i]*viewWaveHalfHeight))-1.0, 3.0, 3.0);
                        NSRectFill(rect);
                    }
                    else if( offset+i >= selectedSample && offset+i < selectedSample+selectedSampleLength )
                    {
                        /* this is a selected sample, draw outline frame */
                        rect = NSMakeRect(x-2.0, (viewWaveHalfHeight+(frameStart[i]*viewWaveHalfHeight))-2.0, 4.0, 4.0);
                        [[NSBezierPath bezierPathWithRect:rect] stroke];
                    }
                    else
                    {
                        /* non selected sample, filled square */
                        rect = NSMakeRect(x-1.0, (viewWaveHalfHeight+(frameStart[i]*viewWaveHalfHeight))-1.0, 3.0, 3.0);
                        NSRectFill(rect);
                    }
                    
                    x += 1.0/scale;
                    i += 1;
                }
            }
        }
        else
        {
            /* Zoomed out, draw maxed values, reflected across zero */
            for( i=0; i<width; i++ )
            {
                rect = NSMakeRect(i+origin, viewWaveHalfHeight - (viewFloats[i]*viewWaveHalfHeight), 1, (viewFloats[i]*(viewWaveHeight)) );
                NSRectFill(rect);
            }
        }
        
        
        /* draw green modification tints */
        [[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:0.5] set];
        NSMutableIndexSet *changedSet = [self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.changedIndexes"];
        NSRange range = NSMakeRange(dirtyRect.origin.x, dirtyRect.size.width);
        [changedSet enumerateRangesInRange:range options:0 usingBlock:
         ^(NSRange range, BOOL *stop)
         {
             NSRect rect = NSMakeRect(range.location/scale, 0.0, range.length/scale, viewWaveHeight);
             NSRectFillUsingOperation( rect, NSCompositeSourceOver );
             
         }];
        
        /* draw lupe & selection rect */
        if( mouseDownOnPoint == NO )
        {
            if( (toolMode == WFVSelection || toolMode == WFVLupe) && mouseDown == YES )
            {
                NSDottedFrameRect(NSMakeRect(dragRect.origin.x/scale, dragRect.origin.y, dragRect.size.width/scale, dragRect.size.height));
            }
        }
    }
    else
    {
        /* No data, draw black rectangle */
        [[NSColor blackColor] set];
        NSRectFill(dirtyRect);
    }
}

- (void)dealloc
{
    if( panMomentumTimer != nil )
    {
        [panMomentumTimer invalidate];
        [panMomentumTimer release];
    }
    
    if( storedSamples != nil )
        free( storedSamples );
    
    if( previousBuffer != nil )
        free( previousBuffer );
    
    if( previousIndexSet != nil )
        [previousIndexSet release];
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"ObserveValueForKeyPath: %@\nofObject: %@\nchange: %@\ncontext: %p", keyPath, object, change, context);
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        return;
    }
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.highCycle"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        return;
    }
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"])
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        return;
    }
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        return;
    }
    
    if( [keyPath isEqualToString:@"resultingData"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        return;
    }
    
    if( [keyPath isEqualToString:@"frameBufferObject"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)chooseTool:(id)sender
{
    NSSegmentedControl *seggy = sender;
    toolMode = [seggy selectedSegment];
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
    if( toolMode == WFVSelection )
    {
        [[NSCursor arrowCursor] set];
    }
    else if( toolMode == WFVPan )
    {
        [[NSCursor openHandCursor] set];
    }
    else if( toolMode == WFVLupe )
    {
        MyDocument *ourDoc = [[[self window] windowController] document];
        [[ourDoc zoomCursor] set];
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void) mouseDown:(NSEvent *)theEvent
{
    mouseDown = YES;
    mouseDownOnPoint = NO;
    locationPrevious = locationNow = locationMouseDown = [self convertPoint:[theEvent locationInWindow] fromView:[self superview]];
    startOrigin = [[self superview] bounds].origin;
    
    if( panMomentumTimer != nil )
    {
        [panMomentumTimer invalidate];
        [panMomentumTimer release];
        panMomentumTimer = nil;
    }
    
    CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
    CGFloat currentFrameWidth = [[self superview] frame].size.width;
    CGFloat scale = currentBoundsWidth/currentFrameWidth;
    
    if( toolMode == WFVSelection && scale < DOT_HANDLE_SCALE )
    {
        /* Find sample under mouse click */
        NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
        selectedSampleUnderMouse = locationNowSelf.x;
        
        CGFloat viewHeight = [self frame].size.height;
        CGFloat viewWaveHeight = viewHeight - DATA_SPACE;
        CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
        
        AudioSampleType *audioFrames = [[self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"] mutableBytes];
        AudioSampleType *frameStart = audioFrames + selectedSampleUnderMouse;
        CGFloat thePoint = viewWaveHalfHeight+(frameStart[0]*viewWaveHalfHeight);
        NSRect sampleRect = NSMakeRect(selectedSampleUnderMouse-6.0, thePoint-6.0, 12, 12);
        
        /* Check if a sample is near the mouse down */
        if (NSPointInRect(locationNowSelf, sampleRect))
        {
            mouseDownOnPoint = YES;
            
            /* check if mouse down sample is in selection */
            if( (selectedSampleUnderMouse >= selectedSample) && (selectedSampleUnderMouse < selectedSample + selectedSampleLength) )
            {
                /* yes, mouse down in selection */
            }
            else
            {
                /* nope, select this one sample */
                selectedSample = selectedSampleUnderMouse;
                selectedSampleLength = 1;
            }
            
            /* Add selection to changed set */
            NSMutableIndexSet *changedSet = [self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.changedIndexes"];
            if( previousIndexSet != nil ) [previousIndexSet release];
            previousIndexSet = [changedSet mutableCopy];
            NSRange range = NSMakeRange(selectedSample, selectedSampleLength);
            [changedSet addIndexesInRange:range];
            
            /* make copy of selected samples */
            if( storedSamples != nil ) free( storedSamples );
            
            AudioSampleType *frameStart = audioFrames + selectedSample;
            storedSamples = malloc( sizeof(AudioSampleType)*selectedSampleLength );
            
            for( unsigned long i = 0; i<selectedSampleLength; i++ )
            {
                storedSamples[i] = frameStart[i];
            }
        }
    }
    else if( toolMode == WFVSelection && scale > DOT_HANDLE_SCALE )
        mouseDown = NO; /* no selecting samples if zoomed out too far */
}

- (void) mouseDragged:(NSEvent *)theEvent
{
    locationPrevious = locationNow;
    locationNow = [self convertPoint:[theEvent locationInWindow] fromView:[self superview]];
    
    if( toolMode == WFVPan )
    {
        CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
        CGFloat currentFrameWidth = [[self superview] frame].size.width;
        CGFloat scale = currentBoundsWidth/currentFrameWidth;
        
        [self scrollPoint:NSMakePoint(startOrigin.x+((locationMouseDown.x-locationNow.x)*scale), startOrigin.y)];
    }
    else if( toolMode == WFVLupe )
    {
        NSPoint locationMouseDownSelf = [self convertPoint:locationMouseDown fromView:nil];
        NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
        NSRect rectA = NSMakeRect(locationMouseDownSelf.x, startOrigin.y + locationMouseDownSelf.y, 1, 1);
        NSRect rectB = NSMakeRect(locationNowSelf.x, startOrigin.y + locationNowSelf.y, 1, 1);
        
        dragRect = NSUnionRect(rectA, rectB);
        
        [self setNeedsDisplay:YES];
    }
    else if( toolMode == WFVSelection )
    {
        if( mouseDownOnPoint == YES )
        {
            NSPoint locationMouseDownSelf = [self convertPoint:locationMouseDown fromView:nil];
            NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
            
            cancelDrag = NO;
            
            CGFloat viewHeight = [self frame].size.height;
            CGFloat viewWaveHeight = viewHeight - DATA_SPACE;
            CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
            
            AudioSampleType *audioFrames = [[self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"] mutableBytes];
            AudioSampleType *frameStart = audioFrames + selectedSample;
            
            AudioSampleType delta = (locationNowSelf.y - locationMouseDownSelf.y) / viewWaveHalfHeight;
            
            /* adjust sample up or down depending on mouse */
            for( unsigned long i=0; i<selectedSampleLength; i++ )
            {
                frameStart[i] = storedSamples[i] + delta;
                
                /* Check for clipping, and possible canceling */
                if( frameStart[i] > 1.5 )
                    cancelDrag = YES;
                else if( frameStart[i] > 1.0 )
                    frameStart[i] = 1.0;
                
                if( frameStart[i] < -1.5 )
                    cancelDrag = YES;
                else if( frameStart[i] < -1.0 )
                    frameStart[i] = -1.0;
            }
            
            if( cancelDrag )
            {
                /* reset all samples */
                for( unsigned long i=0; i<selectedSampleLength; i++ )
                {
                    frameStart[i] = storedSamples[i];
                }
            }
            
            resample = YES;
            [self setNeedsDisplay:YES];
        }
        else if( mouseDown == YES)
        {
            NSPoint locationMouseDownSelf = [self convertPoint:locationMouseDown fromView:nil];
            NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
            NSRect rectA = NSMakeRect(locationMouseDownSelf.x-0.5, startOrigin.y + locationMouseDownSelf.y-0.5, 1, 1);
            NSRect rectB = NSMakeRect(locationNowSelf.x-0.5, startOrigin.y + locationNowSelf.y-0.5, 1, 1);
            
            dragRect = NSUnionRect(rectA, rectB);
            
            selectedSample = ceil(dragRect.origin.x);
            selectedSampleLength = dragRect.size.width + 0.25;
            
            [self setNeedsDisplay:YES];
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint locationUp = [self convertPoint:[theEvent locationInWindow] fromView:[self superview]];
    panMomentumValue = locationPrevious.x - locationUp.x;
    
    if( (toolMode == WFVPan) && (fabs(panMomentumValue) > 10.0) )
    {
        panMomentumTimer = [[NSTimer scheduledTimerWithTimeInterval:0.030 target:self selector:@selector(mouseMomentum:) userInfo:nil repeats:YES] retain];
    }
    else if( toolMode == WFVLupe )
    {
        if( locationUp.x == locationPrevious.x ) /* no dragging, just simple click */
        {
            NSView *clipView = [self superview];
            CGFloat currentBoundsWidth = [clipView bounds].size.width;
            CGFloat currentFrameWidth = [clipView frame].size.width;
            CGFloat scale = currentBoundsWidth/currentFrameWidth;
            NSUInteger flags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
            
            float delta;
            
            if( flags == NSAlternateKeyMask )
                delta = 1000.0*scale;
            else
                delta = -1000.0*scale;
            
            NSPoint point = [[clipView superview] convertPoint:locationUp fromView:nil];
            point.x *= scale;
            float ratio = 1.0 / (point.x / currentBoundsWidth);
            
            dragRect = [clipView bounds];
            float width = dragRect.size.width;
            float newWidth = width + delta;
            dragRect.size.width = newWidth;
            dragRect.origin.x += (width - newWidth) / ratio;
            
            NSRect currentBounds = [clipView bounds];
            double timeToAccel = ZOOM_FRAMES/3.0;
            double timeCruising = ZOOM_FRAMES/3.0;
            double timeToDecel = ZOOM_FRAMES/3.0;
            double finalPositionOrigin = dragRect.origin.x - currentBounds.origin.x;
            double finalPositionWidth = dragRect.size.width - currentBounds.size.width;
            
            for( int currentTime=0; currentTime<ZOOM_FRAMES; currentTime++ )
            {
                originFrames[currentTime] = currentBounds.origin.x + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionOrigin, currentTime);
                sizeFrames[currentTime] = currentBounds.size.width + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionWidth, currentTime);
            }
            
            currentFrame = 0;
            panMomentumTimer = [[NSTimer scheduledTimerWithTimeInterval:0.035 target:self selector:@selector(mouseMomentum:) userInfo:nil repeats:YES] retain];
        }
        else /* drag lupe */
        {
            NSRect currentBounds = [[self superview] bounds];
            double timeToAccel = ZOOM_FRAMES/3.0;
            double timeCruising = ZOOM_FRAMES/3.0;
            double timeToDecel = ZOOM_FRAMES/3.0;
            double finalPositionOrigin = dragRect.origin.x - currentBounds.origin.x;
            double finalPositionWidth = dragRect.size.width - currentBounds.size.width;
            
            for( int currentTime=0; currentTime<ZOOM_FRAMES; currentTime++ )
            {
                originFrames[currentTime] = currentBounds.origin.x + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionOrigin, currentTime);
                sizeFrames[currentTime] = currentBounds.size.width + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionWidth, currentTime);
            }
            
            currentFrame = 0;
            panMomentumTimer = [[NSTimer scheduledTimerWithTimeInterval:0.035 target:self selector:@selector(mouseMomentum:) userInfo:nil repeats:YES] retain];
        }
    }
    else if( toolMode == WFVSelection && mouseDownOnPoint == NO )
    {
        if( locationUp.x == locationPrevious.x ) /* no dragging, just simple click */
        {
            selectedSample = NSUIntegerMax;
            selectedSampleLength = 1;
        }
        
        [self setNeedsDisplay:YES];
    }
    else if( toolMode == WFVSelection && mouseDownOnPoint == YES )
    {   
        if( cancelDrag == NO )
        {
            NSManagedObjectContext *parentContext = [(NSPersistentDocument *)[[[self window] windowController] document] managedObjectContext];
            NSData *previousSamples = [NSData dataWithBytes:storedSamples length:sizeof(AudioSampleType)*selectedSampleLength];
            NSValue *rangeValue = [NSValue valueWithRange:NSMakeRange(sizeof(AudioSampleType)*selectedSample, sizeof(AudioSampleType)*selectedSampleLength)];
            NSDictionary *previousState = [NSDictionary dictionaryWithObjectsAndKeys:previousSamples, @"data", rangeValue, @"range", previousIndexSet, @"indexSet", nil];
            
            id modelObject = [self.cachedAnaylizer anaylizerObject];
            [[parentContext undoManager] registerUndoWithTarget:modelObject selector:@selector(setPreviousState:) object:previousState];
            
            if( selectedSampleLength == 1 )
                [[parentContext undoManager] setActionName:@"Move Sample"];
            else
                [[parentContext undoManager] setActionName:@"Move Samples"];
            
            [modelObject anaylizeAudioData];
            [self setNeedsDisplay:YES];
        }
    }
    
    mouseDown = NO;
}

- (void)mouseMomentum:(NSTimer*)theTimer
{
    if( toolMode == WFVPan )
    {
        startOrigin = [[self superview] bounds].origin;
        CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
        CGFloat currentFrameWidth = [[self superview] frame].size.width;
        CGFloat scale = currentBoundsWidth/currentFrameWidth;
        [self scrollPoint:NSMakePoint(startOrigin.x+(panMomentumValue*scale), startOrigin.y)];
        
        panMomentumValue /= 1.1;
        
        if (fabs(panMomentumValue) < 2.0)
        {
            panMomentumValue = 0;
            [theTimer invalidate];
        }
    }
    else if( toolMode == WFVLupe )
    {
        NSRect currentBounds = [[self superview] bounds];
        
        if (currentFrame == ZOOM_FRAMES)
        {
            [theTimer invalidate];
            return;
        }
        
        currentBounds.origin.x = originFrames[currentFrame];
        currentBounds.size.width = sizeFrames[currentFrame];
        
        [viewController updateBounds:currentBounds];
        
        currentFrame++;
    }
}

@end

void SamplesSamples_max( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, AudioSampleType *lastFrame )
{
    if (sampleSize < 1.0)
    {
        SamplesSamples_resample( sampleRate, outBuffer, inBuffer, sampleSize, viewWidth, lastFrame );
    }
    else if (sampleSize == 1.0 )
    {
        SamplesSamples_1to1( sampleRate, outBuffer, inBuffer, sampleSize, viewWidth, lastFrame );
    }
    else
    {
        /* find maximum sample in each group */
        for( int i=0; i<viewWidth; i++ )
        {
            int j = (i)*sampleSize;
            
            if( &(inBuffer[j+(long)sampleSize-1]) < lastFrame )
                vDSP_maxv( &(inBuffer[j]), 1, &(outBuffer[i]), sampleSize );
            else
            {
                //NSLog( @"reading past array, %p > %p", &(inBuffer[j+(long)sampleSize-1]), lastFrame );
                outBuffer[i] = 0;
            }
        }
    }
}

void SamplesSamples_avg( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, AudioSampleType *lastFrame )
{
    if (sampleSize < 1.0)
    {
        SamplesSamples_resample( sampleRate, outBuffer, inBuffer, sampleSize, viewWidth, lastFrame );
    }
    else if (sampleSize == 1.0 )
    {
        SamplesSamples_1to1( sampleRate, outBuffer, inBuffer, sampleSize, viewWidth, lastFrame );
    }
    else
    {
        /* find average sample in each group */
        for( int i=0, j; i<viewWidth; i++ )
        {
            AudioSampleType curValue = 0.0;
            for( j=0; j<sampleSize; j++ )
            {
                NSUInteger bufPointer = i*sampleSize+j;
                
                if( &(inBuffer[bufPointer]) < lastFrame )
                {
                    curValue += inBuffer[bufPointer];
                }
                else
                    NSLog( @"SamplesSamples_avg: reading past sample buffer" );
            }
            
            outBuffer[i] = curValue/sampleSize;
        }
        
        // Should move to this: Vector mean magnitude; single precision.
        // vDSP_meamgv( float * __vDSP_A, vDSP_Stride __vDSP_I float * __vDSP_C, vDSP_Length __vDSP_N);
    }
}


void SamplesSamples_resample( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, AudioSampleType *lastFrame )
{
    /* de-stride input */
    
    vDSP_Length inputLength = viewWidth / sampleSize;
    AudioSampleType *destrideBuffer = malloc(sizeof(AudioSampleType)*inputLength);
    
    for( int i=0; i<inputLength; i++ )
    {
        if( &(inBuffer[i]) < lastFrame )
            destrideBuffer[i] = inBuffer[i];
        else
            destrideBuffer[i] = 0;
    }
    
    /* resample data to fit in the view width */
    AudioConverterRef inAudioRef;
    
    AudioStreamBasicDescription inSourceFormat;
    AudioStreamBasicDescription inDestinationFormat;
    
    UInt32 ioOutputDataPacketSize = (UInt32)viewWidth;
    AudioBufferList outOutputData;
    AudioStreamPacketDescription outPacketDescription;
    
    inSourceFormat.mSampleRate = sampleRate;
    SetCanonical(&inSourceFormat, 1, false);
    
    inDestinationFormat.mSampleRate = sampleRate / sampleSize;
    SetCanonical(&inDestinationFormat, 1, false);
    
    OSStatus myErr = AudioConverterNew( &inSourceFormat, &inDestinationFormat, &inAudioRef );
    
    if( myErr != noErr )
        fprintf(stderr, "Error in AudioConverterNew: %d", myErr );
    
    outOutputData.mNumberBuffers = 1;
    outOutputData.mBuffers[0].mNumberChannels = 1;
    outOutputData.mBuffers[0].mDataByteSize = sizeof(Float32)*(unsigned int)viewWidth;
    outOutputData.mBuffers[0].mData = outBuffer;
    
    outPacketDescription.mStartOffset = 0;
    outPacketDescription.mVariableFramesInPacket = 0;
    outPacketDescription.mDataByteSize = sizeof(Float32)*(unsigned int)viewWidth;
    
    AudioFileIO afio;
    afio.inBuffer = destrideBuffer;
    afio.count = (UInt32)inputLength;
    afio.done = NO;
    
    myErr = AudioConverterFillComplexBuffer( inAudioRef,
                                            EncoderDataProc,
                                            &afio,
                                            &ioOutputDataPacketSize,
                                            &outOutputData,
                                            &outPacketDescription);
    
    if( myErr != noErr )
        fprintf(stderr, "Error in AudioConverterFillComplexBuffer: %d", myErr );
    
    myErr = AudioConverterDispose( inAudioRef );
    
    if( myErr != noErr )
        fprintf(stderr, "Error in AudioConverterDispose: %d", myErr );
    
    free( destrideBuffer );    
}

/* data provider for resampling routine in SamplesSamples_resample() */
OSStatus EncoderDataProc(AudioConverterRef inAudioConverter, UInt32* ioNumberDataPackets, AudioBufferList* ioData, AudioStreamPacketDescription**	outDataPacketDescription, void* inUserData)
{
	AudioFileIO* afio = (AudioFileIO*)inUserData;
    
    if( afio->done == YES )
    {
        *ioNumberDataPackets = 0;
    }
    else
    {   /* Provide all data in one shot */
        *ioNumberDataPackets = afio->count;
        ioData->mNumberBuffers = 1;
        ioData->mBuffers[0].mData = afio->inBuffer;
        ioData->mBuffers[0].mDataByteSize = sizeof(Float32) * (afio->count);
        ioData->mBuffers[0].mNumberChannels = 1;
        if (outDataPacketDescription) *outDataPacketDescription = NULL;
        afio->done = YES;
    }
    
    return noErr;
}

void SamplesSamples_1to1( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, AudioSampleType *lastFrame )
{
    for( int i = 0; i<viewWidth; i++ )
    {
        outBuffer[i] = inBuffer[i];
    }
}

/* credit to Roman Zenka, stackover question #3367308 */
double CubicHermite(double t, double p0, double p1, double m0, double m1)
{
    double t2 = t*t;
    double t3 = t2*t;
    return (2.0*t3 - 3.0*t2 + 1.0)*p0 + (t3-2.0*t2+t)*m0 + (-2.0*t3+3.0*t2)*p1 + (t3-t2)*m1;
}

double Interpolate( double timeToAccel, double timeCruising, double timeToDecel, double finalPosition, double currentTime)
{    
    double t1 = timeToAccel;
    double t2 = timeCruising;
    double t3 = timeToDecel;
    double x = finalPosition;
    double t = currentTime;
    
    double v = x / (t1/2.0 + t2 + t3/2.0);
    double x1 = v * t1 / 2.0;
    double x2 = v * t2;
    
    if(t <= t1)
    {
        /* acceleration */
        return CubicHermite(t/t1, 0.0, x1, 0.0, x2/t2*t1);
    }
    else if(t <= t1+t2)
    {
        /* cruising */
        return x1 + x2 * (t-t1) / t2;
    }
    else
    {
        /* deceleration */
        return CubicHermite((t-t1-t2)/t3, x1+x2, x, x2/t2*t3, 0.0);
    }
}
