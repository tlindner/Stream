//
//  WaveFormView.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "WaveFormView.h"
#import "CoCoAudioAnalyzer.h"
#import "Accelerate/Accelerate.h"
#import "AudioToolbox/AudioConverter.h"
#import "MyDocument.h"
#import "NSIndexSet+GSIndexSetAdditions.h"
#import "CoCoAudioAnalyzer.h"

#define WFVSelection 0
#define WFVPan 1
#define WFVLupe 2
#define WFVPencil 3

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
@synthesize cachedAnalyzer;
@synthesize analyzationError;
@synthesize observationsActive;

//- (void)setFrame:(NSRect)frameRect
//{
//    NSLog( @"wfv Set Frame: %@", NSStringFromRect(frameRect) );
//    
//    [super setFrame:frameRect];
//}
//
//- (void)setBounds:(NSRect)boundsRect
//{
//    NSLog( @"wfv Set Bounds: %@", NSStringFromRect(boundsRect) );
//    
//    [super setBounds:boundsRect];
//}
//

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
        [self.cachedAnalyzer addObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.lowCycle" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.highCycle" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.resyncThreashold" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.audioChannel" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.amplify" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.interpolate" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.invert" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.dcblocking" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"resultingData" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"failIndexSet" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"editIndexSet" options:0 context:nil];
        [self.cachedAnalyzer addObserver:self forKeyPath:@"viewRange" options:0 context:nil];
        modelObject = (CoCoAudioAnalyzer *)[self.cachedAnalyzer analyzerObject];
        [modelObject addObserver:self forKeyPath:@"frameBuffer" options:0 context:nil];
        StStream *theStream = [self.cachedAnalyzer parentStream];
        [theStream addObserver:self forKeyPath:@"analyzers" options:0 context:nil];
        observationsActive = YES;
    }
}

- (void) deactivateObservations
{
    if( observationsActive == YES )
    {
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.lowCycle"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.highCycle"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.resyncThreashold"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.audioChannel"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.amplify"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.interpolate"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.invert"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.dcblocking"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"resultingData"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"failIndexSet"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"editIndexSet"];
        [self.cachedAnalyzer removeObserver:self forKeyPath:@"viewRange"];
        [modelObject removeObserver:self forKeyPath:@"frameBuffer"];
        StStream *theStream = [self.cachedAnalyzer parentStream];
        [theStream removeObserver:self forKeyPath:@"analyzers"];
        observationsActive = NO;
    }     
}

- (void)drawRect:(NSRect)dirtyRect
{
//    NSLog( @"self frame height: %f, bounds height: %f", [self frame].size.height, [self bounds].size.height );
//    NSLog( @"Super frame height: %f, bounds height: %f", [[self superview] frame].size.height, [[self superview] bounds].size.height );
//    NSLog( @"" );
    
    NSAssert(self.cachedAnalyzer != nil, @"Analyze Audio Data: analyzer can not be nil");
    NSDictionary *optionsDict = [self.cachedAnalyzer valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController"];
    
    NSMutableData *coalescedObject =  modelObject.coalescedObject;
    NSMutableData *characterObject = modelObject.resultingData;
    AudioSampleType *audioFrames = [modelObject.frameBuffer mutableBytes];
    NSRange *characters = [modelObject.charactersObject mutableBytes];
    NSUInteger currentChannel = [[optionsDict objectForKey:@"audioChannel"] intValue];
    NSUInteger frameCount = [modelObject.frameBuffer length] / sizeof(AudioSampleType);
    double sampleRate = [[optionsDict objectForKey:@"sampleRate"] doubleValue];
    
    NSUInteger char_count = [characterObject length];
    NSRange *coalescedCharacters = [coalescedObject mutableBytes];
    NSUInteger coa_char_count = [coalescedObject length]/sizeof(NSRange);
    unsigned char *character = [characterObject mutableBytes];
    
    if( audioFrames != nil )
    {
        CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
        CGFloat currentFrameWidth = [[self superview] frame].size.width;
        
        CGFloat scale = currentBoundsWidth/currentFrameWidth;
        
        NSAffineTransform *at = [NSAffineTransform transform];
        [at scaleXBy:scale yBy:1.0f];
        [at concat];
        
        StStream *stream = [self.cachedAnalyzer parentStream];
        NSOrderedSet *analyzers = [stream analyzers];
        
        CGFloat viewHeight = [self frame].size.height;
        CGFloat viewWaveHeight = viewHeight - (DATA_SPACE*[analyzers count]);
        if( viewWaveHeight < 0 ) viewWaveHeight = 0;
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
        NSUInteger i = 0;
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
                NSString *string;
                if( ((sampleRate / 2400.0) * 8 / scale) > 35.0)
                {
                    string = [NSString stringWithFormat:@"%ld: %2.2X", (unsigned long)i, character[i]];
                }
                else
                {
                    string = [NSString stringWithFormat:@"%2.2X", character[i]];
                }
                
                //NSLog( @"Scale: %f", ((sampleRate / 2400.0) * 8 / scale) );
                
                NSSize charWidth = [string sizeWithAttributes:nil];
                NSPoint thePoint = NSMakePoint((characters[i].location+(characters[i].length/2.0)-(charWidth.width/2.0*scale))/scale, viewWaveHeight+1.0);

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
            
            /* draw selection */
            if( scale <= DOT_HANDLE_SCALE )
            {
                /* Draw handle boxes */
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
                
                /* Draw zero crossing lines */
                [[NSColor darkGrayColor] set];
                NSData *zerocrossingObject = modelObject.zeroCrossingArray;
                NSUInteger zc_size = [zerocrossingObject length] / sizeof(float);
                float *zeroCrossings = (float *)[zerocrossingObject bytes];
                i=0;

                while (i < zc_size && zeroCrossings[i] < dirtyRect.origin.x)
                    i++;
  
                while ( i < zc_size && zeroCrossings[i] < dirtyRect.origin.x + dirtyRect.size.width )
                {
                    NSBezierPath *line = [NSBezierPath bezierPath];
                    [line moveToPoint:NSMakePoint(zeroCrossings[i]/scale, 0.0)];
                    [line lineToPoint:NSMakePoint(zeroCrossings[i]/scale, viewWaveHeight)];
                    [line setLineWidth:0.5]; /// Make it easy to see
                    [line stroke];  
                    i++;
                }
                
                /* Enable pencil tool */
                [viewController.toolControl setEnabled:YES forSegment:WFVPencil];
            }
            else
            {
                /* Disable Pencil tool */
                if( [viewController.toolControl selectedSegment] == WFVPencil )
                {
                    toolMode = WFVLupe;
                    [viewController.toolControl setSelectedSegment:WFVLupe];
                }
                
                [viewController.toolControl setEnabled:NO forSegment:WFVPencil];
                
            }
        }
        else
        {
            /* Disable Pencil tool */
            if( [viewController.toolControl selectedSegment] == WFVPencil )
            {
                toolMode = WFVLupe;
                [viewController.toolControl setSelectedSegment:WFVLupe];
            }
            
            [viewController.toolControl setEnabled:NO forSegment:WFVPencil];

            /* Zoomed out, draw maxed values, reflected across zero */
            for( i=0; i<width; i++ )
            {
                rect = NSMakeRect(i+origin, viewWaveHalfHeight - (viewFloats[i]*viewWaveHalfHeight), 1, (viewFloats[i]*(viewWaveHeight)) );
                NSRectFill(rect);
            }
        }

        /* Draw hi-lite selection */
        if( scale >= DOT_HANDLE_SCALE && selectedSample != NSUIntegerMax)
        {
            [[[NSColor selectedControlColor] colorWithAlphaComponent:0.5] set];
            rect = NSMakeRect(selectedSample/scale, 0, selectedSampleLength/scale, viewWaveHeight);
            NSBezierPath* aPath = [NSBezierPath bezierPathWithRect:rect];
            [aPath fill];            
        }
        
        /* draw green modification tints */
        [[NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:0.5] set];
        NSMutableIndexSet *changedSet = modelObject.changedIndexes;
        NSRange range = NSMakeRange(dirtyRect.origin.x, dirtyRect.size.width);
        [changedSet enumerateRangesInRange:range options:0 usingBlock:
         ^(NSRange range, BOOL *stop)
         {
             #pragma unused(stop)
             NSRect rect = NSMakeRect(range.location/scale, 0.0, range.length/scale, viewWaveHeight);
             NSBezierPath* aPath = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:5.0 yRadius:5.0];
             [aPath fill];
         }];
        
        /* draw lupe & selection rect */
        if( mouseDownOnPoint == NO )
        {
            if( (toolMode == WFVSelection && scale <= DOT_HANDLE_SCALE && mouseDown == YES) || (toolMode == WFVLupe && mouseDown == YES) )
            {
                NSDottedFrameRect(NSMakeRect(dragRect.origin.x/scale, dragRect.origin.y, dragRect.size.width/scale, dragRect.size.height));
            }
        }
        
        /* draw block goupings above wave form */
        for (NSUInteger i=1; i<[analyzers count]; i++)
        {
            StAnalyzer *theAna = [analyzers objectAtIndex:i];
            NSArray *blocksSet = [stream blocksWithAnalyzerKey:[theAna analyzerKind]];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
            NSArray *blocksArray = [blocksSet sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            NSArray *nameArray = [blocksArray valueForKey:@"name"];
            NSArray *rangeArrayObject = [blocksArray valueForKey:@"unionRange"];
            NSArray *blocksColor = [blocksArray valueForKey:@"attributeColor"];
            NSRange *rangeArray = (NSRange *)malloc(sizeof(NSRange) * [rangeArrayObject count]);
            
            for (NSUInteger j=0; j<[rangeArrayObject count]; j++ )
            {
                NSRange theRange = [[rangeArrayObject objectAtIndex:j] rangeValue];
                rangeArray[j].location = characters[theRange.location].location;
                rangeArray[j].length = (characters[theRange.location + theRange.length - 1].location + characters[theRange.location + theRange.length - 1].length) - rangeArray[j].location;
            }
            
            CGFloat bottom = viewWaveHeight + (DATA_SPACE * i) - 2.0;
            NSColor *lightColor = [NSColor colorWithCalibratedWhite:0.8 alpha:0.5];
            NSColor *darkColor = [NSColor colorWithCalibratedWhite:0.65 alpha:0.5];
            
            for (NSUInteger j=0; j<[nameArray count]; j++ )
            {
                NSColor *blockColor = [blocksColor objectAtIndex:j];
                if ([blockColor isEqual:[NSColor clearColor]]) {
                    if (j & 0x1 )
                        [lightColor set];
                    else
                        [darkColor set];

                } else {
                    [blockColor set];
                }
                
                NSRect blobRect, textRect;
                
                textRect = blobRect = NSMakeRect(rangeArray[j].location, bottom, rangeArray[j].length, DATA_SPACE-2);
                blobRect.origin.x /= scale;
                blobRect.size.width /= scale;
                NSBezierPath* aPath = [NSBezierPath bezierPathWithRoundedRect:blobRect xRadius:5.0 yRadius:5.0];
                [aPath fill];
                
                textRect = NSIntersectionRect(textRect, [[self superview] bounds]);
                
                if( ! NSIsEmptyRect( textRect ) )
                {
                    textRect.origin.x /= scale;
                    textRect.size.width /= scale;
                    NSSize charWidth = [[nameArray objectAtIndex:j] sizeWithAttributes:nil];
                    CGFloat xStart = NSMidX(textRect) - ((charWidth.width/2.0*scale)/scale);
                    NSPoint thePoint = NSMakePoint(xStart, bottom+1.0);
                    [[nameArray objectAtIndex:j] drawAtPoint:thePoint withAttributes:nil];
                }
            }
            free( rangeArray );
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
    
    [self setCachedAnalyzer:nil];
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"ObserveValueForKeyPath: %@\nofObject: %@\nchange: %@\ncontext: %p", keyPath, object, change, context);
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnalyzerViewController.interpolate"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    } else if( [keyPath isEqualToString:@"optionsDictionary.AudioAnalyzerViewController.amplify"])
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    } else if( [keyPath isEqualToString:@"optionsDictionary.AudioAnalyzerViewController.invert"])
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    } else if( [keyPath isEqualToString:@"optionsDictionary.AudioAnalyzerViewController.dcblocking"])
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    } else if( [keyPath isEqualToString:@"optionsDictionary.AudioAnalyzerViewController.lowCycle"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    } else if( [keyPath isEqualToString:@"optionsDictionary.AudioAnalyzerViewController.highCycle"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    }
    else if( [keyPath isEqualToString:@"optionsDictionary.AudioAnalyzerViewController.resyncThreashold"])
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    }
    else if( [keyPath isEqualToString:@"optionsDictionary.AudioAnalyzerViewController.audioChannel"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    }
    else if( [keyPath isEqualToString:@"resultingData"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    }
    else if( [keyPath isEqualToString:@"failIndexSet"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    }
    else if( [keyPath isEqualToString:@"editIndexSet"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
        [self.cachedAnalyzer.analyzerObject analyzeData];
        [self.cachedAnalyzer.parentStream regenerateAllBlocks];
    }
    else if( [keyPath isEqualToString:@"frameBuffer"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
    }
    else if( [keyPath isEqualToString:@"viewRange"] )
    {
        [self zoomToCharacter: [[self.cachedAnalyzer viewRange] rangeValue]];
    }
    else if( [keyPath isEqualToString:@"analyzers"] )
    {
        resample = YES;
        [self setNeedsDisplay:YES];
    }
    else
    {   
        NSLog( @"Got an unexpected change" );
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
    #pragma unused(userData)
    #pragma unused(tag)
    #pragma unused(view)
    #pragma unused(point)
    NSDictionary *optionsDict = [self.cachedAnalyzer valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController"];
    double sampleRate = [[optionsDict objectForKey:@"sampleRate"] doubleValue];

    return [NSString stringWithFormat:@"%f Hertz", sampleRate / selectedSampleLength];
}

- (IBAction)chooseTool:(id)sender
{
    NSSegmentedControl *seggy = sender;
    toolMode = [seggy selectedSegment];
}

-(void)cursorUpdate:(NSEvent *)theEvent
{
    #pragma unused(theEvent)
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

- (IBAction)copy:(id)sender
{
    #pragma unused(sender)
    if( selectedSample != NSUIntegerMax )
    {
        /* Package chunk of sound into a WAV file */
        NSRange subRange = NSMakeRange(selectedSample * sizeof(float), selectedSampleLength * sizeof(float));
        
        NSData *selectedSamples = [NSData dataWithData:[modelObject.frameBuffer subdataWithRange:subRange]];
        NSURL *wavURL = [modelObject makeTemporaryWavFileWithData:selectedSamples];
        
        if( wavURL != nil )
        {
            /* Create NSSound object with WAV data */
            NSSound *sound = [[NSSound alloc] initWithContentsOfURL:wavURL byReference:NO];
            
            /* Stuff it into a paste board */
            NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard clearContents];
            [sound writeToPasteboard:pasteboard];
            [sound release];
        }
        else
        {
            NSBeep();
        }
    }   
}

- (IBAction)paste:(id)sender
{
#pragma unused(sender)
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    BOOL haveSound = [NSSound canInitWithPasteboard:pasteboard];
    
    if (haveSound) {
//        NSSound *sound = [[[NSSound alloc] initWithPasteboard:pasteboard] autorelease];
        NSBeep();
    }
    else
    {
        NSBeep();
    }
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
        
        StStream *stream = [self.cachedAnalyzer parentStream];
        NSOrderedSet *analyzers = [stream analyzers];
        CGFloat viewHeight = [self frame].size.height;
        CGFloat viewWaveHeight = viewHeight - (DATA_SPACE*[analyzers count]);
        if( viewWaveHeight < 0 ) viewWaveHeight = 0;
        CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
        
        AudioSampleType *audioFrames = [modelObject.frameBuffer mutableBytes];
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
            NSMutableIndexSet *changedSet = modelObject.changedIndexes;
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
    {
        mouseDown = YES;
        mouseDownOnPoint = NO;
    }
    else if( toolMode == WFVPencil )
    {
        NSPoint locationMouseDownSelf = [self convertPoint:locationMouseDown fromView:nil];
        NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
        selectedSampleUnderMouse = locationNowSelf.x;
        selectedSample = selectedSampleUnderMouse;
        CGFloat viewHeight = [self frame].size.height;
        CGFloat viewWaveHeight = viewHeight - DATA_SPACE;
        CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
        AudioSampleType *audioFrames = [modelObject.frameBuffer mutableBytes];
        unsigned long audioFramesLength = [modelObject.frameBuffer length];
        AudioSampleType *frameStart = audioFrames + selectedSample;
        
        /* Cache previous changed set */
        NSMutableIndexSet *changedSet = modelObject.changedIndexes;
        if( previousIndexSet != nil ) [previousIndexSet release];
        previousIndexSet = [changedSet mutableCopy];
        
        /* update changed set */
        [changedSet addIndex:selectedSample];
        
        /* make copy of all samples */
        if( storedSamples != nil ) free( storedSamples );
        
        storedSamples = malloc( audioFramesLength );
        memcpy(storedSamples, audioFrames, audioFramesLength);

        /* Pencil in new sample value */
        AudioSampleType new_value = (locationMouseDownSelf.y / viewWaveHalfHeight) - 1.0;
        frameStart[0] = new_value;
        
        /* update analyzation */
        resample = YES;
        [self setNeedsDisplay:YES];
    }
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
            
            AudioSampleType *audioFrames = [modelObject.frameBuffer mutableBytes];
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
            CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
            CGFloat currentFrameWidth = [[self superview] frame].size.width;
            CGFloat scale = currentBoundsWidth/currentFrameWidth;
            
            /* Handle floating info window */
            if( attachedWindow == nil )
            {
                NSDictionary *optionsDict = [self.cachedAnalyzer valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController"];
                double sampleRate = [[optionsDict objectForKey:@"sampleRate"] doubleValue];
                NSView *toolView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 25)];
                textView = [[NSTextView alloc] initWithFrame:NSMakeRect(5, 5, 90, 15)];
                
                
                NSMutableParagraphStyle *mutParaStyle=[[NSMutableParagraphStyle alloc] init];
                [mutParaStyle setAlignment:NSCenterTextAlignment];
                NSAttributedString *string;
                
                if( scale <= DOT_HANDLE_SCALE )
                {
                    string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%4.1f Hertz", sampleRate/selectedSampleLength] attributes:[NSDictionary dictionaryWithObjectsAndKeys:mutParaStyle, NSParagraphStyleAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil] ];
                }
                else {
                    string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%4.2fs", selectedSampleLength/sampleRate] attributes:[NSDictionary dictionaryWithObjectsAndKeys:mutParaStyle, NSParagraphStyleAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil] ];
                }
                
                [mutParaStyle release];
                [textView setDrawsBackground:NO];
                [textView insertText:string];
                [string release];
                [toolView addSubview:textView];
                [textView release];
                attachedWindow = [[MAAttachedWindow alloc] initWithView:toolView attachedToPoint:locationNow inWindow:[self window] onSide:MAPositionBottom atDistance:10.0];
                [toolView release];
                [[self window] addChildWindow:attachedWindow ordered:NSWindowAbove];
            }
            else {
                NSDictionary *optionsDict = [self.cachedAnalyzer valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController"];
                double sampleRate = [[optionsDict objectForKey:@"sampleRate"] doubleValue];
                if( scale <= DOT_HANDLE_SCALE )
                    [textView setString:[NSString stringWithFormat:@"%4.1f Hertz", sampleRate/selectedSampleLength]];
                else
                    [textView setString:[NSString stringWithFormat:@"%4.2fs", selectedSampleLength/sampleRate]];
                [attachedWindow setPoint:locationNow side:MAPositionBottom];
            }
            
            [self setNeedsDisplay:YES];
        }
    }
    else if( toolMode == WFVPencil )
    {
        NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
        NSUInteger sampleUnderMouse = locationNowSelf.x;
        CGFloat viewHeight = [self frame].size.height;
        CGFloat viewWaveHeight = viewHeight - DATA_SPACE;
        CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
        AudioSampleType *audioFrames = [modelObject.frameBuffer mutableBytes];
        AudioSampleType *frameStart = audioFrames + sampleUnderMouse;
        AudioSampleType new_value = (locationNowSelf.y / viewWaveHalfHeight) - 1.0;
        frameStart[0] = new_value;
        
        NSMutableIndexSet *changedSet = modelObject.changedIndexes;
        [changedSet addIndex:sampleUnderMouse];
        
        resample = YES;
        [self setNeedsDisplay:YES];
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
            
            originFrames[ZOOM_FRAMES] = dragRect.origin.x;
            sizeFrames[ZOOM_FRAMES] = dragRect.size.width;
            
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
            
            originFrames[ZOOM_FRAMES] = dragRect.origin.x;
            sizeFrames[ZOOM_FRAMES] = dragRect.size.width;
            
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
            
            [self.cachedAnalyzer setValue:[NSNumber numberWithBool:YES] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.selected"];
        }
        
        [self setNeedsDisplay:YES];
    }
    else if( toolMode == WFVSelection && mouseDownOnPoint == YES )
    {   
        if( cancelDrag == NO )
        {
            NSManagedObjectContext *parentContext = [(NSPersistentDocument *)[[[self window] windowController] document] managedObjectContext];
            NSData *previousSamples = [NSData dataWithBytes:storedSamples length:sizeof(AudioSampleType)*selectedSampleLength];
            NSRange range = NSMakeRange(sizeof(AudioSampleType)*selectedSample, sizeof(AudioSampleType)*selectedSampleLength);
            NSValue *rangeValue = [NSValue valueWithRange:range];
            NSDictionary *previousState = [NSDictionary dictionaryWithObjectsAndKeys:previousSamples, @"data", rangeValue, @"range", previousIndexSet, @"indexSet", nil];
            
            [[parentContext undoManager] registerUndoWithTarget:modelObject selector:@selector(setPreviousState:) object:previousState];
            
            if( selectedSampleLength == 1 )
                [[parentContext undoManager] setActionName:@"Move Sample"];
            else
                [[parentContext undoManager] setActionName:@"Move Samples"];
            
            /* post edit to analyzer */
//            AudioSampleType *audioFrames = [modelObject.frameBuffer mutableBytes];
//            NSData *editedSamples = [NSData dataWithBytes:audioFrames + range.location length:range.length];
            NSData *editedSamples = [modelObject.frameBuffer subdataWithRange:range];
            [[self cachedAnalyzer] postEdit:editedSamples range:range];

            [modelObject analyzeAudioData];
            [self setNeedsDisplay:YES];
        }
    }
    else if( toolMode == WFVPencil )
    {   
        /* calculate contigious range of modified samples */
        NSMutableIndexSet *changedSet = modelObject.changedIndexes;
        NSIndexSet *modifiedSet = [changedSet gsSubtractWithIndexSet:previousIndexSet];
        NSRange modifiedRange = NSMakeRange([modifiedSet firstIndex], [modifiedSet lastIndex] - [modifiedSet firstIndex] + 1);
        
        /* Create and register undo object */
        NSRange range = NSMakeRange(sizeof(AudioSampleType)*modifiedRange.location, sizeof(AudioSampleType)*modifiedRange.length);
        NSValue *rangeValue = [NSValue valueWithRange:range];
        NSManagedObjectContext *parentContext = [(NSPersistentDocument *)[[[self window] windowController] document] managedObjectContext];
        NSData *previousSamples = [NSData dataWithBytes:storedSamples+modifiedRange.location length:sizeof(AudioSampleType)*modifiedRange.length];
        NSDictionary *previousState = [NSDictionary dictionaryWithObjectsAndKeys:previousSamples, @"data", rangeValue, @"range", previousIndexSet, @"indexSet", nil];

        [[parentContext undoManager] registerUndoWithTarget:modelObject selector:@selector(setPreviousState:) object:previousState];
        [[parentContext undoManager] setActionName:@"Draw Samples"];

        /* post edit to analyzer */
        AudioSampleType *audioFrames = [modelObject.frameBuffer mutableBytes];
        NSData *editedSamples = [NSData dataWithBytes:audioFrames + range.location length:range.length];
        [[self cachedAnalyzer] postEdit:editedSamples range:range];

        /* Release samples */
        free( storedSamples );
        storedSamples = nil;
        
        /* re-analyze */
        [modelObject analyzeAudioData];
        [self setNeedsDisplay:YES];
    }
    
    if (selectedSample == NSUIntegerMax)
        [self.cachedAnalyzer setValue:[NSNumber numberWithBool:NO] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.selected"];
    else
        [self.cachedAnalyzer setValue:[NSNumber numberWithBool:YES] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.selected"];

    if( attachedWindow != nil )
    {
        [[self window] removeChildWindow:attachedWindow];
        [attachedWindow orderOut:self];
        [attachedWindow release];
        attachedWindow = nil;
    }
    mouseDown = NO;
}

- (void)zoomToCharacter:(NSRange)range
{
    toolMode = WFVLupe;
    NSMutableData *charactersObject = modelObject.charactersObject;
    NSUInteger characterCount = [charactersObject length] / sizeof(NSRange);
    NSRange *characters = (NSRange *)[charactersObject mutableBytes];
    CGFloat currentFrameWidth = [self frame].size.width;
    
    NSRect currentBounds = [[self superview] bounds];
    double timeToAccel = ZOOM_FRAMES/3.0;
    double timeCruising = ZOOM_FRAMES/3.0;
    double timeToDecel = ZOOM_FRAMES/3.0;
    
    NSUInteger rangeMin = range.location;
    rangeMin = MIN(rangeMin, characterCount-1);
    NSUInteger rangeMax = range.location + range.length;
    rangeMax = MIN(rangeMax, characterCount-1);
    
    double finalPositionOrigin = characters[rangeMin].location - currentBounds.origin.x;
    double finalPositionWidth = ((characters[rangeMax].location + characters[rangeMax].length) - characters[rangeMin].location);

    for( int currentTime=0; currentTime<ZOOM_FRAMES; currentTime++ )
    {
        originFrames[currentTime] = currentBounds.origin.x + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionOrigin, currentTime);
        sizeFrames[currentTime] = currentBounds.size.width + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionWidth, currentTime);
    }
    
    originFrames[ZOOM_FRAMES] = characters[rangeMin].location - 5.0;
    originFrames[ZOOM_FRAMES] = MAX(originFrames[ZOOM_FRAMES], 0.0);
    originFrames[ZOOM_FRAMES] = MIN(originFrames[ZOOM_FRAMES], currentFrameWidth);
    
    sizeFrames[ZOOM_FRAMES] = ((characters[rangeMax].location + characters[rangeMax].length) - characters[rangeMin].location) + 10.0;
    sizeFrames[ZOOM_FRAMES] = MAX(sizeFrames[ZOOM_FRAMES], 1.0);
    sizeFrames[ZOOM_FRAMES] = MIN(sizeFrames[ZOOM_FRAMES], currentFrameWidth - originFrames[ZOOM_FRAMES]);
    
    currentFrame = 0;
    panMomentumTimer = [[NSTimer scheduledTimerWithTimeInterval:0.035 target:self selector:@selector(mouseMomentum:) userInfo:nil repeats:YES] retain];
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
        
        if (currentFrame == ZOOM_FRAMES+1)
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

- (void) getSelectionOrigin:(NSUInteger *)origin width:(NSUInteger *)width
{
    *origin = selectedSample;
    *width = selectedSampleLength;
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
    
    for( vDSP_Length i=0; i<inputLength; i++ )
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
    #pragma unused(inAudioConverter)
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
    #pragma unused(sampleRate)
    #pragma unused(sampleSize)
    #pragma unused(lastFrame)
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
